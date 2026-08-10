#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
copyq_app="/Applications/CopyQ.app"
copyq_bin="$copyq_app/Contents/MacOS/CopyQ"
commands_file="$repo_dir/config/copyq/commands.ini"
markdown_link_script="$repo_dir/config/copyq/markdown-link.js"

if [[ ! -x "$copyq_bin" ]]; then
  echo "warning: CopyQ is not installed; skipping CopyQ configuration" >&2
  exit 0
fi

if ! "$copyq_bin" --version >/dev/null 2>&1; then
  echo "warning: CopyQ cannot start; follow docs/COPYQ.md#unsigned-app-on-macos" >&2
  exit 0
fi

open -a CopyQ

server_ready=false
for _ in {1..10}; do
  if "$copyq_bin" config check_clipboard >/dev/null 2>&1; then
    server_ready=true
    break
  fi
  sleep 0.5
done

if ! $server_ready; then
  echo "warning: CopyQ server did not start; follow docs/COPYQ.md#troubleshooting" >&2
  exit 0
fi

"$copyq_bin" config navigation_style 1 >/dev/null
"$copyq_bin" config tab_tree true >/dev/null
"$copyq_bin" config show_tab_item_count true >/dev/null
"$copyq_bin" config autostart true >/dev/null

escaped_commands_file="${commands_file//\\/\\\\}"
escaped_commands_file="${escaped_commands_file//\'/\\\'}"
escaped_markdown_link_script="${markdown_link_script//\\/\\\\}"
escaped_markdown_link_script="${escaped_markdown_link_script//\'/\\\'}"

"$copyq_bin" eval "
  var file = File('$escaped_commands_file');
  if (!file.open())
    throw 'Cannot open CopyQ commands file: ' + file.errorString();

  var commandData = str(file.readAll()).replace(
    /@MARKDOWN_LINK_SCRIPT@/g,
    '$escaped_markdown_link_script'
  );
  var imported = importCommands(commandData);
  var importedNames = imported.map(function(command) { return command.name; });
  var existing = commands().filter(function(command) {
    return importedNames.indexOf(command.name) < 0;
  });
  setCommands(existing.concat(imported));
" >/dev/null

echo "configured CopyQ"
