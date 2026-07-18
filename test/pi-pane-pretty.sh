#!/usr/bin/env bash

set -euo pipefail

REPO_ROOT=$(cd "$(dirname "$0")/.." && pwd)
FILTER="$REPO_ROOT/agents/skills/use-pi-in-pane/pretty.jq"

actual=$(mktemp)
expected=$(mktemp)
trap 'rm -f "$actual" "$expected"' EXIT

cat <<'JSONL' | jq -rj -f "$FILTER" > "$actual"
{"type":"message_update","assistantMessageEvent":{"type":"thinking_delta","delta":"**Inspecting the formatter**\n\n"}}
{"type":"message_update","assistantMessageEvent":{"type":"toolcall_start","partial":{"content":[{"type":"toolCall","name":"read","arguments":{}}]}}}
{"type":"message_update","assistantMessageEvent":{"type":"toolcall_delta","delta":"{\"path\":"}}
{"type":"message_update","assistantMessageEvent":{"type":"toolcall_end","toolCall":{"name":"read","arguments":{"path":"agents/skills/use-pi-in-pane/pretty.jq"}}}}
{"type":"tool_execution_start","toolCallId":"read-1","toolName":"read","args":{"path":"agents/skills/use-pi-in-pane/pretty.jq","offset":10,"limit":20}}
{"type":"tool_execution_start","toolCallId":"bash-1","toolName":"bash","args":{"command":"printf 'one'\nprintf 'two'","timeout":10}}
{"type":"tool_execution_start","toolCallId":"custom-1","toolName":"custom","args":{"target":"pane","verbose":true}}
{"type":"tool_execution_end","toolCallId":"bash-1","toolName":"bash","result":{"content":[{"type":"text","text":"permission denied\nmore detail"}]},"isError":true}
JSONL

cat > "$expected" <<'OUTPUT'
**Inspecting the formatter**

▸ read  agents/skills/use-pi-in-pane/pretty.jq (offset 10, limit 20)
▸ bash  printf 'one' printf 'two'
▸ custom  {"target":"pane","verbose":true}
✗ bash  permission denied more detail
OUTPUT

if ! diff -u "$expected" "$actual"; then
    echo "pi pane formatter output did not match" >&2
    exit 1
fi

echo "pi pane formatter output: ok"
