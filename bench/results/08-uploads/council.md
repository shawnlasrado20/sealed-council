## Design: upload straight to storage, resize in the background, client polls for status

**Storage.** Use one private bucket (S3, GCS or R2) with keys `photos/{id}/original` and `photos/{id}/{small|medium|large}`. Serve the three sizes through a CDN and never make originals public. Each database row holds: id, owner, keys, byte size, type, `status` (`uploading | processing | ready | failed`) and an error reason.

**Upload.** The client calls `POST /photos`. The API authenticates the user, creates an `uploading` row and returns the id plus a short-lived presigned URL. The browser uploads straight to the bucket, so the API never holds image bytes. Enforce the 25 MB limit in the upload policy where the method supports it (S3 presigned POST can; a plain presigned PUT cannot). Always check the object's size with a HEAD request before processing. On completion (a storage event, or `POST /photos/{id}/complete` with an owner check), set `processing` and queue one job.

**Resizing.** Use a managed queue (SQS, or pg-boss on your existing Postgres) and one small worker service or Lambda. The worker:
- checks the real format (JPEG, PNG or WebP);
- rejects images over a pixel cap (e.g. 50 MP) before fully decoding them, because a 25 MB file can expand to gigabytes in memory;
- uses libvips/sharp to make the three sizes one at a time and strips EXIF/GPS;
- writes all outputs before setting `ready`.

Keep concurrency low and fixed, with a memory limit per worker.

**Status.** The client shows upload progress and a local preview. It then polls `GET /photos/{id}` (owner-checked) every 1 to 2 seconds until the status is `ready` or `failed`. Skip WebSockets.

**Failures.**
- Jobs are idempotent with fixed output keys per photo id, so duplicate deliveries are harmless.
- Retry temporary errors 3 times with backoff, then send the job to a dead-letter queue and mark the photo `failed` with a reason. Alert on dead-letter queue depth and job age.
- Invalid or corrupt files fail permanently with no retry.
- Keep originals so a photo can be reprocessed without uploading again.
- A scheduled sweep expires `uploading` rows older than 24 hours, deletes leftover objects, and requeues or fails jobs stuck in `processing`. A bucket lifecycle rule cancels incomplete uploads.

**Footprint:** one bucket, one queue, one worker. Peak load now only delays processing instead of crashing the API.
