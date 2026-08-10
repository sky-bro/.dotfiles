#!/usr/bin/env bash
set -euo pipefail

xcode_app="/Applications/Xcode.app"
developer_dir="$xcode_app/Contents/Developer"
action=check

usage() {
  cat <<'EOF'
Usage: config/xcode/configure.sh [--check|--apply|--download-ios]

  --check         Report Xcode selection, first-launch, SDK, and simulator state.
  --apply         Select Xcode, accept its license, and install first-launch tools.
                  Run this action with sudo in a real terminal.
  --download-ios  Download the current iOS/iPadOS Simulator runtime as the user.
EOF
}

while (($#)); do
  case "$1" in
    --check) action=check ;;
    --apply) action=apply ;;
    --download-ios) action=download-ios ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown argument: $1" >&2; usage >&2; exit 2 ;;
  esac
  shift
done

if [[ ! -d "$xcode_app" ]]; then
  echo "Xcode is not installed at $xcode_app" >&2
  exit 1
fi

if [[ "$action" == apply ]]; then
  if ((EUID != 0)); then
    echo "Administrator access is required; run this command with sudo." >&2
    exit 1
  fi

  xcode-select --switch "$developer_dir"
  xcodebuild -license accept
  xcodebuild -runFirstLaunch
  echo "configured $developer_dir"
  exit 0
fi

if [[ "$action" == download-ios ]]; then
  if ((EUID == 0)); then
    echo "Run --download-ios as the login user, not with sudo." >&2
    exit 1
  fi

  xcodebuild -downloadPlatform iOS
  exit 0
fi

echo "installed:"
DEVELOPER_DIR="$developer_dir" xcodebuild -version

selected_dir="$(xcode-select -p 2>/dev/null || true)"
if [[ "$selected_dir" == "$developer_dir" ]]; then
  echo "selected:  $selected_dir"
else
  echo "selected:  ${selected_dir:-none}"
  echo "expected:  $developer_dir"
fi

if DEVELOPER_DIR="$developer_dir" xcodebuild -checkFirstLaunchStatus; then
  echo "first launch: complete"
else
  echo "first launch: incomplete"
fi

sdk_version="$(
  DEVELOPER_DIR="$developer_dir" \
    xcrun --sdk iphoneos --show-sdk-version 2>/dev/null || true
)"
echo "iPhoneOS SDK: ${sdk_version:-unavailable}"

echo "iOS/iPadOS simulator runtimes:"
DEVELOPER_DIR="$developer_dir" \
  xcrun simctl list runtimes 2>/dev/null \
  | awk '/^== Runtimes ==$|^iOS / {print}'
