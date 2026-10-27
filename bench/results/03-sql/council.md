**Fix:** create a composite expression index that matches both the filter and the sort.

```sql
CREATE INDEX CONCURRENTLY events_lower_email_created_at_idx
    ON events (lower(email), created_at DESC);

ANALYZE events;
```

The query itself doesn't need to change.

**Why the existing indexes don't help**

- **`events(email)` can't be used for this filter.** That index stores raw `email` values, but the query filters on `lower(email)`, which is a different expression.
- **`events(created_at)` is slow.** Postgres can walk the last 7 days newest-first and check the email on each row. On a 30M-row table that window can be very large, so it may read a big slice of the table before it finds 20 matches.

**Why the new index works**

A B-tree index is read from its first column to its last.

1. Because `lower(email)` comes first, `lower(email) = lower($1)` becomes a direct lookup. Postgres jumps straight to that email's entries, and `lower($1)` is computed only once.
2. Within those entries, `created_at` is already stored newest-first. Postgres starts at the newest entry and reads in order.
3. It stops when it reaches 20 rows (the `LIMIT`) or passes the 7-day cutoff, whichever comes first.

There is no Sort step and no reading of other users' rows. `SELECT *` still has to fetch each matching row from the table, but that's cheap for 20 rows. Postgres can also read an index backwards, so plain `created_at` (ascending) would work too. `DESC` just matches the `ORDER BY`.

**Notes**

- `CONCURRENTLY` lets writes continue while the index builds. It must run outside a transaction block.
- Don't use a partial index with `WHERE created_at > now() - interval '7 days'`. Index conditions must be immutable, and `now()` is not.
- Check the plan with `EXPLAIN (ANALYZE, BUFFERS)`. You should see an Index Scan on the new index and no Sort node.
- The new index costs disk space and adds work on every write. If no other query uses `events(email)`, drop it.
- **Longer term:** store emails already lowercased, or use the `citext` type, and index `(email, created_at DESC)`. The query would then drop `lower()`.
