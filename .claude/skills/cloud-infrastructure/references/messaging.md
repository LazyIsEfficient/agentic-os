# Messaging Infrastructure

Provisioning patterns for message brokers and queues. For broker selection see [system-architect/references/distributed-patterns.md](../../system-architect/references/distributed-patterns.md); for application-level producer/consumer code see [typescript-data-engineering/references/message-brokers.md](../../typescript-data-engineering/references/message-brokers.md).

## Universal Rules

1. **Always provision a DLQ** alongside every primary queue. A queue without a DLQ is a production incident waiting to happen.
2. **Encrypt in transit and at rest.** TLS for all client connections; KMS keys for managed services.
3. **Private network only** — brokers live in private subnets. No public endpoints, ever.
4. **Least-privilege IAM / ACLs** scoped to specific topics or queues, not `*`.
5. **Right-size by environment** — dev can use a single small instance or local Docker; production needs HA and replication.
6. **Backups and snapshots** for any broker holding state (Kafka topics, RabbitMQ definitions).
7. **Monitor depth and age** — alert on queue depth, oldest-message age, consumer lag. Not on broker CPU.
8. **Tag everything** — `getTags()` on every resource.

## AWS SQS

Standard queue + DLQ via redrive policy:

```typescript
import * as aws from '@pulumi/aws'

const dlq = new aws.sqs.Queue('orders-dlq', {
  name: getResourceName('orders-dlq'),
  messageRetentionSeconds: 14 * 24 * 60 * 60, // 14 days
  kmsMasterKeyId: 'alias/aws/sqs',
  tags: getTags(),
})

const queue = new aws.sqs.Queue('orders', {
  name: getResourceName('orders'),
  visibilityTimeoutSeconds: 60,           // ≥ p99 handler latency
  messageRetentionSeconds: 4 * 24 * 60 * 60,
  receiveWaitTimeSeconds: 20,             // long polling default
  kmsMasterKeyId: 'alias/aws/sqs',
  redrivePolicy: pulumi.jsonStringify({
    deadLetterTargetArn: dlq.arn,
    maxReceiveCount: 5,
  }),
  tags: getTags(),
})
```

Rules:
- **`receiveWaitTimeSeconds: 20`** — enables long polling at the queue level so consumers can't accidentally short-poll.
- **`visibilityTimeout`** must exceed handler p99, with headroom for retries.
- **FIFO queues** (`name: 'orders.fifo'`, `fifoQueue: true`) only when ordering is required — they cap at 300 TPS per group without batching.
- **CloudWatch alarms** on `ApproximateAgeOfOldestMessage` (per queue) and DLQ `ApproximateNumberOfMessagesVisible > 0`.

## AWS SNS → SQS Fan-Out

```typescript
const topic = new aws.sns.Topic('order-events', {
  name: getResourceName('order-events'),
  kmsMasterKeyId: 'alias/aws/sns',
  tags: getTags(),
})

new aws.sns.TopicSubscription('fulfillment-sub', {
  topic: topic.arn,
  protocol: 'sqs',
  endpoint: queue.arn,
  rawMessageDelivery: true,
})

new aws.sqs.QueuePolicy('fulfillment-allow-sns', {
  queueUrl: queue.url,
  policy: pulumi.all([queue.arn, topic.arn]).apply(([qArn, tArn]) =>
    JSON.stringify({
      Version: '2012-10-17',
      Statement: [{
        Effect: 'Allow',
        Principal: { Service: 'sns.amazonaws.com' },
        Action: 'sqs:SendMessage',
        Resource: qArn,
        Condition: { ArnEquals: { 'aws:SourceArn': tArn } },
      }],
    }),
  ),
})
```

Rules:
- **`rawMessageDelivery: true`** so consumers don't have to unwrap an SNS envelope.
- One SQS queue per consumer group; SNS fans out the same message to each.

## RabbitMQ on Amazon MQ

```typescript
const broker = new aws.mq.Broker('rabbit', {
  brokerName: getResourceName('rabbit'),
  engineType: 'RabbitMQ',
  engineVersion: '3.13',
  hostInstanceType: getInstanceSizing().mq, // dev: mq.t3.micro, prod: mq.m5.large
  deploymentMode: isProd() ? 'CLUSTER_MULTI_AZ' : 'SINGLE_INSTANCE',
  publiclyAccessible: false,
  subnetIds: privateSubnetIds,
  securityGroups: [rabbitSg.id],
  encryptionOptions: { useAwsOwnedKey: false, kmsKeyId: kmsKey.arn },
  users: [{ username: 'admin', password: adminPasswordSecret.value }],
  tags: getTags(),
})
```

Rules:
- **`CLUSTER_MULTI_AZ`** in production, never `SINGLE_INSTANCE`.
- **`publiclyAccessible: false`** — never expose to the internet.
- **Quorum queues** in application code, not classic mirrored queues (deprecated).
- **Credentials in Secrets Manager**, never inline.
- **Set `messageTtl` and `deadLetterExchange`** at queue declaration time in the app, not at the broker level.

## Self-Managed Kafka (MSK)

