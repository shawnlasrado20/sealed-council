**Pick this:** Postgres outbox + one delivery worker on the same Node process. At-least-once, ordered **per endpoint**, not globally.

**Storage.** In the same DB transaction as the business write, insert a `webhook_events` row (`id` UUID, `endpoint_id`, `type`, `payload`, `created_at`). A `webhook_deliveries` row tracks `status` (`pending`/`sending`/`succeeded`/`dead`), `attempt_count`, `next_retry_at`, `last_http_status`, `leased_until`. Unique on `(endpoint_id, event_id)` so the same event is never enqueued twice. Endpoints store URL, secret, and `disabled_at`.

**Worker.** Poll `pending` rows where `next_retry_at <= now()`, `FOR UPDATE SKIP LOCKED`, set `leased_until`. POST JSON `{id, type, created_at, data}` with `Idempotency-Key: <event id>` and `X-Signature` (HMAC of body). Success = HTTP 2xx. One in-flight delivery per endpoint (lease or `SELECT … FOR UPDATE` on the endpoint row) so that endpoint sees FIFO. Other endpoints run in parallel. 50k/day is ~1 event/s average; a single worker is enough.

**Retries.** Exponential backoff with jitter (e.g. 30s → 5m → 30m → 2h), cap ~8 attempts, then `dead`. Retry on timeout, 429, 5xx. Do **not** retry 4xx except 429. After N consecutive failures, pause that endpoint and alert; do not poison the whole queue.

**Idempotency.** The event `id` is the contract. You guarantee: at-least-once, same `id` never means a different payload. Customers must de-dupe on `id`. After a crash mid-send, you retry; duplicates are expected.

**Ordering.** FIFO per endpoint only. Do not promise cross-endpoint or global order.

**Monitor.** Queue depth, oldest pending age, success rate, p95 latency, attempts-to-success, DLQ count, per-endpoint consecutive failures, 4xx vs 5xx split. Alert on DLQ growth and endpoint pause.

**Do not build yet.** Kafka/SQS, a separate worker fleet, exactly-once, a customer replay UI, automatic endpoint discovery, or multi-region. Add a tiny admin “retry dead for endpoint X” later if support needs it.
