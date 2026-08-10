#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source_config="$repo_dir/config/sshd/010-dotfiles.conf"
target_config="/etc/ssh/sshd_config.d/010-dotfiles.conf"
action=check

usage() {
  cat <<'EOF'
Usage: config/sshd/manage.sh [--check|--apply|--disable]

  --check    Validate and report the system configuration change (default).
  --apply    Install the configuration and enable macOS Remote Login.
  --disable  Disable macOS Remote Login without deleting the configuration.
EOF
}

while (($#)); do
  case "$1" in
    --check) action=check ;;
    --apply) action=apply ;;
    --disable) action=disable ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown argument: $1" >&2; usage >&2; exit 2 ;;
  esac
  shift
done

validate_config() {
  local validate_dir host_key validate_config validation_output validation_status
  validate_dir="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-sshd.XXXXXX")"
  host_key="$validate_dir/host_key"
  validate_config="$validate_dir/sshd_config"

  ssh-keygen -q -t ed25519 -N "" -f "$host_key"
  {
    printf 'HostKey %s\n' "$host_key"
    printf 'Include %s\n' "$source_config"
  } > "$validate_config"

  validation_status=0
  validation_output="$(/usr/sbin/sshd -t -f "$validate_config" 2>&1)" \
    || validation_status=$?
  rm -f "$validate_config" "$host_key" "${host_key}.pub"
  rmdir "$validate_dir"

  if ((validation_status != 0)); then
    echo "$validation_output" >&2
    return "$validation_status"
  fi
}

validate_config
echo "valid   $source_config"

if [[ "$action" == check ]]; then
  if [[ -f "$target_config" ]] && cmp -s "$source_config" "$target_config"; then
    echo "ok      $target_config"
  elif [[ -e "$target_config" ]]; then
    echo "replace $target_config (backup first)"
  else
    echo "create  $target_config"
  fi
  echo "check   macOS Remote Login state (administrator access required)"
  exit 0
fi

if ((EUID != 0)); then
  echo "Administrator access is required; run this command with sudo." >&2
  exit 1
fi

if [[ "$action" == disable ]]; then
  /usr/sbin/systemsetup -setremotelogin off
  echo "disabled macOS Remote Login"
  exit 0
fi

timestamp="$(date +%Y%m%d-%H%M%S)-$$"
backup_dir="/var/backups/dotfiles/sshd/$timestamp"
install_tmp="${target_config}.tmp.$$"

cleanup_install() {
  rm -f "$install_tmp"
}
trap cleanup_install EXIT

if [[ -e "$target_config" ]] && ! cmp -s "$source_config" "$target_config"; then
  mkdir -p "$backup_dir"
  cp -p "$target_config" "$backup_dir/"
  echo "backed up $target_config to $backup_dir/"
fi

install -o root -g wheel -m 0644 "$source_config" "$install_tmp"
mv "$install_tmp" "$target_config"
echo "installed $target_config"

/usr/sbin/systemsetup -setremotelogin on
echo "enabled macOS Remote Login"

echo
echo "Verify from another terminal before ending the local session:"
echo "  ssh sky@<mac-address>"
