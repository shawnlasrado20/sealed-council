#!/bin/bash
# Supported install: git clone … && ./install.sh
# --uninstall removes only symlinks that point into this clone.
set -u

ROOT=$(cd "$(dirname "$0")" && pwd)
BIN_SRC="$ROOT/bin/sealed-council"
HOME_DIR="${HOME:?}"
CLAUDE_DEST="$HOME_DIR/.claude/skills/sealed-council"
AGENTS_DEST="$HOME_DIR/.agents/skills/sealed-council"
BIN_DEST="$HOME_DIR/.local/bin/sealed-council"

die() { echo "install.sh: $1" >&2; exit 1; }

resolved_target() {
  local dest=$1 t dir
  [ -L "$dest" ] || return 1
  t=$(readlink "$dest")
  case $t in
    /*) printf '%s\n' "$t" ;;
    *) dir=$(cd "$(dirname "$dest")" && pwd); printf '%s\n' "$dir/$t" ;;
  esac
}

points_here() {
  local got
  got=$(resolved_target "$1") || return 1
  case $got in
    "$ROOT"|"$ROOT"/*) return 0 ;;
    *) return 1 ;;
  esac
}

link_in() {
  local src=$1 dest=$2
  if [ -L "$dest" ]; then
    if [ "$(resolved_target "$dest")" = "$src" ]; then
      echo "ok $dest"
      return 0
    fi
    die "refuse to overwrite $dest"
  fi
  [ -e "$dest" ] && die "refuse to overwrite $dest"
  mkdir -p "$(dirname "$dest")"
  ln -s "$src" "$dest"
  echo "linked $dest -> $src"
}

uninstall_one() {
  local dest=$1
  if [ ! -e "$dest" ] && [ ! -L "$dest" ]; then
    return 0
  fi
  if [ ! -L "$dest" ]; then
    echo "leave $dest (not a symlink)"
    return 0
  fi
  if points_here "$dest"; then
    rm -f "$dest"
    echo "removed $dest"
  else
    echo "leave $dest (does not point into $ROOT)"
  fi
}

SKILL_SRC="$ROOT/skills/sealed-council"
[ -f "$SKILL_SRC/SKILL.md" ] || die "SKILL.md missing"
[ -x "$BIN_SRC" ] || die "missing executable $BIN_SRC"

case ${1:-} in
  --uninstall)
    uninstall_one "$CLAUDE_DEST"
    uninstall_one "$AGENTS_DEST"
    uninstall_one "$BIN_DEST"
    ;;
  "" )
    can_link() {
      local src=$1 dest=$2
      if [ -L "$dest" ]; then
        [ "$(resolved_target "$dest")" = "$src" ] && return 0
        return 1
      fi
      [ -e "$dest" ] && return 1
      return 0
    }
    can_link "$SKILL_SRC" "$CLAUDE_DEST" || die "refuse to overwrite $CLAUDE_DEST"
    can_link "$SKILL_SRC" "$AGENTS_DEST" || die "refuse to overwrite $AGENTS_DEST"
    can_link "$BIN_SRC" "$BIN_DEST" || die "refuse to overwrite $BIN_DEST"
    link_in "$SKILL_SRC" "$CLAUDE_DEST"
    link_in "$SKILL_SRC" "$AGENTS_DEST"
    link_in "$BIN_SRC" "$BIN_DEST"
    echo "CLI: $BIN_DEST  (put ~/.local/bin on PATH if needed)"
    ;;
  *)
    echo "usage: ./install.sh [--uninstall]" >&2
    exit 1
    ;;
esac
