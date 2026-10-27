It caches `None` correctly: `(None, timestamp)` is a nonempty, truthy tuple. The timestamp starts after `fetch` completes, so fetching does not consume the TTL.

The problems are:

- **Concurrent misses:** checking, fetching, and storing are separate operations. Multiple threads can fetch the same user simultaneously. The GIL does not make this sequence atomic.
- **Overwriting newer results:** overlapping fetches can finish out of order, allowing an older result to overwrite a newer one.
- **Wall-clock changes:** `time.time()` can jump backward or forward, extending or shortening cache lifetimes. Use `time.monotonic()`.
- **Unbounded retention:** expired entries remain indefinitely unless their UID is requested again. Many distinct UIDs can exhaust memory.
- **Potential key collisions:** if different `fetch` functions represent different data sources, UID alone is insufficient. This depends on the caller’s contract.

A minimal, bounded, thread-safe version, assuming one shared user source:

```python
import threading
import time

_cache = {}
_lock = threading.Lock()
_MAX_ENTRIES = 10_000

def get_user(uid, fetch, ttl=60):
    with _lock:
        now = time.monotonic()
        hit = _cache.get(uid)
        if hit is not None and now - hit[1] < ttl:
            return hit[0]

        user = fetch(uid)  # Exceptions propagate; no result is stored.
        if uid not in _cache and len(_cache) >= _MAX_ENTRIES:
            del _cache[next(iter(_cache))]
        _cache[uid] = (user, time.monotonic())
        return user
```

This serializes fetches, preventing overlapping writes. Eviction uses insertion order, not LRU.

Skipped execution and per-key concurrency optimization. Risk: a two-second fetch blocks all cache access; `fetch` must not reenter `get_user`.