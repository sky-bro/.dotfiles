#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
apply=false
list_choices=false
interaction=auto
interactive=false
overrides=()

usage() {
  cat <<'EOF'
Usage: ./setup.sh [--check | --apply] [--interactive | --non-interactive] [--list]
                  [--with NAME] [--without NAME]

  --check             Show what would change (default).
  --apply             Choose software and configuration, then confirm before applying.
  --list              Show all choices and defaults, then exit.
  --interactive       Open the checklist even for a preview.
  --non-interactive   Use defaults and flags without a checklist or confirmation prompt.
  --with NAME         Select an item, or use software or configuration for a whole section.
  --without NAME      Skip an item or section. Later choices override earlier ones.
EOF
}

while (($#)); do
  case "$1" in
    --check) apply=false ;;
    --apply) apply=true ;;
    --install-packages) ;; # Legacy spelling. Software is now part of every plan.
    --list|--list-packages) list_choices=true ;;
    --interactive|--non-interactive)
      if [[ "$interaction" != auto && "$interaction" != "$1" ]]; then
        echo '--interactive and --non-interactive cannot be combined.' >&2
        exit 2
      fi
      interaction="$1"
      ;;
    --with|--without)
      if [[ ! ${2:-} =~ ^[a-z0-9][a-z0-9@._/-]*$ ]]; then
        echo "$1 requires an item or section name; see --list." >&2
        exit 2
      fi
      overrides+=("${1#--}:$2")
      shift
      ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown argument: $1" >&2; usage >&2; exit 2 ;;
  esac
  shift
done

if [[ "$interaction" == --interactive ]] ||
    { [[ "$interaction" == auto ]] && $apply && ! $list_choices; }; then
  interactive=true
fi

config_components=(
  'config-shell:on:Zsh, tmux and WezTerm'
  'config-mise:on:mise runtime settings'
  'config-vscode:on:VS Code settings and key repeat'
  'config-containers:on:Colima and Docker CLI plugins'
  'config-security:off:SSH, GnuPG and Git identity'
  'config-claude:off:Claude Code settings'
  'config-tools:on:Pass, Vicinae, Tailscale and window tools'
  'config-copyq:off:CopyQ settings and commands'
)

zsh_custom="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
shell_plugins=(
  "$HOME/.oh-my-zsh|https://github.com/ohmyzsh/ohmyzsh.git"
  "$zsh_custom/themes/powerlevel10k|https://github.com/romkatv/powerlevel10k.git"
  "$zsh_custom/plugins/zsh-autosuggestions|https://github.com/zsh-users/zsh-autosuggestions"
)

record_choice() {
  local name="$1" default="$2" kind="$3" install_id="$4" description="$5"
  local section=software override plan_row choice
  [[ "$kind" != config ]] || section=configuration
  known_choices+="$name "
  choice="$default"
  for override in ${overrides[@]+"${overrides[@]}"}; do
    case "$override" in
      "with:$name"|"with:$section") choice=on ;;
      "without:$name"|"without:$section") choice=off ;;
    esac
  done
  [[ "$choice" != on ]] || selected_choices+="$name "
  printf -v plan_row '%-9s %-9s %-23s %s' "$default" "$choice" "$name" "$description"
  choice_plan+="$plan_row"$'\n'
  if $interactive; then
    choice_rows+="$name"$'\t'"$default"$'\t'"$choice"$'\t'"$kind"$'\t'"$install_id"$'\n'
  fi
  REPLY="$choice"
}

