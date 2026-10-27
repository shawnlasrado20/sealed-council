RANK: A > B

The two answers are close. Both pick shared tables with row-level policies and give sound reasons. A is ahead on how isolation is enforced:
- It forces the policies even for the table owner.
- It builds the tenant into foreign keys and unique constraints, so references cannot cross tenants.
- It denies access by default when no tenant is set.
- It covers background workers, exports, caches, file storage and search indexes. These are common places for data to leak between tenants, and B skips them.
- It says plainly what the policies cannot protect against.
- For the prospect, it asks what "data isolation" means before promising anything. That is the right first move.

B is more concrete. It shows an actual policy and how the tenant is set per transaction. Its advice to give only that one customer a dedicated instance is a sharp, practical answer. Its triggers for changing course are also richer: per-tenant point-in-time restore, incompatible schemas, and moving only the largest tenants out. But "logical isolation is real isolation" is an overconfident sales line. It also likely goes over the 300-word limit and is thinner on enforcement.
