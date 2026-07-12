#!/usr/bin/env bash

# Verify that the installer uses the same explicit shell-script suffix as
# bootstrap.sh.
set -euo pipefail

repo_root=$(cd "$(dirname "$0")/.." && pwd)

test -x "$repo_root/setup.sh"
test ! -e "$repo_root/setup"
