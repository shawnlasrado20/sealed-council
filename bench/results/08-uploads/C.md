Direct-to-object-storage upload, then resize asynchronously. Keep the original; never process 25 MB on the API process.

**Storage.** Put originals and derived files in object storage (S3/GCS/R2) behind a CDN. Key layout: `photos/{id}/original`, `photos/{id}/{thumb|medium|large}`. The API stores only metadata: id, owner, keys, content type, byte size, and `status` (`uploading` | `processing` | `ready` | `failed`).

**Upload.** Client asks the API for a short-lived presigned PUT (and a photo id). The API records `uploading` and returns the URL plus max size/type rules. The browser uploads straight to storage; the file never touches the API. On complete, the client (or an object-created event) tells the API, which sets `processing` and enqueues one job. Cap types (JPEG/PNG/WebP) and size in both the presign policy and a cheap HEAD/metadata check.

**Resizing.** One small worker (S3 event → Lambda, or a single queue consumer). It streams the original, writes three sizes with a bounded image library, then sets `ready`. Bound memory (max pixels, stream/decode in chunks). Concurrency stays low so two people can reason about cost and OOMs. Do not block the upload HTTP request.

**Status.** Upload returns `{id, status: "processing"}` immediately. The client polls `GET /photos/{id}` every few seconds (or SSE if you already have it). Show a placeholder until `ready`; then serve CDN URLs for the three sizes.

**Failures.** Keep the original. Retry the job with backoff (2–3 times), then `failed` plus a reason. Dead-letter the poison job. User can retry processing without re-uploading. Idempotent jobs keyed by photo id. Expire abandoned `uploading` rows. Scan for `processing` stuck past a timeout.

That is enough for two people: one bucket, one queue, one worker, no in-process decode on the API.