```typescript
const cluster = new aws.msk.Cluster('events', {
  clusterName: getResourceName('events'),
  kafkaVersion: '3.7.x',
  numberOfBrokerNodes: isProd() ? 3 : 1,
  brokerNodeGroupInfo: {
    instanceType: getInstanceSizing().msk,
    clientSubnets: privateSubnetIds,
    securityGroups: [mskSg.id],
    storageInfo: { ebsStorageInfo: { volumeSize: isProd() ? 1000 : 100 } },
  },
  encryptionInfo: {
    encryptionAtRestKmsKeyArn: kmsKey.arn,
    encryptionInTransit: { clientBroker: 'TLS', inCluster: true },
  },
  clientAuthentication: { sasl: { iam: true } },
  loggingInfo: {
    brokerLogs: {
      cloudwatchLogs: { enabled: true, logGroup: kafkaLogs.name },
    },
  },
  tags: getTags(),
})
```

Rules:
- **At least 3 broker nodes** in production, spread across AZs.
- **IAM auth (`sasl.iam`)** for clients running in AWS — no static credentials.
- **Topic-level config** (replication factor, retention) is set per topic via the admin API or Terraform `kafka_topic`, not at cluster creation.
- **Replication factor ≥ 3, `min.insync.replicas: 2`** for durable topics.
- **Schema registry** (Glue Schema Registry or Confluent) — treat schemas as APIs.
- **MSK Connect** for managed connectors; otherwise run Kafka Connect on ECS.

## Google Pub/Sub

```typescript
import * as gcp from '@pulumi/gcp'

const topic = new gcp.pubsub.Topic('order-events', {
  name: getResourceName('order-events'),
  messageRetentionDuration: '604800s', // 7 days
  labels: getTags(),
})

const dlq = new gcp.pubsub.Topic('order-events-dlq', {
  name: getResourceName('order-events-dlq'),
  labels: getTags(),
})

new gcp.pubsub.Subscription('fulfillment', {
  name: getResourceName('fulfillment'),
  topic: topic.id,
  ackDeadlineSeconds: 60,
  messageRetentionDuration: '604800s',
  retryPolicy: { minimumBackoff: '10s', maximumBackoff: '600s' },
  deadLetterPolicy: { deadLetterTopic: dlq.id, maxDeliveryAttempts: 5 },
  expirationPolicy: { ttl: '' }, // never expire
  enableMessageOrdering: false,
})
```

Rules:
- **Always set `deadLetterPolicy`** with `maxDeliveryAttempts` between 5 and 10.
- **`ackDeadlineSeconds`** must exceed handler p99; clients can extend per-message but provision a sane default.
- **`enableMessageOrdering: true`** only when ordering keys are required — it adds latency.
- **Workload Identity** for GKE consumers; service account keys are a smell.

## Redis as a Queue (BullMQ on ElastiCache)

When you already have Redis and need a job queue, not an event bus:

```typescript
// Reuse the ElastiCache Redis from references/elasticache.md.
// BullMQ-specific provisioning is application-level: separate logical DB per queue
// or per environment to avoid key collisions.
```

Rules:
- **Separate Redis instance for queues** if write throughput matters — queues will dominate the workload.
- **Persistence enabled (`appendonly yes`)** so a restart doesn't lose jobs.
- **Eviction policy `noeviction`** — never evict keys under memory pressure when running queues.
- **Redis is not a broker.** Don't use it for cross-service event distribution; use SNS/SQS, RabbitMQ, or Kafka.

## Network and Security

- All brokers live in **private subnets**. Security groups allow inbound only from app security groups, on the broker port only.
- **TLS terminated at the broker**, not at a load balancer in front of it.
- **Credentials in Secrets Manager** with rotation policies. App reads at startup.
- **VPC endpoints** for SQS/SNS/Pub/Sub so traffic stays off the public internet.
- **Audit logging** enabled for all broker management actions (CloudTrail, GCP audit logs).

## Observability

Wire CloudWatch / Stackdriver alarms on:

| Metric | Alert when |
|---|---|
| Queue depth | Above sustained threshold (per queue baseline) |
| Oldest message age | Older than expected processing latency |
| DLQ message count | `> 0` for any DLQ |
| Consumer lag (Kafka) | Above `replication_factor * partition_count` worth of lag |
| Broker CPU / memory | Above 70% sustained |
| Failed publishes | Any non-zero rate |

Dashboards per environment, alerts route to oncall.

## Anti-Patterns

- **Public broker endpoints** — instant security incident.
- **No DLQ** — guaranteed data loss the first time you ship a poison message.
- **Single-AZ in production** — one rack failure away from outage.
- **Static IAM credentials** baked into task definitions — use IAM roles or IRSA.
- **Sharing a queue across unrelated consumers** — coupling deploys and noisy-neighbor latency.
- **Sizing for peak by adding instances forever** — fix the consumer, not the broker.

## Related

- [overview-and-config.md](overview-and-config.md) — naming, tagging, sizing helpers
- [vpc-and-security-groups.md](vpc-and-security-groups.md) — private subnets, SG patterns
- [secrets-manager.md](secrets-manager.md) — broker credential storage
- [iam-oidc.md](iam-oidc.md) — IAM auth for MSK and SQS
- [system-architect/references/distributed-patterns.md](../../system-architect/references/distributed-patterns.md) — broker selection, delivery semantics
- [typescript-data-engineering/references/message-brokers.md](../../typescript-data-engineering/references/message-brokers.md) — application-level producer/consumer code
