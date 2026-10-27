## What can go wrong

1. **Missing argument.** If `$1` is empty, `cd` with no argument goes to `$HOME`, and the script deletes old `*.tar.gz` files there.
2. **`cd` failure is ignored.** If the path is wrong, unmounted or unreadable, the loop runs in cron's working directory (usually `$HOME`) and deletes files there.
3. **Unquoted variables.** A `BACKUP_DIR` or filename containing spaces or glob characters gets split and expanded. `rm` can then hit the wrong files.
4. **`$(ls *.tar.gz)`.** Reading the output of `ls` breaks on spaces and newlines in filenames. If nothing matches, the loop gets the literal string `*.tar.gz`, and `ls` and `stat` print errors.
5. **Filenames starting with `-`.** `stat` and `rm` treat a name like `-rf.tar.gz` as options.
6. **`rm -rf`.** A directory named `x.tar.gz` gets deleted recursively, and `-f` hides failures.
7. **`stat` failure.** If a file disappears mid-run, `stat` returns nothing and `[` fails with a syntax error.
8. **Relative paths.** Cron's working directory may not be what you expect.
9. **No safety floor.** If backups silently stop being made, the script eventually deletes every backup.
10. **No logging.** You get no record of what was deleted, and errors end up in cron mail, which may go nowhere.
11. **Overlapping runs.** With no lock, a slow run can overlap the next one.

## Safe version

```bash
#!/bin/bash
set -euo pipefail

dir=${1:?usage: $0 /abs/backup/dir}
keep_min=7

[[ $dir == /* && -d $dir ]] || { echo "invalid dir: $dir" >&2; exit 1; }

exec 9>"$dir/.cleanup.lock"
flock -n 9 || { echo "already running" >&2; exit 1; }

count=$(find "$dir" -maxdepth 1 -type f -name '*.tar.gz' | wc -l)
if (( count <= keep_min )); then
  echo "only $count backups, skipping" >&2
  exit 0
fi

find "$dir" -maxdepth 1 -type f -name '*.tar.gz' -mtime +29 \
  -print -delete | logger -t backup-cleanup
```

How it fixes the problems:

- **Argument and path checks:** a missing argument fails loudly, and the directory must be an absolute path that exists.
- **No `cd`:** nothing depends on the working directory.
- **`find` instead of `ls`:** it handles any filename safely and doesn't need quoting tricks.
- **Only real backup files:** `-type f` and `-maxdepth 1` limit deletion to regular files at the top level, so no directories are deleted recursively.
- **Age test:** `-mtime +29` matches files at least 30 full days old.
- **Safety floor:** if there are 7 or fewer backups, nothing is deleted.
- **Lock:** `flock` stops two runs from overlapping.
- **Logging:** each deleted file is written to syslog.

The floor only counts backups. For stronger protection, check that a recent backup exists before deleting anything.
