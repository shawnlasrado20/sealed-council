**Bugs**

1. **Nested results.** `out.push(data.items)` pushes each page in as a single array, so you get `[[...], [...]]` instead of a flat list. Use `push(...data.items)`.
2. **Wrong stop condition.** The API signals the last page with `next === null`, but the code ignores `next`. When the last page has exactly 50 items, the code makes one extra request. That usually returns an empty page and ends the loop, but it can also fail.
3. **Broken URL building.** `` `${url}?page=` `` produces an invalid URL if `url` already has a query string. Following `next` avoids building page URLs at all.
4. **No status check.** A 429 or 500 response is parsed as data. `data.items` is then `undefined`, and `.length` throws.
5. **Rate limits ignored.** A 429 should wait for `Retry-After`, which can be seconds or an HTTP date, and then retry the same page. Retries need a cap.

**Corrected**

```ts
type Page<T> = { items: T[]; next: string | null };

const sleep = (ms: number) => new Promise(r => setTimeout(r, ms));

function retryDelay(h: string | null, attempt: number): number {
  if (h !== null) {
    const s = Number(h);
    if (Number.isFinite(s)) return Math.max(0, s * 1000);
    const d = Date.parse(h);
    if (!Number.isNaN(d)) return Math.max(0, d - Date.now());
  }
  return Math.min(1000 * 2 ** attempt, 30_000); // fallback backoff
}

async function fetchAll<T = unknown>(url: string, maxRetries = 5): Promise<T[]> {
  const out: T[] = [];
  let next: string | null = url;
  let retries = 0;

  while (next !== null) {
    const res = await fetch(next);

    if (res.status === 429) {
      if (retries >= maxRetries) throw new Error(`Rate limited: ${next}`);
      await sleep(retryDelay(res.headers.get("Retry-After"), retries++));
      continue; // retry same page
    }
    if (!res.ok) throw new Error(`HTTP ${res.status} for ${next}`);

    const data = (await res.json()) as Page<T>;
    if (!Array.isArray(data?.items) ||
        !(data.next === null || typeof data.next === "string")) {
      throw new Error("Invalid pagination response");
    }

    out.push(...data.items);
    // next may be relative; resolve against the final response URL
    next = data.next === null ? null : new URL(data.next, res.url || next).href;
    retries = 0;
  }
  return out;
}
```

**Notes**
- This code has not been run.
- It assumes `next` is a URL. If `next` is a cursor token, build the URL from it with `URLSearchParams` instead.
- It assumes the pagination links eventually end. The items themselves are not validated.
