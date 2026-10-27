**Approach:** Use a transactional outbox in Postgres, with a delivery worker running in the existing Node process. The contract is at-least-once delivery. You cannot avoid all duplicates: if a customer processes a webhook and the response is lost, you will send it again.

**Storage**
- **`webhook_events`:** id (UUID), type, payload, created_at. Insert it in the same transaction as the business change. Missed webhooks usually come from making the HTTP call after commit and losing it in a crash or deploy.
- **`webhook_deliveries`:** event_id, endpoint_id, status, attempts, next_attempt_at, leased_until, last_status_code, last_error. A unique constraint on (event_id, endpoint_id) prevents enqueuing the same event twice.
- **Capacity:** plan by deliveries, not events. One event sent to many endpoints means many requests. Postgres still handles this easily.

**Dispatch**
- Claim due rows with `FOR UPDATE SKIP LOCKED`, set a lease, and commit before sending the HTTP request.
- Expired leases recover work after a crash.
- Bound global concurrency and use a 10s timeout. Only 2xx counts as success.

**Retries**
- Retry timeouts, connection errors, 408, 429 and 5xx. Use exponential backoff with jitter (1m, 5m, 30m, 2h, 6h, then every 12h) and respect a bounded `Retry-After`.
- Other 4xx responses are terminal.
- After 3 days, mark the delivery `dead`.
- After repeated consecutive failures, pause the endpoint, alert, and email the customer. One bad endpoint should not slow everyone else.

**Idempotency**
- Every retry uses the same `Webhook-Id` (the event UUID) and the same payload. Sign each request with an HMAC and a timestamp.
- Document that customers must dedupe on that ID, ideally storing it under a unique constraint in the same transaction as their own changes.

**Ordering**
- Do not guarantee ordering. Include `created_at` and a per-resource `version` so customers can drop stale updates or fetch current state from your API.

**Monitor**
- Oldest pending delivery age (the main alert)
- Queue depth
- Success, retry and dead rates per endpoint
- Paused endpoints
- Expired leases
- Worker heartbeat

**Not building yet:** Kafka, SQS or Redis queues; a separate worker fleet; per-endpoint FIFO; exactly-once delivery; a customer replay UI or API. Add an admin "resend dead deliveries" command when support needs one.
