#!/bin/bash
# @vicinae.schemaVersion 1
# @vicinae.title AI Sessions (Legacy)
# @vicinae.mode silent
# @vicinae.exec ["/bin/bash"]
# @vicinae.description Text fallback for the native Sesswitch extension
# @vicinae.packageName Sesswitch

set -euo pipefail

binary="$HOME/repos/sesswitch/bin/sesswitch"
if [[ ! -x "$binary" ]]; then
  echo "sesswitch is not built: $binary" >&2
  exit 1
fi

exec "$binary" pick
