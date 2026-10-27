A Postgres query is slow (4 s) on a 30M-row table:

```sql
SELECT * FROM events
WHERE lower(email) = lower($1) AND created_at > now() - interval '7 days'
ORDER BY created_at DESC LIMIT 20;
```
Existing indexes: `events(email)`, `events(created_at)`. What is the best fix? Give the exact SQL and explain why it works. Answer in at most 300 words.
