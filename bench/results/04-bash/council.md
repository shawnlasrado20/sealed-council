## What can go wrong

1. **Empty `$1`:** a bare `cd` goes to `$HOME`, so the script deletes old `*.tar.gz` files there.
2. **Unchecked `cd`:** if the path is wrong, unmounted or unreadable, deletion runs in cron's working directory instead.
3. **Unquoted `$BACKUP_DIR` and `$f`:** spaces and glob characters split the names or expand them into other names.
4. **Parsing `ls`:** breaks on whitespace and newlines in filenames. If nothing matches, `ls` prints an error and the loop silently does nothing.
5. **Names starting with `-`:** `stat` and `rm` read them as options because there is no `--`.
6. **`rm -rf`:** a directory named `x.tar.gz` is deleted recursively, and `-f` hides failures.
7. **`stat` failure:** if a file vanishes mid-run, `stat` returns nothing, `[` gets a malformed test, and the error is ignored.
8. **`CDPATH` or relative paths:** `cd` can end up in an unexpected directory.
9. **No retention floor:** if backups stop being made, within 30 days every archive is deleted.
10. **No lock:** a slow run can overlap the next night's run.
11. **No logging and no `set -e`:** failures are silent and nothing records what was deleted.
12. **mtime is a weak proxy:** a `touch` or a copy changes a file's age.

## Safe version

```bash
#!/bin/bash
set -euo pipefail

dir=${1:?usage: $0 /abs/backup/dir}
[[ $dir == /* && $dir != / && -d $dir ]] \
  || { echo "bad dir: $dir" >&2; exit 1; }

exec 9>"$dir/.cleanup.lock"
flock -n 9 || exit 0

# If the backup job has stalled, delete nothing
if [[ -z $(find "$dir" -maxdepth 1 -type f -name '*.tar.gz' -mtime -2 -print -quit) ]]; then
  logger -t backup-cleanup "no backup in 2 days; skipping"
  exit 1
fi

find "$dir" -maxdepth 1 -type f -name '*.tar.gz' -mtime +29 -print -delete \
  | logger -t backup-cleanup
```

- The directory must be an absolute path that exists and is not `/`. There is no `cd`, so nothing depends on the working directory.
- `find` handles any filename literally. `-type f` deletes only regular files: no directories and no symlinks. `-maxdepth 1` keeps it out of subdirectories.
- `-mtime +29` matches files at least 30 full days old.
- The script deletes nothing unless a backup from the last two days exists. This stops it from deleting every archive when the backup job breaks.
- `flock` stops runs from overlapping.
- Each deleted file is logged to syslog.

Test it on a directory of throwaway files before giving it to cron.
