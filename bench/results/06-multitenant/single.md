**Recommendation: (a) shared tables with `tenant_id`, enforced by Postgres Row-Level Security. Keep a path open to (c) for the enterprise customer if they need it.**

**Why:** 500 tenants with at most 100k rows each is about 50M rows at the very top end. One Postgres instance handles that easily. Shared tables give you one migration path, one connection pool, simple cross-tenant analytics and cheap onboarding. Schema-per-tenant (b) costs you the most for the least: 500 schemas means slow migrations, catalog bloat and pooler headaches, and it isolates no better than RLS. Database-per-tenant (c) gives real isolation, but running hundreds of databases is too much overhead for a small team.

**Enforcing isolation:**
- Add `tenant_id NOT NULL` to every tenant-owned table, and put it first in composite primary keys, foreign keys and indexes. Composite FKs stop a row from referencing another tenant's data.
- Turn on RLS with `FORCE ROW LEVEL SECURITY`, using the policy `tenant_id = current_setting('app.tenant_id')::uuid`.
- The app connects as a non-owner role without `BYPASSRLS`. It sets the tenant with `SET LOCAL` inside each transaction, which is safe with PgBouncer transaction pooling.
- Use a separate privileged role only for migrations and admin work, and audit its use.
- Add CI tests that try to read across tenants and fail the build if they succeed.
- Encrypt at rest, and offer per-tenant export and deletion.

**For the enterprise prospect:** first ask what "data isolation" means to them. Usually it is a security-questionnaire item, and RLS plus a SOC 2 explanation is enough. If they need physical separation, give them their own database or cluster at a premium price, running the same schema with `tenant_id` still in place. The codebase stays the same and only the routing changes.

**What would change my mind:**
- Contracts that require data residency, customer-managed keys, or physically separate storage across many tenants would push me to (c).
- Noisy neighbours that per-tenant query limits can't contain.
- Per-tenant restore or point-in-time recovery becoming a frequent request.
- Heavy per-tenant schema customization.
- Tenant data growing to around 100M rows or more, which would mean sharding with something like Citus on `tenant_id`.
