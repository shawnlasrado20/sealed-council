**No.** The function is not correct for a multithreaded server. It does cache `None` correctly, though: `(None, ts)` is a non-empty tuple, so it is truthy and counts as a hit.

**Bugs**

1. **Cache stampede.** The check, the fetch and the store are separate steps, and the GIL does not make them atomic. When an entry is missing or expired, every thread asking for that uid calls the 2-second `fetch`. One global lock held during `fetch` would make every request wait, cache hits included. The fix is a lock per uid, plus a second cache check after taking it.
2. **Stale overwrites.** Overlapping fetches can finish out of order, so an older result can replace a newer one.
3. **Wall-clock TTL.** `time.time()` jumps when NTP or a person changes the clock, so entries expire early or stay too long. Use `time.monotonic()`.
4. **Unbounded growth.** Nothing is ever evicted. Every lookup of a uid that doesn't exist adds a permanent `(None, t)` entry, so memory grows without limit.
5. **Key ignores `fetch`.** If callers pass different data sources, they get each other's cached data. In that case, key on `(fetch, uid)`.

Optional: a missing user stays "missing" for the full TTL. A shorter TTL for `None` results is reasonable, but that is a design choice, not a bug.

**Fixed**

```python
import threading, time
from collections import OrderedDict

_cache = OrderedDict()   # uid -> (user, expires_at)
_lock = threading.Lock()
_key_locks = {}          # uid -> [lock, refcount]
MAX_ENTRIES = 10_000

def _lookup(uid):
    with _lock:
        hit = _cache.get(uid)
        if hit is not None and time.monotonic() < hit[1]:
            _cache.move_to_end(uid)
            return True, hit[0]
        return False, None

def get_user(uid, fetch, ttl=60):
    found, user = _lookup(uid)
    if found:
        return user
    with _lock:
        entry = _key_locks.setdefault(uid, [threading.Lock(), 0])
        entry[1] += 1
    try:
        with entry[0]:                 # one fetch per uid
            found, user = _lookup(uid)  # filled while waiting?
            if found:
                return user
            user = fetch(uid)
            with _lock:
                _cache[uid] = (user, time.monotonic() + ttl)
                _cache.move_to_end(uid)
                while len(_cache) > MAX_ENTRIES:
                    _cache.popitem(last=False)
            return user
    finally:
        with _lock:
            entry[1] -= 1
            if entry[1] == 0:
                del _key_locks[uid]
```

Different uids still fetch in parallel, and the lock table removes its own entries. If `fetch` raises, nothing is cached and the next waiting thread tries again. I have not run this code.
