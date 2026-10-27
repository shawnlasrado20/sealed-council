Review this Python function. Is it correct? If not, list every bug and give a fixed version. Answer in at most 300 words.

```python
import time
_cache = {}

def get_user(uid, fetch, ttl=60):
    hit = _cache.get(uid)
    if hit and time.time() - hit[1] < ttl:
        return hit[0]
    user = fetch(uid)
    _cache[uid] = (user, time.time())
    return user
```
It is called from many threads in a web server. `fetch` takes about 2 seconds and sometimes returns None when the user does not exist.
