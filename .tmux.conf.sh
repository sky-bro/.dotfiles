#!/usr/bin/env bash

set -u

tmux_bind_clipboard() {
    local clipboard_command="$1"
    tmux bind-key -T copy-mode-vi y \
        send-keys -X copy-pipe-and-cancel "$clipboard_command"
    tmux bind-key -T copy-mode-vi MouseDragEnd1Pane \
        send-keys -X copy-pipe-and-cancel "$clipboard_command"
}

case "$(uname -s)" in
    Darwin)
        tmux_bind_clipboard pbcopy
        ;;
    Linux)
        if [[ -n "${WSL_DISTRO_NAME:-}" ]]; then
            tmux_bind_clipboard /mnt/c/Windows/System32/clip.exe
        else
            tmux bind-key -T copy-mode-vi y \
                send-keys -X copy-selection-and-cancel
        fi
        ;;
    *)
        tmux bind-key -T copy-mode-vi y \
            send-keys -X copy-selection-and-cancel
        ;;
esac
