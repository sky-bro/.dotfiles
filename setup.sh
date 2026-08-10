#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
apply=false
install_packages=false

usage() {
  cat <<'EOF'
Usage: ./setup.sh [--check] [--apply] [--install-packages]

  --check             Show what would change (default).
  --apply             Back up conflicts and create managed symlinks.
  --install-packages  Install Brewfile packages before setup (macOS only).
EOF
}

while (($#)); do
  case "$1" in
    --check) apply=false ;;
    --apply) apply=true ;;
    --install-packages) install_packages=true ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown argument: $1" >&2; usage >&2; exit 2 ;;
  esac
  shift
done

if [[ "$(uname -s)" != Darwin ]]; then
  echo "This setup profile currently supports macOS only." >&2
  exit 1
fi

# shellcheck source=config/identity.env
source "$repo_dir/config/identity.env"

if $install_packages; then
  command -v brew >/dev/null 2>&1 || {
    echo "Homebrew is required: https://brew.sh" >&2
    exit 1
  }
  env -u HOMEBREW_API_DOMAIN \
      -u HOMEBREW_BOTTLE_DOMAIN \
      -u HOMEBREW_BREW_GIT_REMOTE \
      -u HOMEBREW_CORE_GIT_REMOTE \
      brew bundle --file "$repo_dir/Brewfile"

  if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
    git clone --depth=1 https://github.com/ohmyzsh/ohmyzsh.git "$HOME/.oh-my-zsh"
  fi
  zsh_custom="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
  if [[ ! -d "$zsh_custom/themes/powerlevel10k" ]]; then
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \
      "$zsh_custom/themes/powerlevel10k"
  fi
  if [[ ! -d "$zsh_custom/plugins/zsh-autosuggestions" ]]; then
    git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions \
      "$zsh_custom/plugins/zsh-autosuggestions"
  fi
fi

declare -a links=(
  "profiles/macos/zshrc:.zshrc"
  "profiles/macos/p10k.zsh:.p10k.zsh"
  "profiles/macos/wezterm.lua:.wezterm.lua"
  "config/mise/config.toml:.config/mise/config.toml"
  "config/colima/default.yaml:.colima/_templates/default.yaml"
  "config/vscode/settings.json:Library/Application Support/Code/User/settings.json"
  ".tmux.conf:.tmux.conf"
  ".tmux.conf.sh:.tmux.conf.sh"
  "config/ssh/config:.ssh/config"
  ".gnupg/gpg.conf:.gnupg/gpg.conf"
  ".gnupg/gpg-agent.conf:.gnupg/gpg-agent.conf"
)

timestamp="$(date +%Y%m%d-%H%M%S)-$$"
backup_root="${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles-backups/$timestamp"
did_backup=false

for mapping in "${links[@]}"; do
  source_rel="${mapping%%:*}"
  target_rel="${mapping#*:}"
  source_path="$repo_dir/$source_rel"
  target_path="$HOME/$target_rel"

  if [[ -L "$target_path" && "$(readlink "$target_path")" == "$source_path" ]]; then
    echo "ok      ~/$target_rel"
    continue
  fi

  if ! $apply; then
    [[ -e "$target_path" || -L "$target_path" ]] \
      && echo "replace ~/$target_rel (backup first)" \
      || echo "create  ~/$target_rel"
    continue
  fi

  mkdir -p "$(dirname "$target_path")"
  if [[ -e "$target_path" || -L "$target_path" ]]; then
    mkdir -p "$backup_root/$(dirname "$target_rel")"
    mv "$target_path" "$backup_root/$target_rel"
    did_backup=true
  fi
  ln -s "$source_path" "$target_path"
  echo "linked  ~/$target_rel"
done

