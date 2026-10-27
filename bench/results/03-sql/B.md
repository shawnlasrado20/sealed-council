Create a composite expression index matching both the filter and ordering:

```sql
CREATE INDEX CONCURRENTLY events_lower_email_created_at_idx
ON events (lower(email), created_at DESC);
```

Keep the query unchanged:

```sql
SELECT *
FROM events
WHERE lower(email) = lower($1)
  AND created_at > now() - interval '7 days'
ORDER BY created_at DESC
LIMIT 20;
```

Why it works:

- The existing `email` index cannot directly support equality on `lower(email)`. The expression index can.
- With `lower(email)` first, PostgreSQL can seek directly to that email’s entries.
- Within those entries, `created_at` is ordered newest first. PostgreSQL can apply the seven-day range and stop after finding 20 rows, without a separate sort or scanning unrelated emails.
- `SELECT *` still requires fetching matching table rows, but the index sharply reduces the search.

`CONCURRENTLY` allows writes during index creation; run it **outside a transaction block**. An ascending second column could also satisfy this query through a backward scan.

Do not use a rolling partial index with `WHERE created_at > now() - interval '7 days'`: index predicates require immutable expressions, and `now()` is not immutable.

Not checked: the actual execution plan; verify with `EXPLAIN (ANALYZE, BUFFERS)`. Risk: building this index uses disk and I/O, and maintaining it adds write overhead.