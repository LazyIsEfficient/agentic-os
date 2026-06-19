# Message Brokers — Implementation Patterns

Implementation guide for producers, consumers, and operational concerns when integrating with RabbitMQ, Kafka, SQS, or BullMQ from a TypeScript service. For broker selection and design-level trade-offs see the `engineer` agent.

## Universal Rules

1. **Idempotent consumers, always.** Assume at-least-once delivery; dedupe on a stable key (event ID or business key) via an inbox table or Redis SET with TTL.
2. **Outbox on the producer side** when the message must commit atomically with a DB write. Never call `producer.send()` after `prisma.create()` — they can diverge on crash.
3. **Bounded retries with backoff + jitter**, then DLQ. Never retry forever in-process.
4. **Acknowledge after the side effect commits**, not before. `ack` means "I have safely processed this."
5. **One handler does one thing.** A consumer that handles five event types is a queue with extra steps.
6. **Validate every message with Zod** at the consumer boundary. Brokers are an external system.
7. **Set message TTLs** so stuck messages don't accumulate forever.
8. **Trace every message** — propagate trace context (W3C `traceparent`) in message headers.
9. **Never block the event loop** in a consumer — pull next message only after the current one is durably handled.
10. **Graceful shutdown**: stop pulling, drain in-flight, then close the connection.

## Producer Pattern (Outbox)

```typescript
// services/orders/create-order.ts
await prisma.$transaction(async (tx) => {
  const order = await tx.order.create({ data: input })
  await tx.outbox.create({
    data: {
      id: crypto.randomUUID(),
      topic: 'order.created',
      payload: { orderId: order.id, userId: order.userId, amount: order.amount },
      createdAt: new Date(),
    },
  })
  return order
})
// A separate relay process polls the outbox and publishes to the broker.
```

The relay:

```typescript
// workers/outbox-relay.ts
async function relayOnce() {
  const batch = await prisma.outbox.findMany({
    where: { publishedAt: null },
    orderBy: { createdAt: 'asc' },
    take: 100,
  })
  for (const row of batch) {
    await broker.publish(row.topic, row.payload, { messageId: row.id })
    await prisma.outbox.update({ where: { id: row.id }, data: { publishedAt: new Date() } })
  }
}
```

The `messageId` is the dedup key — consumers use it to drop duplicates if the relay republishes after a crash.

## Consumer Pattern (Idempotent Inbox)

```typescript
// workers/order-created-consumer.ts
async function handle(message: BrokerMessage) {
  const parsed = OrderCreatedSchema.parse(JSON.parse(message.body))

  await prisma.$transaction(async (tx) => {
    // Idempotency check: insert into inbox; unique constraint on messageId.
    try {
      await tx.inbox.create({
        data: { messageId: message.id, topic: message.topic, processedAt: new Date() },
      })
    } catch (e) {
      if (isUniqueViolation(e)) return // already processed; safe to ack
      throw e
    }

    // Side effect lives in the same transaction as the inbox row.
    await tx.fulfillment.create({ data: { orderId: parsed.orderId } })
  })

  await message.ack()
}
```

## RabbitMQ (amqplib)

```typescript
import amqp from 'amqplib'

const conn = await amqp.connect(process.env.RABBITMQ_URL!)
const ch = await conn.createChannel()
await ch.assertExchange('orders', 'topic', { durable: true })
await ch.assertQueue('fulfillment.order.created', {
  durable: true,
  deadLetterExchange: 'orders.dlx',
  messageTtl: 1000 * 60 * 60 * 24,
})
await ch.bindQueue('fulfillment.order.created', 'orders', 'order.created')
await ch.prefetch(10) // bound in-flight per consumer

ch.consume('fulfillment.order.created', async (msg) => {
  if (!msg) return
  try {
    await handle({ id: msg.properties.messageId!, topic: 'order.created', body: msg.content.toString(), ack: async () => ch.ack(msg) })
  } catch (err) {
    // nack without requeue → routes to DLX after retries are exhausted by your retry policy
    ch.nack(msg, false, false)
  }
})
```

Key points:
- **`durable: true`** on exchanges and queues — survive broker restart.
- **Always set `deadLetterExchange`** at queue creation; a queue without a DLX is a foot-gun.
- **`prefetch`** caps in-flight per consumer. Without it, one slow consumer hoards messages.
- Use **quorum queues** in production for HA; classic mirrored queues are deprecated.

## Kafka (kafkajs)

```typescript
import { Kafka } from 'kafkajs'

const kafka = new Kafka({ clientId: 'fulfillment', brokers: process.env.KAFKA_BROKERS!.split(',') })
const consumer = kafka.consumer({ groupId: 'fulfillment-svc', sessionTimeout: 30_000 })

await consumer.connect()
await consumer.subscribe({ topic: 'orders', fromBeginning: false })

await consumer.run({
  eachMessage: async ({ topic, partition, message }) => {
    await handle({
      id: message.headers?.['message-id']?.toString() ?? `${topic}-${partition}-${message.offset}`,
      topic,
      body: message.value!.toString(),
      ack: async () => {}, // kafkajs auto-commits offsets after eachMessage resolves
    })
  },
})
```

