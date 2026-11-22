#!/bin/bash
set -euo pipefail
source_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
case "${1:-}" in
  ''|--dry-run|--list|--build|--self-test|--compile) ;;
  *) echo 'Unknown option; run kill-window --help.' >&2; exit 2 ;;
esac
if (($# > 1)); then
  echo 'Expected at most one option; run kill-window --help.' >&2
  exit 2
fi
cache="${KILL_WINDOW_CACHE_DIR:-$HOME/Library/Caches/com.sky.dotfiles.kill-window}"
app="$cache/Kill Window.app"
binary="$app/Contents/MacOS/KillWindow"
plist="$app/Contents/Info.plist"
mkdir -p "$cache"
if [[ "${1:-}" != --compile ]]; then
  # Kernel-backed build lock: a killed launcher cannot leave a stale lock behind.
  /usr/bin/lockf -k -t 10 "$cache/build.lock" /bin/bash "$source_dir/macos.sh" --compile
  case "${1:-}" in
    --build) printf '%s\n' "$app" ;;
    --list|--self-test) "$binary" "$1" ;;
    # Let launcher scripts return immediately; the native app owns its lifetime/lock.
    *) /usr/bin/open -n "$app" --args "${1:---pick}" ;;
  esac
  exit
fi
if ! /usr/bin/xcrun --find swiftc >/dev/null 2>&1; then
  echo 'Swift compiler unavailable. Install Apple Xcode/Command Line Tools first.' >&2
  exit 1
fi
build_output=''
cleanup() {
  if [[ -n "$build_output" && -f "$build_output" ]]; then rm -f "$build_output"; fi
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
fingerprint="$(/usr/bin/shasum -a 256 "$source_dir/WindowPicker.swift" "$source_dir/macos.sh")"
if [[ ! -x "$binary" || ! -f "$plist" || ! -f "$cache/source.sha256" || "$(cat "$cache/source.sha256")" != "$fingerprint" ]]; then
  mkdir -p "$app/Contents/MacOS" "$cache/modules"
  build_output="$(mktemp "$cache/KillWindow.XXXXXX")"
  /usr/bin/xcrun swiftc -O -module-cache-path "$cache/modules" \
    "$source_dir/WindowPicker.swift" -o "$build_output"
  chmod 755 "$build_output"
  mv -f "$build_output" "$binary"
  build_output=''
  cat > "$plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleIdentifier</key><string>com.sky.dotfiles.kill-window</string>
<key>CFBundleName</key><string>Kill Window</string>
<key>CFBundleExecutable</key><string>KillWindow</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>LSUIElement</key><true/>
<key>NSHighResolutionCapable</key><true/>
</dict></plist>
PLIST
  printf '%s\n' "$fingerprint" > "$cache/source.sha256"
fi
