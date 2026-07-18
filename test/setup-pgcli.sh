#!/usr/bin/env bash

set -euo pipefail

repo_root=$(cd "$(dirname "$0")/.." && pwd)

grep -Fq 'uv tool install --python 3.14 --with psycopg-binary pgcli' "$repo_root/setup.sh"
grep -Fq "\"\$REPO_ROOT/test/setup-pgcli.sh\"" "$repo_root/test/run.sh"
grep -Fq '"pgcli|pgcli --version"' "$repo_root/test/verify.sh"
