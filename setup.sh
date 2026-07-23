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
  ".tmux.conf:.tmux.conf"
  ".tmux.conf.sh:.tmux.conf.sh"
  ".gnupg/gpg.conf:.gnupg/gpg.conf"
  ".gnupg/gpg-agent.conf:.gnupg/gpg-agent.conf"
  ".gnupg/sshcontrol:.gnupg/sshcontrol"
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

if ! $apply; then
  echo
  echo "Dry run only. Re-run with --apply after reviewing the changes."
  exit 0
fi

chmod 700 "$HOME/.gnupg"
gpgconf --kill gpg-agent 2>/dev/null || true

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
