**Bugs**

1. `out.push(data.items)` nests arrays (`[[...], [...]]`) instead of concatenating items.
2. Pagination uses `page` and `length < 50`. The API’s stop signal is `next === null`. A full last page (exactly 50 items) never breaks → infinite loop.
3. `` `${url}?page=` `` breaks URLs that already have a query string, and ignores `next` (likely a URL or cursor).
4. No status check. A 429 still calls `res.json()`, which can throw or yield garbage.
5. 429 / `Retry-After` is ignored (seconds or HTTP-date).
6. Missing `items` (or a non-array) throws on `.length`.

**Corrected**

```ts
async function fetchAll<T = unknown>(url: string): Promise<T[]> {
  const out: T[] = [];
  let next: string | null = url;

  while (next) {
    const res = await fetch(next);

    if (res.status === 429) {
      const raw = res.headers.get("Retry-After");
      const ms = raw
        ? /^\d+$/.test(raw)
          ? Number(raw) * 1000
          : Math.max(0, Date.parse(raw) - Date.now())
        : 1000;
      await new Promise((r) => setTimeout(r, ms || 1000));
      continue;
    }

    if (!res.ok) throw new Error(`HTTP ${res.status}`);

    const data: { items?: T[]; next: string | null } = await res.json();
    if (Array.isArray(data.items)) out.push(...data.items);
    next = data.next ?? null;
  }

  return out;
}
```

Follow `next` until null, flatten `items`, retry 429 after `Retry-After`.
