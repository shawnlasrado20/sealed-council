Move image bytes out of the API and resizing out of the request path. Use managed object storage, a managed queue, and one small worker service.

**Upload and storage**

1. The client requests an upload from the API. The API authenticates the user, creates a photo record with an opaque ID and `uploading` status, and returns a short-lived signed upload URL or form.
2. The client uploads directly to a private object-storage bucket. Enforce the 25 MB limit through the storage upload policy where supported; validate the stored object’s size before processing regardless.
3. A storage upload event sends the photo ID and object key to the queue. Keep originals and generated sizes under separate, immutable keys. Serve ready images through a CDN using appropriate access controls.

**Resizing**

A worker validates the actual image format and decoded pixel count, then generates the three sizes sequentially using a memory-efficient image library. Limit worker concurrency and memory; cap worker scaling to control cost. Never load multiple full-resolution images unnecessarily.

Write all outputs before marking the photo `ready`. The database stores status and output keys. Make processing idempotent: duplicate queue deliveries must safely produce the same result.

**Client status**

Return the photo ID immediately. Show upload progress locally, then poll an authenticated status endpoint for `processing`, `ready`, or `failed`. Polling is enough for a two-person team; WebSockets add little here.

**Failures**

Retry transient storage and processing errors with bounded exponential backoff. Send exhausted jobs to a dead-letter queue and alert. Reject invalid images permanently with a useful error. A scheduled cleanup marks abandoned uploads and overdue jobs failed and deletes orphaned objects. Retain originals long enough to retry processing.

Skipped: custom infrastructure and real-time push. Main risk: compressed images can decode far beyond 25 MB, so pixel limits and worker memory limits are essential.