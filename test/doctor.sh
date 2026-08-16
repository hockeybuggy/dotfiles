#!/usr/bin/env bash

set -uo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
TMPDIR_ROOT=$(mktemp -d)
trap 'rm -rf "$TMPDIR_ROOT"' EXIT

fail() {
    echo "FAIL: $*" >&2
    exit 1
}

home="$TMPDIR_ROOT/home"
mkdir -p "$home"

set +e
output=$(HOME="$home" "$ROOT/doctor.sh" --ci 2>&1)
status=$?
set -e

[ "$status" -eq 1 ] || fail "expected an unbootstrapped home to exit 1, got $status"
printf '%s\n' "$output" | grep -q "Install mode" || fail "missing install mode check"
printf '%s\n' "$output" | grep -q "bootstrap.sh --minimal" || fail "missing mode selection hint"
printf '%s\n' "$output" | grep -q "Linked-files manifest" || fail "missing manifest check"
printf '%s\n' "$output" | grep -q "Summary" || fail "missing summary"

fake_bin="$TMPDIR_ROOT/bin"
healthy_home="$TMPDIR_ROOT/healthy-home"
mkdir -p "$fake_bin" "$healthy_home/.claude/hooks" "$healthy_home/.pi/agent/extensions"
cat > "$fake_bin/tool" <<'EOF'
#!/bin/sh
name=${0##*/}
case "$name" in
    nvim) echo "NVIM v0.11.0" ;;
    tmux) echo "tmux 3.5" ;;
    zsh) [ "${1:-}" = "--version" ] && echo "zsh 5.9" ;;
    uv) case "$*" in *"python find"*) echo "3.14.0" ;; *) echo "uv 1.0" ;; esac ;;
    git)
        case "$*" in
            *user.name*) echo "Dot Files" ;;
            *user.email*) echo "dotfiles@example.com" ;;
            *commit.template*) echo "~/.gitmessage" ;;
            *core.pager*) echo "~/.dotfiles/.bin/git-pager.sh" ;;
        esac
        ;;
    brew) echo "uutils-coreutils 0.1" ;;
    *) echo "$name 1.0" ;;
esac
exit 0
EOF
chmod +x "$fake_bin/tool"

core_commands="nvim tmux zsh git fzf rg fd bat eza btm starship zoxide fnm node npm python3 pip"
development_commands="uv gpg diff-so-fancy markdownlint cargo rustc ruff ty pgcli claude pi agy"
for command_name in $core_commands; do
    ln -s tool "$fake_bin/$command_name"
done
if [ "$(uname -s)" = Darwin ]; then
    for command_name in reattach-to-user-namespace brew; do
        ln -s tool "$fake_bin/$command_name"
    done
fi

ln -s "$ROOT/.gitmessage" "$healthy_home/.gitmessage"
echo "$healthy_home/.gitmessage" > "$healthy_home/.dotfiles_linked_files"
ln -s "$ROOT/.claude/CLAUDE.md" "$healthy_home/.claude/CLAUDE.md"
mkdir -p "$healthy_home/.pi/agent" "$healthy_home/.gemini/config" "$healthy_home/.gemini/antigravity-cli"
ln -s "$ROOT/.claude/CLAUDE.md" "$healthy_home/.pi/agent/CLAUDE.md"
ln -s "$ROOT/.claude/CLAUDE.md" "$healthy_home/.gemini/config/GEMINI.md"
ln -s "$ROOT/agents/agy/hooks.json" "$healthy_home/.gemini/config/hooks.json"
ln -s "$ROOT/.config/mcp/mcp.json" "$healthy_home/.gemini/config/mcp_config.json"
python3 - "$healthy_home/.gemini/antigravity-cli/settings.json" "$ROOT" <<'PY'
import json
import sys
json.dump({"permissions": {"allow": [f"read_file({sys.argv[2]})"]}}, open(sys.argv[1], "w"))
PY

