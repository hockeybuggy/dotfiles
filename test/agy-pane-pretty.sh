#!/usr/bin/env bash

set -euo pipefail

REPO_ROOT=$(cd "$(dirname "$0")/.." && pwd)
FILTER="$REPO_ROOT/agents/skills-claude/use-agy-in-pane/pretty.jq"

actual=$(mktemp)
expected=$(mktemp)
trap 'rm -f "$actual" "$expected"' EXIT

cat <<'JSONL' | jq -rj -f "$FILTER" > "$actual"
{"event":"init","conversation_id":"x","init":{"cwd":"/tmp","tools":[]}}
{"event":"step_update","step_update":{"conversation_id":"x","step_index":0,"state":"DONE","step_type":"user_input"}}
{"event":"step_update","step_update":{"conversation_id":"x","step_index":1,"state":"DONE","step_type":"unknown","duration_seconds":0.0006}}
{"event":"step_update","step_update":{"conversation_id":"x","step_index":2,"state":"DONE","step_type":"agent_response","duration_seconds":4.2}}
{"event":"step_update","step_update":{"conversation_id":"x","step_index":3,"state":"ACTIVE","step_type":"tool","tool_name":"run_command","tool_info":{"name":"run_command","parameters":{"CommandLine":"ls -la ."}}}}
{"event":"step_update","step_update":{"conversation_id":"x","step_index":3,"state":"DONE","step_type":"tool","tool_name":"run_command","duration_seconds":0.11,"tool_info":{"name":"run_command","parameters":{"CommandLine":"ls -la ."},"output":"total 0\n"}}}
{"event":"step_update","step_update":{"conversation_id":"x","step_index":4,"state":"DONE","step_type":"checkpoint","duration_seconds":0.46}}
{"event":"step_update","step_update":{"conversation_id":"x","step_index":5,"state":"ACTIVE","step_type":"agent_response","text_delta":"The"}}
{"event":"step_update","step_update":{"conversation_id":"x","step_index":5,"state":"ACTIVE","step_type":"agent_response","text_delta":" dir is empty,"}}
{"event":"step_update","step_update":{"conversation_id":"x","step_index":5,"state":"DONE","step_type":"agent_response","text_delta":" total size 0.\n","duration_seconds":2.5}}
{"event":"result","result":{"conversation_id":"x","status":"SUCCESS","response":"The dir is empty, total size 0.\n"}}
JSONL

cat > "$expected" <<'OUTPUT'
▸ run_command  ls -la .
The dir is empty, total size 0.
OUTPUT

if ! diff -u "$expected" "$actual"; then
    echo "agy pane formatter output did not match" >&2
    exit 1
fi

echo "agy pane formatter output: ok"
