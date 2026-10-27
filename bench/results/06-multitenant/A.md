Choose **(a) shared tables with `tenant_id`**, backed by Postgres row-level security (RLS). At 40–500 customers and up to roughly 50 million rows, tenant count alone does not justify hundreds of schemas or databases. Shared tables keep migrations, pooling, and operations simple.

**Enforce isolation at several layers:**

- Make `tenant_id` mandatory. Include it in tenant-scoped unique constraints and foreign keys so references cannot cross tenants. Index common queries with `tenant_id` as appropriate.
- Enable and **force RLS**, with policies covering both reads and writes (`USING` and `WITH CHECK`).
- Run the app through a non-owner role without superuser or `BYPASSRLS` privileges. Keep migration credentials separate.
- Derive the tenant from authenticated membership, never an unchecked request parameter. Set tenant context transaction-locally; missing context must deny access. Apply the same rules to workers and exports.
- Test cross-tenant reads, writes, joins, and pooled-connection reuse. Tenant-scope caches, object storage, and search indexes too.

RLS protects against forgotten query filters; it does not protect against a fully compromised application that can select another tenant’s context.

Ask the enterprise prospect what “data isolation” means: access separation, dedicated infrastructure, encryption keys, residency, or independent restore. Document the guarantee before promising an architecture.

**Change to (c), database per tenant**, when contractual requirements demand a stronger boundary, independent backup/restore or residency, or a large tenant needs resource isolation. Dedicated infrastructure may also be necessary; separate databases on one server still share resources.

I would rarely choose **(b)**: schemas add migration and namespace complexity while retaining shared compute and privileged-access risks.

Skipped detailed capacity sizing; benchmark representative workloads. Main risk: shared infrastructure retains noisy-neighbor and operational blast-radius exposure.