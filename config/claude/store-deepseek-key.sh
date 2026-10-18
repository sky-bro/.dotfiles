#!/usr/bin/env bash
set -euo pipefail

service="com.sky.dotfiles.deepseek-api"
account="${USER:?USER is not set}"

if [[ ! -t 0 || ! -t 1 ]]; then
  echo "Run this command in an interactive terminal." >&2
  exit 1
fi

echo "Store or replace the DeepSeek API key in the macOS login keychain."
echo "The key will not be echoed or written to dotfiles."
exec /usr/bin/security add-generic-password \
  -U \
  -a "$account" \
  -s "$service" \
  -l "DeepSeek API key for Claude Code" \
  -w
