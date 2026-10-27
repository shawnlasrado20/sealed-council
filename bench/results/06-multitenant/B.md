**Pick (a): shared tables + `tenant_id`.** Stay on one Postgres. 500 tenants × 100k rows is still a small database. Do not buy isolation by multiplying schemas or databases.

Schema-per-tenant and database-per-tenant make every migration, backup, connection pool, and failover 40–500 times harder. At this size that cost is not worth it. Physical split does not magically fix a missing `WHERE tenant_id = …`; it only hides the bug until ops break.

**Isolation (this is the product):**
- `tenant_id NOT NULL` on every tenant-owned table; indexes lead with it.
- App role is not table owner and cannot bypass RLS.
- RLS: `USING (tenant_id = current_setting('app.tenant_id')::uuid)` (and matching `WITH CHECK`).
- Set `app.tenant_id` once per request from the **server-side** session (JWT / API key → tenant), never from a client-supplied header you trust blindly.
- One shared connection pool; `SET LOCAL` in the transaction.
- Tests that a tenant A token cannot read tenant B rows, including joins and raw SQL.
- No cross-tenant unique constraints unless they are global on purpose.

For the enterprise prospect: **logical isolation is real isolation** if RLS is mandatory and the app role cannot turn it off. If they mean “our bytes never sit next to anyone else’s,” sell a **dedicated instance** for that one customer (same schema, same code). Do not move the other 39 onto (b) or (c).

**Change your mind when:**
- A contract requires separate DB/cluster (residency, “no co-mingling,” dedicated key) **and** the deal pays for the ops.
- You need per-tenant PITR / export as a product.
- Tenants need incompatible schemas or extensions.
- A few tenants become huge noisy neighbors (tens of millions of rows, heavy analytics) — isolate **those** tenants, not the fleet.
- Tenant count heads toward many thousands **and** catalog/migration pain shows up — still prefer (a) plus sharding before (b)/(c).
