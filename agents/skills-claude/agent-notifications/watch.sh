#!/usr/bin/env bash
# Follow the shared agent notification log.
#
# Meant to be run as the command of a dedicated Ghostty window; see SKILL.md.
# `tail -F` (not -f) so the window survives the log being rotated or deleted.

set -uo pipefail

LOG="${AGENT_NOTIFICATION_LOG:-$HOME/devel/AGENT_NOTIFICATIONS.log}"

mkdir -p "$(dirname "$LOG")"
touch "$LOG"

printf '\033[1mAgent notifications\033[0m \033[2m%s\033[0m\n\n' "$LOG"

exec tail -n 20 -F "$LOG"
