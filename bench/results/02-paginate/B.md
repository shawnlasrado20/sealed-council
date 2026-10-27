Bugs: `push(data.items)` nests arrays; a short page can still have a successor; `next` should control pagination; appending `?page=` breaks existing queries; HTTP errors and rate limits are ignored.

```ts
type Page<T> = { items: T[]; next: string | null };

async function fetchAll<T = unknown>(url: string): Promise<T[]> {
  const out: T[] = [];
  let next: string | null = url;
  let retries = 0;

  while (next !== null) {
    const res = await fetch(next);

    if (res.status === 429) {
      if (++retries > 5) throw new Error("Rate-limit retry limit exceeded");

      const header = res.headers.get("Retry-After");
      const seconds = header === null ? NaN : Number(header);
      const delay = Number.isFinite(seconds)
        ? seconds * 1000
        : header === null ? NaN : Date.parse(header) - Date.now();

      await new Promise(resolve =>
        setTimeout(resolve, Math.max(0, Number.isFinite(delay) ? delay : 1000))
      );
      continue; // Retry the same page.
    }

    if (!res.ok) throw new Error(`HTTP ${res.status}`);

    const data: Page<T> = await res.json();
    if (
      !Array.isArray(data?.items) ||
      !(data.next === null || typeof data.next === "string")
    ) {
      throw new Error("Invalid pagination response");
    }

    for (const item of data.items) out.push(item);
    next = data.next === null
      ? null
      : new URL(data.next, res.url || next).href;
    retries = 0;
  }

  return out;
}
```

`Retry-After` supports both seconds and HTTP dates. Relative `next` links resolve against the response URL.

Not executed; item contents remain unvalidated. Assumes an absolute starting URL and trustworthy, terminating pagination links.