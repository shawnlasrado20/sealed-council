**Now: Postgres full-text search. Later: add pgvector on the same rows.**

This is not a 50M-document search problem. Search is per user. 50M notes / 200k users is ~250 notes each. Even 10k-note power users are small for a GIN index. The hard filter is `user_id`, not corpus size.

**Now — `tsvector` + GIN, always scoped to the owner**

Keep notes in Postgres. Add a `tsvector` column (generated from title + body), a GIN index, and queries of the form `WHERE user_id = $1 AND tsv @@ plainto_tsquery(...)`. Rank with `ts_rank`. Stay under 300 ms easily; you already have ACLs, backups, and transactions.

A 3-person team should not run Elasticsearch/OpenSearch. You would add dual-write or CDC, mapping, cluster ops, and a second failure domain for a workload Postgres already handles. Hosted search (Algolia, Elastic Cloud, Meilisearch) still needs a sync pipeline and a vendor bill. That is extra cost for keyword search over a user’s own notes.

Skip pgvector for v1. It does not replace BM25/keyword search, and you do not have embeddings or a ranking story yet.

**Later — pgvector, same table, hybrid rank**

When you want semantic search: embed on write, store a vector column, index with HNSW/IVFFlat, and combine FTS + ANN (RRF or a weighted score). Same `user_id` filter, same DB, no new product. Tune `work_mem`, vacuum, and `gin_pending_list_limit` as volume grows.

**Revisit only if** you need typo-tolerant search-as-you-type, heavy facets, or cross-user discovery. Then a hosted engine is the next step — still not a self-hosted ES cluster.

Do not introduce a search cluster until Postgres FTS is measurably the bottleneck.
