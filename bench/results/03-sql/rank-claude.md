RANK: C > B

Both answers give the same correct fix: an expression index on `(lower(email), created_at DESC)`, built with `CONCURRENTLY`. Both also rightly reject a rolling partial index because `now()` is not immutable, and both note that a backward scan would work too.

C ranks higher because it explains more of the "why." It says what each existing index does wrong: the raw `email` index can't be used for `lower(email)`, and the `created_at` index may have to walk a large 7-day window before it finds 20 matches. That diagnosis is what makes the fix convincing. C also explains how the index is read from left to right and how `LIMIT` lets the scan stop early. Its suggested follow-up, storing email already lowercased or using `citext`, is a useful long-term option.

B has better operational caveats: run `CONCURRENTLY` outside a transaction block, check with `EXPLAIN (ANALYZE, BUFFERS)`, and expect extra write and disk cost. Those are valuable, but they don't make up for its thinner explanation of why the current plan is slow.
