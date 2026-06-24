# Ingestion kinds and scan targets

Use the **Kind** column to classify each catalog entry.

| Kind | Meaning | Typical ingestion route examples |
|---|---|---|
| `api` | HTTP/RPC surface | `GET /v1/users/:id`, `POST /graphql`, gRPC `UserService/Get` |
| `persistence` | Stored entity / table / collection | Postgres `public.orders`, Mongo `users`, Prisma model `Order` |
| `message` | Async payload (queue, stream, bus) | Kafka `billing.invoice`, SQS `order-fulfillment`, Redis pub/sub |
| `event` | Domain event (often nested in `message`) | Same as message, or in-process event bus name |
| `websocket` | Real-time frame | `WS /ws/ticks`, Socket.io event `price_update` |

## What to scan in a diff

Prioritize files and symbols that define **contracts**:

- OpenAPI / Swagger / GraphQL schema / protobuf / Avro / JSON Schema
- Route handlers with explicit request/response types (Express, Fastify, Axum, etc.)
- ORM models, migrations, Prisma/Diesel/SQLAlchemy schema
- DTO / `types.ts` / Zod / Pydantic / serde structs used at boundaries
- Message envelope types, queue payload structs, webhook body types
- API client interfaces that mirror server contracts

Skip: pure UI components, CSS, test fixtures **unless** they define canonical shapes used in production paths.

## Ingestion route field

One line per primary entry point — how data **enters** the system for this shape:

- REST: method + path + status code if response-only
- GraphQL: operation type + field name
- Queue: broker + topic/queue name (+ schema registry subject if present)
- DB: database + table/collection (+ migration id if new)

If multiple routes share the same shape, list each on its own line in the table or use a bullet list under **Ingestion route**.
