#!/usr/bin/env bash
# agy-done.sh — Stop hook: play the completion sound and reset the tmux
# window title.
#
# Fires when agy's execution loop terminates -- the closest equivalent to
# Claude Code's Stop hook or pi's agent_settled event. See
# agents/agy/hooks.json.
#
# Input: a JSON payload on stdin; `workspacePaths[0]` is the project
# directory in interactive sessions. Output: a JSON object with a required
# "decision" field -- any value other than "continue" lets the loop stop,
# which is what we want; these hooks only observe, never gate.

payload=$(cat)
workspace=$(printf '%s' "$payload" | jq -r '.workspacePaths[0] // empty' 2>/dev/null)
[ -n "$workspace" ] && export AGY_PROJECT_DIR="$workspace"

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
bash "$dir/done.sh"
bash "$dir/tmux-title.sh" 🤖

echo '{"decision":"stop"}'
