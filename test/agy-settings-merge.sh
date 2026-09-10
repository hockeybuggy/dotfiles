#!/usr/bin/env bash
#
# agy-settings-merge.sh -- prove lib/merge-agy-settings.py only ever adds to
# agy's personal settings file.
#
# The file being merged into is the user's only copy of these settings, and
# agy rewrites it behind our back, so the risks worth pinning down are all
# destructive ones: clobbering a local value, dropping a machine-local key,
# duplicating rules across repeated bootstrap runs, or overwriting a file we
# failed to parse.

set -euo pipefail

REPO_ROOT=$(cd "$(dirname "$0")/.." && pwd)
MERGE="$REPO_ROOT/lib/merge-agy-settings.py"

workdir=$(mktemp -d)
trap 'rm -rf "$workdir"' EXIT

defaults="$workdir/defaults.json"
target="$workdir/settings.json"

cat > "$defaults" <<'JSON'
{
  "colorScheme": "dark",
  "model": "Tracked Model",
  "permissions": {
    "allow": ["command(git status)", "command(gh)"]
  }
}
JSON

fail() {
    echo "agy settings merge: $1" >&2
    exit 1
}

# jq is not a dependency of this repo's shell scripts; python3 is.
field() {
    python3 -c "
import json, sys
print(json.load(open(sys.argv[1]))$2)
" "$target" "$1" 2>/dev/null
}

# --- a missing target is created from the defaults ------------------------
python3 "$MERGE" "$defaults" "$target"
[ -f "$target" ] || fail "no settings file was created"
[ "$(field '' "['model']")" = "Tracked Model" ] || fail "defaults were not written"

# --- local values win over tracked defaults -------------------------------
cat > "$target" <<'JSON'
{
  "colorScheme": "light",
  "model": "Locally Chosen Model",
  "permissions": {
    "allow": ["command(cargo test)"],
    "deny": ["command(rm)"]
  },
  "trustedWorkspaces": ["/home/someone/devel/thing"]
}
JSON
python3 "$MERGE" "$defaults" "$target" --allow-rule "read_file(/repo)"

[ "$(field '' "['model']")" = "Locally Chosen Model" ] \
    || fail "a tracked default overwrote a local value"
[ "$(field '' "['colorScheme']")" = "light" ] \
    || fail "a tracked default overwrote a local colour scheme"
[ "$(field '' "['trustedWorkspaces'][0]")" = "/home/someone/devel/thing" ] \
    || fail "a machine-local key was dropped"
[ "$(field '' "['permissions']['deny'][0]")" = "command(rm)" ] \
    || fail "a deny rule was dropped"

# The local rule keeps its position; tracked rules and the extra allow-rule
# are appended after it.
allow=$(field '' "['permissions']['allow']")
[ "$allow" = "['command(cargo test)', 'command(git status)', 'command(gh)', 'read_file(/repo)']" ] \
    || fail "unexpected allow list: $allow"

# --- re-running is idempotent, not cumulative -----------------------------
python3 "$MERGE" "$defaults" "$target" --allow-rule "read_file(/repo)"
python3 "$MERGE" "$defaults" "$target" --allow-rule "read_file(/repo)"
count=$(field '' "['permissions']['allow'].count('command(gh)')")
[ "$count" = "1" ] || fail "repeated runs duplicated an allow rule ($count copies)"

# --- an unparseable target is left alone ----------------------------------
printf 'not json at all\n' > "$target"
if python3 "$MERGE" "$defaults" "$target" 2>/dev/null; then
    fail "merging into an unparseable settings file should have failed"
fi
[ "$(cat "$target")" = "not json at all" ] \
    || fail "an unparseable settings file was overwritten"

# --- the tracked defaults this repo actually ships are valid --------------
python3 -c "
import json, sys
settings = json.load(open(sys.argv[1]))
allow = settings['permissions']['allow']
assert allow == sorted(set(allow), key=allow.index), 'duplicate allow rules'
assert 'trustedWorkspaces' not in settings, 'trustedWorkspaces must stay local'
for rule in allow:
    assert '/Users/' not in rule and '/home/' not in rule, \
        'tracked rule contains a home path: ' + rule
" "$REPO_ROOT/agents/agy/settings.json" || fail "agents/agy/settings.json is not portable"

echo "agy settings merge: ok"
