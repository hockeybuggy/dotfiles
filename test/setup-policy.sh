#!/usr/bin/env bash

# Verify that both platforms use the shared tool installation paths and that CI
# runs with the current JavaScript action runtime and minimal permissions.
set -euo pipefail

repo_root=$(cd "$(dirname "$0")/.." && pwd)
setup="$repo_root/setup.sh"
workflow="$repo_root/.github/workflows/test-setup.yml"
brew_formulae=$(awk '
    /^[[:space:]]*brew install \\$/ { found=1 }
    found { print }
    found && ! /\\$/ { exit }
' "$setup")

grep -q 'setup_node_tools' "$setup"
grep -q 'rustup update stable' "$setup"
grep -q 'install_release_binary "bat"' "$setup"
grep -q 'install_release_binary "ripgrep"' "$setup"
grep -q 'arch_ripgrep' "$setup"
grep -q 'install_release_binary "fd"' "$setup"
grep -q 'install_release_binary "fzf"' "$setup"
if grep -Eq '(^|[[:space:]])node([[:space:]\\]|$)' <<<"$brew_formulae"; then
    echo "node must be installed through fnm, not Homebrew" >&2
    exit 1
fi
if grep -Eq '(^|[[:space:]])markdownlint-cli([[:space:]\\]|$)' <<<"$brew_formulae"; then
    echo "markdownlint-cli must be installed through npm, not Homebrew" >&2
    exit 1
fi
grep -q 'actions/checkout@v5' "$workflow"
grep -q 'contents: read' "$workflow"
