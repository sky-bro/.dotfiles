#!/usr/bin/env bash
set -euo pipefail

apply=false

case "${1:---check}" in
  --check) ;;
  --apply) apply=true ;;
  *) echo "Usage: $0 [--check|--apply]" >&2; exit 2 ;;
esac

domain="com.microsoft.VSCode"
key="ApplePressAndHoldEnabled"

if [[ "$(defaults read "$domain" "$key" 2>/dev/null || true)" == "0" ]]; then
  echo "ok      VS Code key repeat"
  exit 0
fi

if ! $apply; then
  echo "set     VS Code key repeat (requires logout/login)"
  exit 0
fi

defaults write "$domain" "$key" -bool false
echo "set     VS Code key repeat (logout/login required)"
