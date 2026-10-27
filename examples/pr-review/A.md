BLOCK

**The refund is not idempotent across concurrent requests or failures.** Two requests can both read an unrefunded order and call Stripe. A crash after Stripe succeeds but before Postgres updates leaves the order eligible for another refund. Partial refunds can therefore be issued twice; the existing tests miss this.

**Fix:** Atomically claim a durable refund operation in Postgres, with a uniqueness constraint preventing competing operations for the same refund. Persist its amount and a stable Stripe idempotency key before calling Stripe. Retries must reuse that operation and key, then reconcile Stripe’s result into Postgres. A database transaction alone cannot make the Stripe call atomic.

Add tests for concurrent requests and a crash after Stripe succeeds but before the database update.

Skipped other review findings to prioritize this failure. Risk: duplicate refunds and inconsistent payment records.