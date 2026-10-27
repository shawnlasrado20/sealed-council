**BLOCK**

The refund is a check-then-act on `order.status` with no row lock, no transaction, and no Stripe idempotency key. Two concurrent POSTs both read `paid`, both refund, both write. Client-supplied `amount` is not checked, so those races (or a single call with `amount: 1`) can over-refund or mark a partial refund as fully `refunded`. If Stripe succeeds and the `UPDATE` fails, money is gone and the order still looks refundable.

**Fix:** Open a transaction, `SELECT … FOR UPDATE`, re-check status, require `amount` to be a positive integer `<=` remaining refundable cents, `UPDATE … WHERE status = 'paid'` (or to `refunding`) and abort if no row, then `stripe.refunds.create` with an idempotency key, then commit `refunded` / `refunded_cents`. On Stripe failure, roll back. Add a concurrent-refund test.
