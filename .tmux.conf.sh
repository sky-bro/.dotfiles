#!/usr/bin/env bash

set -u

# Menu commands contain only quoted shell arguments; names are display-only.
tmux_menu_command() {
    local command
    printf -v command '%q ' bash "$HOME/.tmux.conf.sh" "$@"
    command=${command//\\/\\\\}
    command=${command//\"/\\\"}
    printf 'run-shell "%s"' "$command"
}

tmux_move_pane_menu() {
    local source="$1" client="$2" session_id session_name window_id window_index window_name
    local destination="${3:-}" label source_window source_session
    local -a menu=()

    if [[ -z "$destination" ]]; then
        source_session=$(tmux display-message -p -c "$client" -t "$source" '#{session_id}') || return
        while IFS=$'\t' read -r session_id session_name; do
            label="Session: $session_name"
            [[ "$session_id" == "$source_session" ]] && label+=' [current]'
            menu+=("${label//#/##}" "" "$(tmux_menu_command move-pane-menu "$source" "$client" "$session_id")")
        done < <(tmux list-sessions -F $'#{session_id}\t#{session_name}')
        tmux display-menu -c "$client" -t "$source" -T 'Move pane: choose session' \
            -x C -y C "${menu[@]}"
    else
        source_window=$(tmux display-message -p -t "$source" '#{window_id}') || return
        menu+=("New window" n "$(tmux_menu_command move-pane-new "$source" "$client" "$destination")" "")
        while IFS=$'\t' read -r window_id window_index window_name; do
            label="$window_index: $window_name"
            if [[ "$window_id" == "$source_window" ]]; then
                # A leading hyphen makes a tmux menu item visible but disabled.
                label="-$label [current]"
                menu+=("${label//#/##}" "" "")
            else
                menu+=("${label//#/##}" "" "$(tmux_menu_command move-pane-window "$source" "$client" "$destination" "$window_id")")
            fi
        done < <(tmux list-windows -t "$destination" -F $'#{window_id}\t#{window_index}\t#{window_name}')
        menu+=("" "Back to sessions" b "$(tmux_menu_command move-pane-menu "$source" "$client")")
        tmux display-menu -c "$client" -t "$source" -T 'Move pane: choose window' \
            -x C -y C "${menu[@]}"
    fi
}

tmux_place_marked() {
    local direction="$1" target="$2" source
    local -a split=()
    if [[ "$(tmux display-message -p -t "$target" '#{pane_marked_set}')" != 1 ]]; then
        tmux display-message -t "$target" 'Mark a source pane with Ctrl-a M first'
        return
    fi
    source=$(tmux display-message -p -t '{marked}' '#{pane_id}') || return
    if [[ "$source" == "$target" ]]; then
        tmux display-message -t "$target" 'Focus a different target pane; Ctrl-a M cancels the mark'
        return
    fi
    case "$direction" in
        left) split=(-h -b) ;;
        down) split=(-v) ;;
        up) split=(-v -b) ;;
        right) split=(-h) ;;
        *) return 1 ;;
    esac
    # Keep the mark if insertion fails (for example, not enough space).
    tmux move-pane "${split[@]}" -s "$source" -t "$target" && tmux select-pane -M
}

tmux_move_pane() {
    local mode="$1" source="$2" client="$3" session="$4" original_session status
    original_session=$(tmux display-message -p -c "$client" '#{client_session}') || return
    # Leave before removing the last source window, which may destroy its session.
    tmux switch-client -c "$client" -t "$session" || return
    if [[ "$mode" == move-pane-new ]]; then
        tmux break-pane -d -s "$source" -t "$session:"
    else
        tmux move-pane -d -h -s "$source" -t "$5"
    fi
    status=$?
    if ((status != 0)); then
        tmux switch-client -c "$client" -t "=$original_session"
        return "$status"
    fi
    tmux select-window -t "$source"
    tmux select-pane -t "$source"
}

case "${1:-}" in
    place-marked) tmux_place_marked "$2" "$3"; exit ;;
    move-pane-menu) tmux_move_pane_menu "$2" "$3" "${4:-}"; exit ;;
    move-pane-new|move-pane-window) tmux_move_pane "$@"; exit ;;
esac

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
