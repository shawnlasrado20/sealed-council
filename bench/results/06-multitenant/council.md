**Recommendation: (a) shared tables with `tenant_id`, enforced by Postgres row-level security (RLS).** At the top of your range, 500 tenants with 100k rows each is about 50M rows. One Postgres instance usually handles that, but benchmark your real workload to confirm. Shared tables give you one migration path, one connection pool and cheap onboarding. (b) makes migrations and pooling harder but still shares compute and privileged access. (c) is a stronger boundary, but it multiplies backups, migrations and failover.

**Enforcing isolation**
- Make `tenant_id NOT NULL` on every tenant-owned table. Include it in composite keys, foreign keys and unique constraints so rows cannot reference another tenant's data.
- `ENABLE` and `FORCE ROW LEVEL SECURITY` with `USING` and `WITH CHECK` policies on `tenant_id = current_setting('app.tenant_id', true)::uuid`. If no tenant is set, access is denied.
- Connect the app as a non-owner role without `BYPASSRLS`. Run migrations and admin work under a separate role and audit its use.
- Take the tenant from the authenticated session, never from a value the client sends. Set it with `SET LOCAL` in each transaction. Apply the same rules to workers and exports.
- In CI, test cross-tenant reads, writes, joins and pooled connection reuse. Scope caches, file storage and search indexes by tenant too.

RLS catches forgotten filters. It does not stop a compromised app that can set any tenant.

**Enterprise prospect:** Ask what "data isolation" means to them: access separation, dedicated infrastructure, their own keys, residency or independent restore. Write down the guarantee before you commit to an architecture. If they need physical separation, sell a dedicated database or instance at a premium. It runs the same schema and code; only routing changes. Leave everyone else where they are.

**What would change my mind**
- Many contracts requiring residency, customer-managed keys or no co-mingling: move to (c).
- Per-tenant point-in-time restore becomes a product requirement.
- Noisy neighbours that limits can't contain: move only those tenants out.
- Tenants need incompatible schemas.
- Data grows far past 50M rows: shard on `tenant_id`, for example with Citus, rather than adopting (b).
