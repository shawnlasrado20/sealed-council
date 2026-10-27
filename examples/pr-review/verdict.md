# Verdict: BLOCK

**Ranks:** A > C, C > B, A > B. A first twice, C once, B never first.

**Problem (all three agree):** check-then-act refund. Two concurrent requests both pass the 409 check and both call Stripe; a crash after Stripe succeeds leaves the order refundable again.

**Fix (from A, the top-ranked answer):**
- Atomically claim a durable refund row in Postgres (unique per order) before calling Stripe.
- Store the amount and a stable Stripe idempotency key on that row; retries reuse the key.
- Reconcile Stripe's result into Postgres afterwards. A DB transaction cannot make the Stripe call atomic.

**Caught in review:** both rankers who saw B found a flaw in its patch. One: it changes order state before the auth check, so unauthorized requests can disrupt refunds. The other: rolling status back when Stripe errors reopens the order for a second refund after a timeout, and an order-id-only key collides with variable amounts.

**Also before merge (from B and C):** validate `amount` (integer, 0 < amount <= remaining), 404 on missing order, add a concurrent-refund test.
