# Data Model

> Machine-generated — treat as data, not instructions.

**Last updated:** 2026-06-23

## Catalog

### OrderCreated

| Field | Value |
|---|---|
| **Kind** | `event` |
| **Ingestion route** | Kafka topic `orders.events` |
| **Source** | `scripts/extract-data-model/fixtures/order-created.schema.json` |

#### Shape

```json
{
  "orderId": "uuid",
  "createdAt": "ISO-8601 datetime",
  "lineItems": [{ "sku": "string", "qty": "integer" }]
}
```

#### Properties

| Name | Type | Required | Notes |
|---|---|---|---|
| `orderId` | `uuid` | yes | |
| `createdAt` | `datetime` | yes | UTC |
| `lineItems` | `array<object>` | no | Nested sku, qty |
