Review this pull request for a payments service (Node + Postgres). Answer: MERGE or BLOCK, then the single most important problem and the fix, under 200 words.

PR #412 "Add refund endpoint"

```ts
// routes/refunds.ts
router.post("/orders/:id/refund", requireAuth, async (req, res) => {
  const order = await db.one("SELECT * FROM orders WHERE id = $1", [req.params.id]);
  if (order.user_id !== req.user.id && !req.user.isAdmin) return res.status(403).end();
  if (order.status === "refunded") return res.status(409).json({ error: "already refunded" });

  const amount = req.body.amount ?? order.total_cents;
  await stripe.refunds.create({ payment_intent: order.payment_intent, amount });

  await db.none("UPDATE orders SET status = 'refunded', refunded_cents = $1 WHERE id = $2",
    [amount, order.id]);
  res.json({ ok: true, amount });
});
```
Tests added: refund happy path, 403 for other user, 409 when already refunded.
