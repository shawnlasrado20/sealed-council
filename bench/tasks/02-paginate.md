This TypeScript fetches all pages from an API. Find the bugs and give a corrected version. Answer in at most 300 words.

```ts
async function fetchAll(url: string) {
  let page = 1, out: any[] = [];
  while (true) {
    const res = await fetch(`${url}?page=${page}`);
    const data = await res.json();
    out.push(data.items);
    if (data.items.length < 50) break;
    page++;
  }
  return out;
}
```
The API returns `{ items: [...], next: string | null }`, pages hold up to 50 items, and it returns HTTP 429 with a Retry-After header when rate limited.