if $install_packages; then
  if command -v mise >/dev/null 2>&1; then
    mise install
  else
    echo "warning: mise is unavailable; managed language runtimes were not installed" >&2
  fi

  if command -v code >/dev/null 2>&1; then
    while IFS= read -r extension; do
      [[ -z "$extension" || "$extension" == \#* ]] && continue
      code --install-extension "$extension"
    done < "$repo_dir/config/vscode/extensions.txt"
  else
    echo "warning: VS Code CLI is unavailable; extensions were not installed" >&2
  fi
fi

if command -v brew >/dev/null 2>&1; then
  brew_prefix="$(brew --prefix)"
  declare -a docker_plugins=(
    "docker-compose"
    "docker-buildx"
  )

  for plugin in "${docker_plugins[@]}"; do
    source_path="$brew_prefix/lib/docker/cli-plugins/$plugin"
    target_rel=".docker/cli-plugins/$plugin"
    target_path="$HOME/$target_rel"

    if [[ -L "$target_path" && "$(readlink "$target_path")" == "$source_path" ]]; then
      echo "ok      ~/$target_rel"
      continue
    fi

    if ! $apply; then
      [[ -e "$target_path" || -L "$target_path" ]] \
        && echo "replace ~/$target_rel (backup first)" \
        || echo "create  ~/$target_rel"
      continue
    fi

    if [[ ! -e "$source_path" ]]; then
      echo "warning: $plugin is not installed; re-run with --install-packages" >&2
      continue
    fi

    mkdir -p "$(dirname "$target_path")"
    if [[ -e "$target_path" || -L "$target_path" ]]; then
      mkdir -p "$backup_root/$(dirname "$target_rel")"
      mv "$target_path" "$backup_root/$target_rel"
      did_backup=true
    fi
    ln -s "$source_path" "$target_path"
    echo "linked  ~/$target_rel"
  done
fi

if $apply; then
  bash "$repo_dir/config/vscode/configure.sh" --apply
else
  bash "$repo_dir/config/vscode/configure.sh" --check
fi

if ! $apply; then
  echo
  echo "Dry run only. Re-run with --apply after reviewing the changes."
  exit 0
fi

chmod 700 "$HOME/.gnupg"
gpgconf --kill gpg-agent 2>/dev/null || true

configure_gpg_ssh_key() {
  local label="$1"
  local keygrip="$2"
  local priority="$3"

  if gpg-connect-agent "KEYINFO $keygrip" /bye 2>/dev/null \
      | grep -q "^S KEYINFO $keygrip "; then
    gpg-connect-agent \
      "KEYATTR $keygrip Use-for-ssh: $priority" /bye >/dev/null
    echo "configured $label for SSH with priority $priority"
  else
    echo "warning: $label authentication key is not installed" >&2
  fi
}

if gpg-connect-agent 'HELP KEYATTR' /bye >/dev/null 2>&1; then
  configure_gpg_ssh_key \
    "GitHub" "$GPG_GITHUB_AUTH_KEYGRIP" "$GPG_GITHUB_AUTH_PRIORITY"
  configure_gpg_ssh_key \
    "OpenWrt" "$GPG_OPENWRT_AUTH_KEYGRIP" "$GPG_OPENWRT_AUTH_PRIORITY"
  gpg-connect-agent RELOADAGENT /bye >/dev/null
else
  echo "warning: this GnuPG version does not support Use-for-ssh attributes" >&2
fi

openwrt_public_key="$HOME/.ssh/openwrt-gpg.pub"
openwrt_public_key_tmp="${openwrt_public_key}.tmp.$$"
if gpg --export-ssh-key "${GPG_OPENWRT_AUTH_SUBKEY}!" \
    > "$openwrt_public_key_tmp" 2>/dev/null; then
  chmod 644 "$openwrt_public_key_tmp"
  mv "$openwrt_public_key_tmp" "$openwrt_public_key"
  echo "exported OpenWrt SSH public key"
else
  rm -f "$openwrt_public_key_tmp"
  echo "warning: OpenWrt authentication subkey is not installed" >&2
fi

bash "$repo_dir/config/copyq/configure.sh"

git config --global user.name "$GIT_USER_NAME"
git config --global user.email "$GIT_USER_EMAIL"

if gpg --list-secret-keys "$GPG_PRIMARY_FINGERPRINT" >/dev/null 2>&1; then
  git config --global user.signingkey "${GPG_SIGNING_SUBKEY}!"
  git config --global commit.gpgsign true
  git config --global gpg.program "$(command -v gpg)"
  echo "configured Git identity and signing key ${GPG_SIGNING_SUBKEY}"
else
  echo "configured Git identity"
  echo "warning: GPG secret key is not installed; follow docs/GPG-MIGRATION.md" >&2
fi

echo
echo "Setup complete."
if $did_backup; then
  echo "Previous files were backed up to: $backup_root"
fi
