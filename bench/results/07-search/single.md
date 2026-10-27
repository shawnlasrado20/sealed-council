**Recommendation: Postgres full-text search now, pgvector in the same database later. Skip Elasticsearch/OpenSearch and hosted search for now.**

**Why Postgres FTS now**
- Every search is scoped to one user. 50M notes across 200k users is about 250 notes per user on average. That makes this a small-corpus problem, not a 50M-document one.
- Add a generated `tsvector` column and a composite GIN index on `(user_id, tsv)` using `btree_gin`. Rank with `ts_rank`. Even heavy users with tens of thousands of notes should come in well under 300 ms.
- There's no second datastore to sync, no CDC pipeline, and no index drift. Permissions stay correct because the query is just `WHERE user_id = $1`. For 3 engineers this matters more than anything else.
- Add `pg_trgm` if users want prefix or typo-tolerant matching on titles.

**Later: pgvector for semantic search**
- Store embeddings in a side table keyed by note_id. Use a modest embedding size, or `halfvec`, to keep storage manageable. 50M vectors at 1536 float dims is roughly 300 GB.
- Because results are per-user, you often don't need an ANN index. Filter by `user_id` through a btree index and compute exact distances over a few hundred rows. That's fast and has perfect recall. Add HNSW only if very large accounts need it, and watch out for filtered-ANN recall issues.
- Do hybrid search by merging FTS and vector results with reciprocal rank fusion in SQL.
- Backfill embeddings with an async job queue, and re-embed when a note is edited.

**When to move to OpenSearch or a hosted service (Algolia, Typesense, etc.)**
- You need advanced relevance tuning, faceting, strong multilingual stemming, or typo tolerance across the board.
- Search load starts hurting the main database's OLTP performance. Try a read replica first.
- Notes grow well past about 500M, or cross-user search becomes a feature.

Until one of those happens, a separate search cluster adds operational cost without solving a real problem.