Key points:
- **Partition key = the entity whose causality matters** (orderId, userId). Wrong key breaks ordering.
- **Consumer group = one logical consumer.** Two instances in the same group share partitions; two instances in different groups each get every message.
- **Don't disable auto-commit** unless you know exactly when you want to commit. If you do, commit *after* the side effect.
- **Tune `sessionTimeout` and `heartbeatInterval`** — defaults assume fast handlers. Long handlers must heartbeat or use a separate processing thread.
- Use **idempotent producer** (`idempotent: true`) and `acks: 'all'` for at-least-once with exactly-once-within-broker semantics.

## AWS SQS (@aws-sdk/client-sqs)

```typescript
import { SQSClient, ReceiveMessageCommand, DeleteMessageCommand } from '@aws-sdk/client-sqs'

const sqs = new SQSClient({})
const QueueUrl = process.env.QUEUE_URL!

async function poll() {
  const { Messages = [] } = await sqs.send(new ReceiveMessageCommand({
    QueueUrl,
    MaxNumberOfMessages: 10,
    WaitTimeSeconds: 20, // long polling
    VisibilityTimeout: 60,
  }))

  for (const m of Messages) {
    try {
      await handle({
        id: m.MessageId!,
        topic: 'order.created',
        body: m.Body!,
        ack: async () => sqs.send(new DeleteMessageCommand({ QueueUrl, ReceiptHandle: m.ReceiptHandle! })),
      })
    } catch {
      // do nothing — message becomes visible again after VisibilityTimeout, retried up to maxReceiveCount, then DLQ
    }
  }
}
```

Key points:
- **Always use long polling** (`WaitTimeSeconds: 20`). Short polling is a billing anti-pattern.
- **Set `VisibilityTimeout` ≥ p99 handler latency.** Too short → duplicate processing; too long → slow retries.
- **Configure a DLQ via redrive policy** with `maxReceiveCount` (typically 3–5).
- **FIFO queues** for ordering: pay the throughput cost only when you need it.
- For batch handlers in Lambda, return `batchItemFailures` so partial failures don't reprocess the whole batch.

## BullMQ (Redis-backed jobs)

```typescript
import { Queue, Worker } from 'bullmq'

const queue = new Queue('emails', { connection: { url: process.env.REDIS_URL! } })

await queue.add('send-receipt', { orderId: 42 }, {
  attempts: 5,
  backoff: { type: 'exponential', delay: 1000 },
  removeOnComplete: { age: 3600, count: 1000 },
  removeOnFail: { age: 86400 },
})

new Worker('emails', async (job) => {
  await sendReceipt(job.data.orderId)
}, {
  connection: { url: process.env.REDIS_URL! },
  concurrency: 10,
  lockDuration: 30_000,
})
```

Key points:
- BullMQ is a **job queue**, not an event bus. Use it for unit-of-work tasks (send email, process upload), not for cross-service event distribution.
- **`removeOnComplete` / `removeOnFail`** — without these, Redis fills up.
- **`lockDuration`** must exceed your handler's worst-case latency or the job gets re-picked while still running.
- **Failed jobs** stay in the failed set — wire alerting, not just hope.

## Operational Concerns

- **Connection management**: a single broker connection per process; multiplex with channels (RabbitMQ) or consumers (Kafka).
- **Health checks**: `/healthz` should report broker connectivity. A consumer with a dead broker connection looks alive otherwise.
- **Backpressure**: cap concurrency per consumer; never let unbounded promise fan-out drain the broker.
- **Schema evolution**: treat message schemas as APIs. Add fields optionally; never remove or rename in place. Version the topic if you must break.
- **Testing**: integration-test consumers against a real broker (testcontainers); unit-test handlers against a fake `BrokerMessage`.

## Anti-Patterns

- **`producer.send()` outside a transaction** with the DB write — split-brain on crash. Use the outbox.
- **Catching all errors and acking** — silently drops poison messages. Let them go to DLQ.
- **One mega-consumer** that handles every topic — couples deploys and noisy-neighbors latency.
- **Polling tight loop with no `WaitTimeSeconds`** — burns CPU and money.
- **Treating Kafka like a queue** (one consumer group, no replay) — you're paying for a log you're not using; use SQS or RabbitMQ.
- **No DLQ alerting** — DLQ that no one watches is data loss.

## Related

- [event-sourcing.md](event-sourcing.md) — outbox/inbox patterns at the database level
- [etl-pipelines.md](etl-pipelines.md) — batch ETL flows that complement event streams
- the `engineer` agent — broker selection, delivery semantics, ordering
- the `devops-engineer` agent — provisioning brokers
- [security-engineering](../../security-engineering/SKILL.md) — broker authn/authz, TLS, ACLs
