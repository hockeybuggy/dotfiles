#!/usr/bin/env bash
#
# tmux-agent-formats.sh -- check the agent glyph and agent row formats in
# .tmux.conf against a throwaway tmux server. Skips when the tmux on PATH has
# no OSC 7501 program status support (it needs 3.9 or a HEAD build).

set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
SOCKET="dotfiles-agent-formats-$$"

fail() {
    echo "FAIL: $*" >&2
    exit 1
}

t() {
    env -u TMUX -u TMUX_PANE -u HERDR_ENV -u HERDR_PANE_ID -u HERDR_SOCKET_PATH \
        -u HERDR_TAB_ID -u HERDR_WORKSPACE_ID -u HERDR_BIN_PATH \
        tmux -L "$SOCKET" "$@"
}

socket_path=""
cleanup() {
    t kill-server 2>/dev/null || true
    [ -z "$socket_path" ] || rm -f "$socket_path"
}
trap cleanup EXIT

t -f "$ROOT/.tmux.conf" new-session -d -s main -n shell sleep 3600
socket_path=$(t display-message -p '#{socket_path}')

report() {
    tty=$(t display-message -p -t "$1" '#{pane_tty}')
    printf '\033]7501;%s\033\\' "$2" > "$tty"
    sleep 0.3
}

empty=$(t display-message -p -t main '#{pane_id}')
report "$empty" 'state=idle:app=probe'
if [ -z "$(t display-message -p -t "$empty" '#{pane_program_state}')" ]; then
    echo "skip: this tmux has no OSC 7501 support"
    exit 0
fi
report "$empty" 'state=clear'

blocked=$(t new-window -d -t main -n themis -P -F '#{pane_id}' sleep 3600)
working=$(t new-window -d -t main -n gateway -P -F '#{pane_id}' sleep 3600)
t select-pane -t "$blocked" -T 'OC | Review #[fg=red]counts'
report "$blocked" 'state=blocked:app=opencode'
report "$working" 'state=working:app=claude-code'

glyph() {
    t display-message -p -t "$1" '#{E:@agent_window_glyph}'
}
case "$(glyph "$blocked")" in *'!'*) ;; *) fail "blocked window glyph: $(glyph "$blocked")" ;; esac
case "$(glyph "$working")" in *'●'*) ;; *) fail "working window glyph: $(glyph "$working")" ;; esac
[ -z "$(glyph "$empty")" ] || fail "a window without agents has a glyph: $(glyph "$empty")"

t set-option -p -t "$working" @agent_unseen 1
case "$(glyph "$working")" in *'✓'*) ;; *) fail "unseen window glyph: $(glyph "$working")" ;; esac

row=$(t display-message -p "$(t show-options -gv 'status-format[1]')")
case "$row" in *"range=pane|$blocked]"*) ;; *) fail "agent row has no click range for $blocked: $row" ;; esac
case "$row" in *'themis · Review ##[fg=red]counts'*) ;; *) fail "agent row did not strip 'OC | ' or escape #: $row" ;; esac
case "$row" in *"range=pane|$empty]"*) fail "agent row lists a pane without an agent: $row" ;; esac

keys=$(t list-keys -T prefix)
printf '%s\n' "$keys" | grep -q 'drover next' || fail "prefix+w is not bound to drover next"
printf '%s\n' "$keys" | grep -q 'drover prev' || fail "prefix+q is not bound to drover prev"
printf '%s\n' "$keys" | grep -q 'drover pick' || fail "prefix+a is not bound to drover pick"

echo "ok"
