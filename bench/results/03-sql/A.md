**Fix:** add a composite expression index that matches the query's filter and sort:

```sql
CREATE INDEX CONCURRENTLY events_lower_email_created_at_idx
    ON events (lower(email), created_at DESC);

ANALYZE events;
```

**Why it works:**

1. **The current indexes can't be used for the email filter.** An index on `events(email)` stores raw `email` values. The query filters on `lower(email)`, which is a different expression, so the planner can't use that index for it. It falls back to the `created_at` index, a bitmap combination, or a sequential scan. Any of these can mean reading a week's worth of rows and running `lower()` on each one.

2. **An expression index matches the predicate exactly.** Indexing `lower(email)` makes `lower(email) = lower($1)` an indexable equality condition. The bind parameter side, `lower($1)`, is evaluated once, so that's fine.

3. **The column order covers both the filter and the sort.** With the equality column first and `created_at` second, all rows for one email sit next to each other in the index, already ordered by `created_at DESC`. Postgres does one index range scan:
   - it seeks to `(lower_email, now() - 7 days)`,
   - walks the entries in order,
   - and stops after 20 rows because of `LIMIT 20`.

   There's no sort step and no scan of unrelated rows. Cost is roughly 20 heap fetches plus a B-tree descent, so this should take milliseconds instead of 4 s.

4. **`CONCURRENTLY` avoids blocking writes** on a 30M-row table while the index builds.

**Follow-ups:**
- Once the new index is in use, drop `events(email)` if no other query needs it. That reduces write overhead.
- Check the result with `EXPLAIN (ANALYZE, BUFFERS)`. You should see an `Index Scan using events_lower_email_created_at_idx` with no Sort node.
- Alternative: make `email` a `citext` column, or normalize emails to lowercase on write, and then index `(email, created_at DESC)`. Either one removes the function call from every query.
- `SELECT *` still needs heap lookups. That's acceptable for 20 rows, so a covering index isn't worth it here.
