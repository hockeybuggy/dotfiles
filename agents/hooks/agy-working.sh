#!/usr/bin/env bash
# agy-working.sh — PreInvocation hook: mark the tmux window as busy.
#
# agy has no session-start/user-prompt event, only PreInvocation (fires
# before every model call). Reused here as the closest equivalent to
# Claude Code's UserPromptSubmit hook or pi's before_agent_start. See
# agents/agy/hooks.json.
#
# Input: a JSON payload on stdin (see hooks.md's "Common Input Fields");
# `workspacePaths[0]` is the project directory in interactive sessions
# (headless `-p` runs leave it empty). Output: a JSON object on stdout --
# PreInvocation accepts an empty one.

payload=$(cat)
workspace=$(printf '%s' "$payload" | jq -r '.workspacePaths[0] // empty' 2>/dev/null)
[ -n "$workspace" ] && export AGY_PROJECT_DIR="$workspace"

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
bash "$dir/tmux-title.sh" ⚡

echo '{}'
