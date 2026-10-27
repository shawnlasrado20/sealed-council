I found five bugs:

1. **Nested results.** `out.push(data.items)` adds each page as one array element, so you get an array of arrays. Use `out.push(...data.items)`.
2. **`next` is ignored.** Checking `length < 50` breaks when the last page has exactly 50 items: you request one more page that may be empty or may error. The API tells you when to stop, so follow `next` until it is `null`.
3. **The status code is never checked.** A 429 or 500 response gets parsed as if it were data. Then `data.items` is `undefined` and `.length` throws, or an error body is treated as results.
4. **No rate-limit handling.** A 429 should wait for the time in `Retry-After` and then retry. That header can be a number of seconds or an HTTP date.
5. **Broken URL building.** `${url}?page=` produces an invalid URL if `url` already has a query string. Using `next` avoids building page URLs at all.

Corrected version:

```ts
interface Page<T> {
  items: T[];
  next: string | null;
}

const sleep = (ms: number) => new Promise(r => setTimeout(r, ms));

function retryAfterMs(header: string | null, attempt: number): number {
  if (header) {
    const secs = Number(header);
    if (!Number.isNaN(secs)) return secs * 1000;
    const date = Date.parse(header);
    if (!Number.isNaN(date)) return Math.max(0, date - Date.now());
  }
  return Math.min(1000 * 2 ** attempt, 30_000); // fallback backoff
}

async function fetchAll<T>(url: string, maxRetries = 5): Promise<T[]> {
  const out: T[] = [];
  let nextUrl: string | null = url;

  while (nextUrl) {
    let res: Response;
    for (let attempt = 0; ; attempt++) {
      res = await fetch(nextUrl);
      if (res.status !== 429) break;
      if (attempt >= maxRetries) throw new Error(`Rate limited: ${nextUrl}`);
      await sleep(retryAfterMs(res.headers.get("Retry-After"), attempt));
    }
    if (!res.ok) throw new Error(`HTTP ${res.status} for ${nextUrl}`);

    const data = (await res.json()) as Page<T>;
    out.push(...data.items);
    // next may be relative; resolve against the current URL
    nextUrl = data.next ? new URL(data.next, nextUrl).toString() : null;
  }
  return out;
}
```

Other changes:
- **Retry cap.** `maxRetries` stops a long rate limit from turning into an infinite loop.
- **Fallback wait.** If `Retry-After` is missing, it waits with exponential backoff (capped at 30 seconds).
- **Typing.** The generic `T` replaces `any`.
- **Assumption about `next`.** I've assumed `next` is a URL. If it's really a cursor token, build the URL from it with `URLSearchParams` instead.
