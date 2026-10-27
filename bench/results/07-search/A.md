**Use Postgres full-text search now. Add semantic retrieval later, starting with pgvector if benchmarks support it.** For three engineers, avoid operating another distributed system before you need one.

Fifty million notes alone does not justify Elasticsearch. The important numbers are notes per user, query concurrency, document size, and how unevenly those notes are distributed.

For now:

- Store a `tsvector` covering title and body, with a GIN index. Index `user_id` separately and enforce ownership on every query.
- Use Postgres’s text-search query parser, rank matches, and return a bounded page. Give title matches more weight.
- Benchmark realistic queries against the largest accounts under concurrent reads and writes. Define “under 300 ms” as an end-to-end percentile target, such as p95, rather than an average.
- Inspect query plans: filtering by owner and searching text must work efficiently together. Separate indexes do not guarantee that.

This keeps updates transactional, avoids synchronizing a second datastore, and uses infrastructure the team already understands. Postgres search is a good first fit if advanced typo tolerance, faceting, and linguistic relevance are not immediate requirements.

Later, generate embeddings asynchronously and try **hybrid search**: combine lexical results with vector results using reciprocal rank fusion. Start with pgvector, but benchmark tenant-filtered recall and latency carefully; approximate vector indexes can return too few relevant matches when ownership filters are selective. Avoid embedding all 50M notes before validating usefulness and cost.

If Postgres cannot meet measured requirements without harming the primary workload, move retrieval to a **hosted search service** supporting lexical and vector search. Keep Postgres authoritative and synchronize changes reliably, including deletions. Self-managed Elasticsearch/OpenSearch is the last choice for this team.

Skipped deployment sizing and benchmarks. Main risk: large accounts and concurrent search can overload the primary database.