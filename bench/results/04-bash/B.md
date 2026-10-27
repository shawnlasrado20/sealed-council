# Backup cleanup script review

## How it goes wrong

1. **Missing `$1`**: `cd` with an empty argument goes to `$HOME`. Cron then deletes `*.tar.gz` in the user’s home.
2. **`cd` not checked**: a bad path leaves you in cron’s cwd (`/` or `$HOME`) and deletes there.
3. **Unquoted `$BACKUP_DIR` / `$f`**: spaces, globs, and IFS splitting change the target.
4. **`$(ls *.tar.gz)`**: breaks on spaces/newlines; not for parsing; can hit `ARG_MAX`; a failed glob can iterate the literal `*.tar.gz`.
5. **`rm -rf`**: `-r` is wrong for files. A symlink named `*.tar.gz` that points at a directory is wiped recursively. Names starting with `-` become flags. `-f` hides errors.
6. **No `--`**: filenames can be parsed as options.
7. **`CDPATH`**: `cd` can land in another tree.
8. **mtime only**: `touch`/extract skips deletion; a copy can age a fresh backup.
9. **`stat` failure**: an empty `[ ]` test miscompares.
10. **No floor**: if nothing was written for 30+ days, every archive is removed.
11. **Silent cron**: no `set -euo pipefail`, no log.

## Safer version

```bash
#!/bin/bash
set -euo pipefail

dir=${1:?usage: "$0" BACKUP_DIR}
case $dir in
  ""|"/"|"."|"..") echo "refusing: $dir" >&2; exit 1 ;;
esac
[[ -d $dir ]] || { echo "not a dir: $dir" >&2; exit 1; }

find -- "$dir" -maxdepth 1 -type f -name '*.tar.gz' -mtime +30 -print -delete
```

Pass an absolute path. `-type f` skips dirs/symlinks; `-maxdepth 1` stays in that folder; `-print` logs; GNU `-mtime +30` is the 30-day cutoff (strictly older than 30×24h). To never drop the last copies, delete only after a “keep N newest” check.
