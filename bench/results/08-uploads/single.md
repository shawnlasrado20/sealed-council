**Proposed design: direct-to-storage uploads and async workers**

1. **Upload straight to object storage.** The client asks the API for a presigned PUT URL (S3, R2 or GCS). The API creates a `photos` row with `status=pending` and returns `{photoId, uploadUrl}`. The browser then uploads the 25 MB file directly to the bucket, so the API never holds image bytes in memory. Enforce the size limit and content-type in the presigned policy. Use a separate private bucket for originals.

2. **Trigger processing from a queue.** A bucket "object created" event, or a client call to `POST /photos/{id}/complete`, puts a job on a managed queue (SQS, or a Postgres-backed queue like pg-boss or Sidekiq if you want fewer moving parts). Stay on managed services: a team of 2 should not run Kafka or Kubernetes.

3. **Resize in workers.** A small worker pool, or a serverless function such as Lambda or Cloud Run jobs, pulls jobs. It streams the original, validates it as a real image (decode, check dimensions, strip EXIF/GPS), and generates the 3 sizes with libvips (sharp), which uses far less memory than ImageMagick. It writes the outputs to a public or CDN-fronted bucket, then sets `status=ready` along with the URLs. Cap worker concurrency so memory per worker is bounded and predictable.

4. **Report status to the client.** The client polls `GET /photos/{id}` every 1 to 2 seconds and shows the local preview until the photo is `ready`. Polling is simple and good enough at this scale. Add SSE or websockets only if they are ever needed.

5. **Handle failures.**
   - Make jobs idempotent with deterministic output keys, so retries are safe.
   - Retry with backoff, about 3 attempts, then send the job to a dead-letter queue, mark the photo `failed` with a reason, and let the user re-upload.
   - Reject invalid or corrupt files permanently, without retrying.
   - Run a nightly sweep that deletes `pending` rows older than 24 hours and their orphaned objects, plus a bucket lifecycle rule for incomplete uploads.
   - Alert on DLQ depth and queue age.

**Result:** the API stays stateless and light, processing scales on its own, and peak load only delays processing instead of crashing the server.
