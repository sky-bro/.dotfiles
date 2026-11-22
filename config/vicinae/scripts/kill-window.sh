#!/bin/bash
# @vicinae.schemaVersion 1
# @vicinae.title Kill Window
# @vicinae.mode silent
# @vicinae.exec ["/bin/bash"]
# @vicinae.description Click a window and confirm force quitting its owning process
# @vicinae.packageName Window Tools

set -euo pipefail
exec "$HOME/.local/bin/kill-window"