read_package_file() {
  local manifest="$1" default="$2"
  local line name kind token install_id REPLY
  local entry_pattern='^(brew|cask|mas)[[:space:]]+"([^"]+)"'
  local group_pattern='# group: ([a-z0-9][a-z0-9@._/-]*)$'
  local mas_id_pattern='id:[[:space:]]*([0-9]+)'

  while IFS= read -r line || [[ -n "$line" ]]; do
    [[ "$line" =~ ^[[:space:]]*(#|$) ]] && continue
    if [[ ! "$line" =~ $entry_pattern ]]; then
      printf 'Invalid entry in %s: %s\n' "$manifest" "$line" >&2
      return 2
    fi
    kind="${BASH_REMATCH[1]}"
    token="${BASH_REMATCH[2]}"
    name="$token"
    if [[ "$line" =~ $group_pattern ]]; then
      name="${BASH_REMATCH[1]}"
    fi
    install_id="$token"
    if [[ "$kind" == mas && "$line" =~ $mas_id_pattern ]]; then
      install_id="${BASH_REMATCH[1]}"
    fi
    record_choice "$name" "$default" "$kind" "$install_id" "${line%% # group:*}"
    if [[ "$REPLY" == on ]]; then
      selected_brewfile+="$line"$'\n'
    fi
  done < "$manifest"
}

build_plan() {
  local component name details plugin installed
  selected_brewfile=''
  selected_choices=' '
  known_choices=' software configuration '
  choice_plan=''
  choice_rows=''
  for component in "${config_components[@]}"; do
    name="${component%%:*}"
    details="${component#*:}"
    record_choice "$name" "${details%%:*}" config - "${details#*:}"
  done
  for plugin in "${shell_plugins[@]}"; do
    installed=no
    [[ ! -d "${plugin%%|*}" ]] || installed=yes
    record_choice shell-plugins on plugin "$installed" "${plugin##*/}"
  done
  read_package_file "$repo_dir/Brewfile" on
  read_package_file "$repo_dir/Brewfile.optional" off
}

is_selected() {
  [[ "$selected_choices" == *" $1 "* ]]
}

if $interactive; then
  if $list_choices; then
    echo '--interactive and --list are separate modes.' >&2
    exit 2
  fi
  if [[ ! -t 0 || ! -t 1 ]]; then
    echo 'Interactive setup requires a terminal. Use --non-interactive for unattended setup, or --check for a text preview.' >&2
    exit 2
  fi
fi

build_plan
for override in ${overrides[@]+"${overrides[@]}"}; do
  if [[ "$known_choices" != *" ${override#*:} "* ]]; then
    echo "Unknown item or section: ${override#*:}; see --list." >&2
    exit 2
  fi
done

if $interactive; then
  if { selection="$(python3 "$repo_dir/config/macos/checklist.py" "$choice_rows" 3>&1 1>&4 4>&-)"; } 4>&1; then
    while IFS= read -r override; do
      [[ -n "$override" ]] && overrides+=("$override")
    done <<< "$selection"
  else
    status=$?
    if [[ "$status" == 130 ]]; then
      echo 'Cancelled. No changes applied.'
      exit 0
    fi
    exit "$status"
  fi
  build_plan
  if $apply; then
    preview_args=(--check)
    for override in ${overrides[@]+"${overrides[@]}"}; do
      preview_args+=("--${override%%:*}" "${override#*:}")
    done
    "$repo_dir/setup.sh" "${preview_args[@]}"
    if ! read -r -p 'Apply the selected software and configuration? [y/N] ' answer ||
        [[ "$answer" != [yY] && "$answer" != [yY][eE][sS] ]]; then
      echo 'Cancelled. No changes applied.'
      exit 0
    fi
  fi
fi

if ! $interactive || ! $apply; then
  printf '%-9s %-9s %-23s %s\n' Default Selected Name Item
  printf '%s\n' "$choice_plan"
fi
if $list_choices; then
  exit 0
fi

if [[ "$(uname -s)" != Darwin ]]; then
  echo "This setup profile currently supports macOS only." >&2
  exit 1
fi

if $apply && [[ -n "$selected_brewfile" ]]; then
  command -v brew >/dev/null 2>&1 || {
    echo "Homebrew is required: https://brew.sh" >&2
    exit 1
  }
  (
    brewfile="$(mktemp "${TMPDIR:-/tmp}/dotfiles-brewfile.XXXXXX")"
    trap 'rm -f "$brewfile"' EXIT
    printf '%s' "$selected_brewfile" > "$brewfile"
    env -u HOMEBREW_API_DOMAIN \
        -u HOMEBREW_BOTTLE_DOMAIN \
        -u HOMEBREW_BREW_GIT_REMOTE \
        -u HOMEBREW_CORE_GIT_REMOTE \
        brew bundle --file "$brewfile"
  )
fi

if is_selected shell-plugins; then
  for plugin in "${shell_plugins[@]}"; do
    plugin_path="${plugin%%|*}"
    [[ ! -d "$plugin_path" ]] || continue
    if $apply; then
      git clone --depth=1 "${plugin#*|}" "$plugin_path"
    else
      printf 'install %s\n' "$plugin_path"
    fi
  done
fi

declare -a links=(
  "config-shell:profiles/macos/zshrc:.zshrc"
  "config-shell:profiles/macos/p10k.zsh:.p10k.zsh"
  "config-shell:profiles/macos/wezterm.lua:.wezterm.lua"
  "config-mise:config/mise/config.toml:.config/mise/config.toml"
  "config-containers:config/colima/default.yaml:.colima/_templates/default.yaml"
  "config-vscode:config/vscode/settings.json:Library/Application Support/Code/User/settings.json"
  "config-claude:config/claude/settings.json:.claude/settings.json"
  "config-claude:config/claude/store-deepseek-key.sh:.local/bin/store-deepseek-key"
  "config-tools:config/tailscale/travel.py:.local/bin/tailscale-travel"
  "config-tools:config/vicinae/scripts/ai-sessions.sh:.local/share/vicinae/scripts/ai-sessions.sh"
  "config-tools:config/pass/passmenu.sh:.local/bin/passmenu"
  "config-tools:bin/kill-window.sh:.local/bin/kill-window"
  "config-tools:config/vicinae/scripts/kill-window.sh:.local/share/vicinae/scripts/kill-window.sh"
  "config-shell:.tmux.conf:.tmux.conf"
  "config-shell:.tmux.conf.sh:.tmux.conf.sh"
  "config-security:config/ssh/config:.ssh/config"
  "config-security:.gnupg/gpg.conf:.gnupg/gpg.conf"
  "config-security:.gnupg/gpg-agent.conf:.gnupg/gpg-agent.conf"
)

timestamp="$(date +%Y%m%d-%H%M%S)-$$"
backup_root="${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles-backups/$timestamp"
did_backup=false

manage_link() {
  local source="$1" target_rel="$2" target="$HOME/$2"

  if [[ -L "$target" && "$(readlink "$target")" == "$source" ]]; then
    echo "ok      ~/$target_rel"
  elif ! $apply; then
    if [[ -e "$target" || -L "$target" ]]; then
      echo "replace ~/$target_rel (backup first)"
    else
      echo "create  ~/$target_rel"
    fi
  else
    mkdir -p "$(dirname "$target")"
    if [[ -e "$target" || -L "$target" ]]; then
      mkdir -p "$backup_root/$(dirname "$target_rel")"
      mv "$target" "$backup_root/$target_rel"
      did_backup=true
    fi
    ln -s "$source" "$target"
    echo "linked  ~/$target_rel"
  fi
}

for mapping in "${links[@]}"; do
  is_selected "${mapping%%:*}" || continue
  mapping="${mapping#*:}"
  manage_link "$repo_dir/${mapping%%:*}" "${mapping#*:}"
done

if $apply; then
  if is_selected mise && is_selected config-mise && command -v mise >/dev/null 2>&1; then
    mise install
  elif is_selected mise && is_selected config-mise; then
    echo "warning: mise is unavailable; managed language runtimes were not installed" >&2
  fi

  if is_selected visual-studio-code && is_selected config-vscode && command -v code >/dev/null 2>&1; then
    while IFS= read -r extension; do
      [[ -z "$extension" || "$extension" == \#* ]] && continue
      code --install-extension "$extension"
    done < "$repo_dir/config/vscode/extensions.txt"
  elif is_selected visual-studio-code && is_selected config-vscode; then
    echo "warning: VS Code CLI is unavailable; extensions were not installed" >&2
  fi

  if is_selected vicinae && is_selected config-tools && command -v npm >/dev/null 2>&1 && command -v vicinae >/dev/null 2>&1; then
    (
      cd "$repo_dir/config/vicinae/passwords"
      npm ci
      npm run build
    )
  elif is_selected vicinae && is_selected config-tools; then
    echo "warning: npm or Vicinae is unavailable; Passwords extension was not built" >&2
  fi
fi

if is_selected config-containers && command -v brew >/dev/null 2>&1; then
  brew_prefix="$(brew --prefix)"
  for plugin in docker-compose docker-buildx; do
    plugin_source="$brew_prefix/lib/docker/cli-plugins/$plugin"
    if [[ -e "$plugin_source" ]] || { ! $apply && is_selected docker; }; then
      manage_link "$plugin_source" ".docker/cli-plugins/$plugin"
    fi
  done
fi

config_mode=--check
if $apply; then
  config_mode=--apply
fi
if is_selected config-vscode; then
  bash "$repo_dir/config/vscode/configure.sh" "$config_mode"
fi

if ! $apply; then
  if is_selected config-security; then
    echo 'configure SSH/GnuPG integration and global Git identity'
  fi
  if is_selected config-copyq; then
    echo 'configure CopyQ settings and commands if the app is installed'
  fi
  if is_selected mise && is_selected config-mise; then
    echo 'install managed mise runtimes'
  fi
  if is_selected visual-studio-code && is_selected config-vscode; then
    echo 'install managed VS Code extensions'
  fi
  if is_selected vicinae && is_selected config-tools; then
    echo 'build the Vicinae Passwords extension'
  fi
  echo
  echo "Dry run only. Re-run with --apply after reviewing the changes."
  exit 0
fi

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

if is_selected config-security; then
  # shellcheck source=config/identity.env
  source "$repo_dir/config/identity.env"
  chmod 700 "$HOME/.gnupg"
  gpgconf --kill gpg-agent 2>/dev/null || true

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
fi

if is_selected config-copyq; then
  bash "$repo_dir/config/copyq/configure.sh"
fi

echo
echo "Setup complete."
if $did_backup; then
  echo "Previous files were backed up to: $backup_root"
fi
