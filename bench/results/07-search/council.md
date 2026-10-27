**Now: Postgres full-text search. Later: pgvector in the same database. If measurements show Postgres can't keep up, move to a hosted search service. Run your own Elasticsearch/OpenSearch only as a last resort.**

**Why**
Every search covers only one user's notes. 50M notes across 200k users is about 250 notes each on average, so this is not really a 50M-document problem. Averages hide skew, though, so plan around your largest accounts.

**Now**
- Add a generated `tsvector` column from title and body, with titles ranked higher. Put one composite GIN index on `(user_id, tsv)` using `btree_gin`, so the user filter and the text match use the same index. Check this with `EXPLAIN ANALYZE`.
- Query `WHERE user_id = $1 AND tsv @@ websearch_to_tsquery(...)`, rank with `ts_rank` and return a limited page of results.
- Treat "under 300 ms" as end-to-end p95. Benchmark the largest accounts while other reads and writes are running.
- Add `pg_trgm` if users want prefix or fuzzy title matching.

There's no second datastore to keep in sync. Permissions, edits and deletes stay in the same transaction. For three engineers, that matters most.

**Later: semantic search**
- Store embeddings in a side table keyed by `note_id`. Generate them in the background when a note is written, and again when it's edited. Test with a small group before embedding all 50M notes. At 1536 float dimensions that is about 300 GB, so use fewer dimensions or `halfvec`.
- With a few hundred notes per user, you can compare against every note the user owns, using a btree index on `user_id` to find them. That is fast and never misses a match. Add an HNSW index only for very large accounts, and test how often it misses: approximate indexes can return too few results when the user filter is narrow.
- For hybrid search, merge keyword and vector results with reciprocal rank fusion in SQL.

**When to leave Postgres**
- Search load still hurts normal app traffic after you move search to a read replica.
- You need typo tolerance everywhere, filtering by categories, finer control over ranking, strong multilingual support or search across users.

At that point, choose a hosted engine that does both keyword and vector search. Keep Postgres as the source of truth and sync every change to the search service, deletes included.
