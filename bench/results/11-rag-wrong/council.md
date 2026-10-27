**Find where it fails**

Pull 150-200 real queries, including the known bad answers. For each one, log the query, the retrieved chunks and their scores, the answer, and an expert-labeled gold article/span (or "unanswerable"). Tag every failure with one label:

- **Retrieval miss:** the right article exists but isn't in the top 3.
- **Chunk damage:** the article was retrieved, but the needed fact was split, buried or cut off. This is likely with 1,000-token chunks.
- **Stale/conflicting source:** an outdated or contradictory article was retrieved.
- **Generation error:** the evidence was enough and the answer was still wrong.
- **Coverage gap:** no article answers the question.

To separate retrieval failures from generation failures, rerun generation with the expert-chosen evidence. If the answer becomes correct, the problem is retrieval. If it is still wrong, the problem is generation or unclear documentation.

**First eval**

Build a small, human-labeled, held-out grounded-answer set. Measure:

- **Recall@3 and recall@10** for the gold evidence (the gap shows whether more candidates plus reranking would help), and how often a deprecated article outranks the current one.
- **Faithfulness:** every claim is supported by a cited chunk.
- **Correctness and currency** compared with the gold answer.
- **Abstention:** whether the bot declines or escalates on unanswerable or conflicting questions.

Report results by failure type and intent, not as one score. Calibrate any LLM judge against the human labels. Add fresh tickets regularly so the set doesn't drift away from real traffic.

**Fixes, in order (let the measured failure counts reorder them)**

1. **Corpus hygiene:** remove or supersede stale articles, resolve contradictions, add date/version/product metadata, and confirm that updates reach the index.
2. **Retrieval:** hybrid BM25+vector search, metadata filters, query rewriting, and a cross-encoder reranker over the top 20-50.
3. **Chunking:** split on headings, prepend the title and section, and tune chunk size against evidence recall.
4. **Grounded generation:** answer only from cited evidence, and escalate when evidence is missing or conflicting.
5. **Model changes last.**

Change one layer at a time and rerun the eval after each change. If recall is high but faithfulness is low, fix generation. If recall is low, leave the model alone.
