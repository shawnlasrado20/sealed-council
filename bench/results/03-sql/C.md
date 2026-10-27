**Best fix:** a composite expression index that matches the predicates and the sort.

```sql
CREATE INDEX CONCURRENTLY events_lower_email_created_at_idx
  ON events (lower(email), created_at DESC);
```

**Why the existing indexes fail**

- `events(email)` cannot be used. `lower(email)` is an expression, so a btree on the raw column is not sargable.
- `events(created_at)` can scan the last 7 days newest-first, then filter by email. On 30M rows that window can be huge, so the engine may walk a large slice of the table before it finds 20 matches.

**Why this index works**

Btree indexes are used left-to-right. Leading `lower(email)` turns `lower(email) = lower($1)` into a point lookup. Trailing `created_at DESC` then:

1. Restricts to `created_at > now() - interval '7 days'`
2. Returns rows already in `ORDER BY created_at DESC`
3. Lets `LIMIT 20` stop after 20 hits (no full sort)

Postgres can scan a btree backwards, so `created_at` without `DESC` also works; matching the `ORDER BY` is clearer.

`SELECT *` still needs heap fetches, but 20 rows is cheap. `CONCURRENTLY` avoids a long write lock on a large table.

Do **not** use a partial index on “last 7 days”: `now()` is not immutable, so that predicate cannot be indexed as a rolling window.

Optional follow-up: store email already lowercased (or use `citext`) and index `(email, created_at DESC)` so queries need no `lower()`.
