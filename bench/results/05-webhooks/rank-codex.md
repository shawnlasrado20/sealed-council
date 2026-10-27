RANK: C > B

C makes the better scope decision: explicitly decline ordering and provide resource versions so consumers can reject stale updates. Its retry window, request timeout, and worker heartbeat also make operations clearer.

B promises FIFO without implementing it: one in-flight request per endpoint prevents concurrency, but later events can overtake an earlier event waiting for retry. Its lease recovery is also unspecified, so crashed deliveries could remain stuck.

Both correctly choose transactional persistence, stable event IDs, uniqueness constraints, and at-least-once delivery. C still needs durable claim recovery, should avoid repeatedly retrying permanent client errors, and overreaches with a customer-facing resend interface.

Not checked: implementation behavior. Main risk: neither fully specifies recovery after a worker crashes.