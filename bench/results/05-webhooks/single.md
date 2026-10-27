**Approach: a transactional outbox in Postgres, with a worker in the same Node process.**

**Storage**
- `webhook_events`: id (UUID), customer_id, type, payload, created_at. Insert it **in the same transaction** as the business change. Missed webhooks usually come from firing an HTTP call after commit and losing it on a crash or deploy.
- `webhook_deliveries`: event_id, endpoint_id, status (pending/succeeded/failed/dead), attempts, next_attempt_at, last_status_code, last_error.
- Workers claim rows with `SELECT ... FOR UPDATE SKIP LOCKED LIMIT n WHERE next_attempt_at <= now()`. 50k a day is about 0.6 per second, so Postgres is enough. You don't need a queue.

**Retries**
- Exponential backoff with jitter: 1m, 5m, 30m, 2h, 6h, then every 12h for up to 3 days. After that, mark the delivery `dead`.
- Use a 10s timeout. Count only 2xx as success. Retry on 5xx, 429, timeouts and connection errors. Treat other 4xx as failures but still retry them.
- If an endpoint fails for 3 days, disable it and email the customer.

**Idempotency (the duplicates problem)**
- At-least-once delivery is the contract. Exactly-once isn't achievable, so state that in the docs.
- Send `Webhook-Id: <event uuid>`, the same value on every retry, plus a timestamp and an HMAC signature. Tell customers to dedupe on that ID.
- On your side, a unique constraint on (event_id, endpoint_id) stops you from enqueuing the same event twice.

**Ordering**
- Don't guarantee it. Include `created_at` and a per-resource `version` in the payload so customers can drop stale updates, or fetch the current state from your API.

**Monitor**
- Age of the oldest pending delivery. This is the main alert.
- Success rate per endpoint, and how many endpoints are disabled.
- Dead-letter count.
- Worker heartbeat.
- A customer-facing delivery log with a "resend" button. This removes most support tickets.

**Not building yet**
- Kafka, SQS or Redis queues
- Per-endpoint FIFO ordering
- A separate delivery service or fan-out cluster
- Svix-style replay APIs, event filtering or transformation
- Per-customer rate limiting (add it only when an endpoint needs it)

If the team would rather buy than build, use Svix or Hookdeck instead.
