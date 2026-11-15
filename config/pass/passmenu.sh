#!/bin/bash
set +x
set -euo pipefail
export PATH="${PATH:-/usr/bin:/bin}:$HOME/.local/share/mise/shims:/opt/homebrew/bin:/usr/local/bin"
if [[ $# -eq 0 ]]; then
  exec vicinae cmd launch @sky-bro/pass-passwords:passwords
fi
bundle="$HOME/.local/share/vicinae/extensions/pass-passwords/assets/pass-cli.cjs"
[[ -f "$bundle" ]] || { echo 'Build the Passwords extension before using CLI options.' >&2; exit 1; }
exec node "$bundle" "$@"
