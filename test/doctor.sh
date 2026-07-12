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

[ "$status" -eq 1 ] || fail "expected a missing manifest to exit 1, got $status"
printf '%s\n' "$output" | grep -q "Config linked correctly" || fail "missing config section"
printf '%s\n' "$output" | grep -q "Linked-files manifest" || fail "missing manifest check"
printf '%s\n' "$output" | grep -q "run ./bootstrap.sh" || fail "missing bootstrap fix hint"
printf '%s\n' "$output" | grep -q "Summary" || fail "missing summary"

fake_bin="$TMPDIR_ROOT/bin"
healthy_home="$TMPDIR_ROOT/healthy-home"
mkdir -p "$fake_bin" "$healthy_home/.claude/hooks" "$healthy_home/.pi/agent"
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
for command_name in nvim tmux zsh git fzf rg fd bat eza btm starship zoxide uv fnm gpg diff-so-fancy node npm markdownlint cargo rustc python3 ruff ty pip reattach-to-user-namespace brew; do
    ln -s tool "$fake_bin/$command_name"
done

ln -s "$ROOT/.gitmessage" "$healthy_home/.gitmessage"
echo "$healthy_home/.gitmessage" > "$healthy_home/.dotfiles_linked_files"
ln -s "$ROOT/.claude/CLAUDE.md" "$healthy_home/.claude/CLAUDE.md"
ln -s "$ROOT/.claude/CLAUDE.md" "$healthy_home/.pi/agent/CLAUDE.md"
for hook in "$ROOT"/.claude/hooks/*.sh; do
    ln -s "$hook" "$healthy_home/.claude/hooks/$(basename "$hook")"
done
echo '{}' > "$healthy_home/.claude/settings.json"

env_path="$fake_bin:/usr/bin:/bin"
set +e
output=$(HOME="$healthy_home" PATH="$env_path" SHELL=/bin/zsh EDITOR=nvim "$ROOT/doctor.sh" --ci 2>&1)
status=$?
set -e
[ "$status" -eq 0 ] || fail "expected a healthy CI setup to exit 0, got $status: $output"
printf '%s\n' "$output" | grep -q "0 FAIL" || fail "healthy summary contains failures"

set +e
HOME="$healthy_home" PATH="$env_path" SHELL=/bin/zsh EDITOR=nvim "$ROOT/doctor.sh" --ci --strict >/dev/null 2>&1
status=$?
set -e
[ "$status" -eq 1 ] || fail "expected --strict to reject optional dependency warnings"

grep -q './doctor.sh --ci' "$ROOT/test/run.sh" || fail "Debian verification does not run doctor"
grep -q './doctor.sh --ci' "$ROOT/.github/workflows/test-setup.yml" || fail "macOS verification does not run doctor"
if grep -q 'fnm use lts-latest' "$ROOT/.github/workflows/test-setup.yml"; then
    fail "macOS verification activates an fnm version that setup.sh does not install"
fi

echo "doctor tests passed"
