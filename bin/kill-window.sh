#!/bin/sh
# Shared entry point; resolve links installed in ~/.local/bin.
set -eu
entry=$0
while [ -L "$entry" ]; do
  directory=$(CDPATH='' cd -- "$(dirname -- "$entry")" && pwd)
  entry=$(readlink "$entry")
  case "$entry" in /*) ;; *) entry=$directory/$entry ;; esac
done
repo=$(CDPATH='' cd -- "$(dirname -- "$entry")/.." && pwd)
case "${1:-}" in
  -h|--help)
    cat <<'HELP'
Usage: kill-window [--dry-run | --list | --build | --self-test]
Click a window, review its owning process, then confirm force quit.
Esc or right-click cancels. Force quit closes every window of that process.
macOS: native picker; --dry-run only inspects, --list lists window owners,
       --build prepares the helper, --self-test checks selection and signaling.
Linux: original interactive xprop picker (requires xprop and notify-send).
HELP
    exit 0 ;;
  --compile) echo 'Unknown option; run kill-window --help.' >&2; exit 2 ;;
esac
case "$(uname -s)" in
  Darwin) exec /bin/bash "$repo/config/kill-window/macos.sh" "$@" ;;
  Linux)
    if [ "$#" -ne 0 ]; then
      echo 'Linux supports interactive selection only; see --help.' >&2
      exit 2
    fi
    exec /bin/sh "$repo/config/kill-window/linux.sh" ;;
  *) echo 'kill-window supports macOS and Linux.' >&2; exit 1 ;;
esac
