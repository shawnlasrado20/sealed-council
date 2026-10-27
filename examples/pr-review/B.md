**BLOCK**

**Most important problem: concurrent requests can refund the same order twice.**

The "already refunded" check reads the order, calls Stripe, and only then writes `status = 'refunded'`. If two requests arrive together (a double-click, a client retry, or someone doing it on purpose), both read the old status, both pass the 409 check, and both call `stripe.refunds.create`. That sends real money out twice. The 409 test only covers requests made one after another, so it can't catch this.

**Fix:** claim the order with one atomic update before calling Stripe, and send an idempotency key to Stripe:

```ts
const order = await db.oneOrNone(
  `UPDATE orders SET status = 'refunding'
   WHERE id = $1 AND status NOT IN ('refunding','refunded')
   RETURNING *`, [req.params.id]);
if (!order) return res.status(409).json({ error: "refund in progress or done" });
// auth check here; if it fails, put the previous status back
await stripe.refunds.create(
  { payment_intent: order.payment_intent, amount },
  { idempotencyKey: `refund-${order.id}` });
// then set status = 'refunded'; if Stripe fails, set it back
```

Also fix before merging:
- Check `req.body.amount`: it must be a whole number and `0 < amount <= total_cents`. Probably only admins should be able to choose a custom amount.
- `db.one` throws when the order doesn't exist, so a missing order gives a 500 instead of a 404.
- Add a test that fires two refund requests at the same time.
