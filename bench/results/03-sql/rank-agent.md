RANK: B > A

Both prescribe the same correct index: `(lower(email), created_at DESC)` with a concurrent build, matching the `lower(email)` equality that the existing `email` btree cannot serve.

B is more accurate on access path: seek to that email’s slice, walk newest-first, apply the 7-day bound, stop at 20. A’s “seek to `(lower_email, now()-7 days)`” starts at the wrong end of a DESC key and would not yield newest-first without extra work. B also states two operational facts A misses: `CONCURRENTLY` cannot run inside a transaction, and a rolling partial index on `now()` is illegal because predicates must be immutable. The backward-scan note is correct.

A is stronger on pedagogy (why the raw `email` index is unused, `ANALYZE`, dropping a redundant btree, normalizing case, covering index not worth 20 heap fetches), but those extras do not offset the scan-start error.