for extension in "$ROOT"/agents/extensions/*.ts; do
    ln -s "$extension" "$healthy_home/.pi/agent/extensions/$(basename "$extension")"
done
mkdir -p "$healthy_home/.pi/agent/scripts"
for hook in "$ROOT"/agents/hooks/*.sh; do
    ln -s "$hook" "$healthy_home/.claude/hooks/$(basename "$hook")"
    ln -s "$hook" "$healthy_home/.pi/agent/scripts/$(basename "$hook")"
done
echo '{}' > "$healthy_home/.claude/settings.json"
mkdir -p "$healthy_home/.claude/skills" "$healthy_home/.pi/agent/skills" "$healthy_home/.gemini/config/skills"
for skill_dir in "$ROOT"/agents/skills/*/ "$ROOT"/agents/skills-claude/*/; do
    [ -d "$skill_dir" ] || continue
    ln -s "$skill_dir" "$healthy_home/.claude/skills/$(basename "$skill_dir")"
done
for skill_dir in "$ROOT"/agents/skills/*/ "$ROOT"/agents/skills-pi/*/; do
    [ -d "$skill_dir" ] || continue
    ln -s "$skill_dir" "$healthy_home/.pi/agent/skills/$(basename "$skill_dir")"
done
for skill_dir in "$ROOT"/agents/skills/*/; do
    [ -d "$skill_dir" ] || continue
    ln -s "$skill_dir" "$healthy_home/.gemini/config/skills/$(basename "$skill_dir")"
done

env_path="$fake_bin:/usr/bin:/bin"
printf 'minimal\n' > "$healthy_home/.dotfiles_mode"
set +e
output=$(HOME="$healthy_home" PATH="$env_path" SHELL=/bin/zsh EDITOR=nvim "$ROOT/doctor.sh" --ci 2>&1)
status=$?
set -e
[ "$status" -eq 0 ] || fail "expected a healthy minimal setup to exit 0, got $status: $output"
printf '%s\n' "$output" | grep -q "Mode.*minimal" || fail "minimal mode is not displayed"
if printf '%s\n' "$output" | grep -Eq '✗[[:space:]]+(uv|Claude Code|cargo)'; then
    fail "minimal mode requires a development-only tool"
fi

printf 'work\n' > "$healthy_home/.dotfiles_mode"
set +e
output=$(HOME="$healthy_home" PATH="$env_path" SHELL=/bin/zsh EDITOR=nvim "$ROOT/doctor.sh" --ci 2>&1)
status=$?
set -e
[ "$status" -eq 1 ] || fail "work mode accepted a minimal tool set"
printf '%s\n' "$output" | grep -Eq '✗[[:space:]]+uv' || fail "work mode did not require uv"

for command_name in $development_commands; do
    ln -s tool "$fake_bin/$command_name"
done

output=$(HOME="$healthy_home" PATH="$env_path" SHELL=/bin/zsh EDITOR=nvim "$ROOT/doctor.sh" --ci 2>&1)
status=$?
[ "$status" -eq 0 ] || fail "expected a healthy work setup to exit 0, got $status: $output"
printf '%s\n' "$output" | grep -q "0 FAIL" || fail "healthy summary contains failures"
printf '%s\n' "$output" | grep -Eq '^[[:space:]]+✓[[:space:]]+pgcli[[:space:]]' || fail "missing pgcli check"
printf '%s\n' "$output" | grep -q "Pi skills linked" || fail "missing Pi skills check"
printf '%s\n' "$output" | grep -q "Pi extensions linked" || fail "missing Pi extensions check"

printf 'invalid\n' > "$healthy_home/.dotfiles_mode"
set +e
output=$(HOME="$healthy_home" PATH="$env_path" SHELL=/bin/zsh EDITOR=nvim "$ROOT/doctor.sh" --ci 2>&1)
status=$?
set -e
[ "$status" -eq 1 ] || fail "invalid mode exited $status instead of 1"
printf '%s\n' "$output" | grep -qi "invalid" || fail "invalid mode lacks diagnostic"

grep -q './doctor.sh --ci' "$ROOT/test/run.sh" || fail "Debian verification does not run doctor"
grep -q './doctor.sh --ci' "$ROOT/.github/workflows/test-setup.yml" || fail "macOS verification does not run doctor"
if grep -q 'fnm use lts-latest' "$ROOT/.github/workflows/test-setup.yml"; then
    fail "macOS verification activates an fnm version that setup.sh does not install"
fi

echo "doctor tests passed"
