RANK: A > C

Both pick shared tables plus database-enforced row filters, reject schema-per-tenant, and treat “data isolation” as a question rather than a slogan. A is stronger because isolation is a system property: tenant comes from membership not a request field, missing context denies access, writes and joins are covered, workers/exports/caches/storage/search are in scope, and the limit of a fully compromised app is stated. Change-of-mind criteria also distinguish a separate database from dedicated machines.

C is more cookbook-concrete (key column order, transaction-local context, a paid dedicated path with the same schema) and lists more triggers to switch. It is weaker where it overclaims capacity, tests only cross-tenant reads, and treats the enterprise ask as a questionnaire to satisfy. A is the answer I would ship.
