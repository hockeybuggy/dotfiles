#!/usr/bin/env python3
"""Merge this repo's tracked agy defaults into agy's personal settings file.

agy reads exactly one settings file, ~/.gemini/antigravity-cli/settings.json,
with no project-level or .local layer to override it. It also rewrites that
file itself (temp file plus rename) whenever a setting or permission changes,
so a symlink into this repo would be replaced by a regular file the first time
agy saved. Merging on bootstrap is the only way to track any of it.

The merge is deliberately one-directional and additive. Tracked defaults fill
in what is missing; anything already in the personal file wins, because agy or
the user put it there deliberately. Nothing is ever removed, so machine-local
keys such as trustedWorkspaces survive untouched.

Usage:
  merge-agy-settings.py <defaults.json> <target.json> [--allow-rule RULE ...]
"""

import argparse
import json
import os
import sys


def merge(defaults, target, allow_rules):
    """Merge defaults into target in place. Target values always win."""
    for key, value in defaults.items():
        if key == "permissions":
            continue
        target.setdefault(key, value)

    # Only 'allow' is merged; a 'deny' list (or anything else agy grows under
    # permissions) belongs to the personal file alone.
    wanted = list(defaults.get("permissions", {}).get("allow", []))
    wanted += allow_rules
    if not wanted:
        return target

    allow = target.setdefault("permissions", {}).setdefault("allow", [])
    for rule in wanted:
        if rule not in allow:
            allow.append(rule)
    return target


def load(path, what):
    if not os.path.exists(path):
        return {}
    try:
        with open(path) as handle:
            return json.load(handle)
    except (OSError, ValueError) as err:
        # Never overwrite a file we could not parse -- it is the user's only
        # copy of these settings.
        sys.exit(f"merge-agy-settings: cannot read {what} {path}: {err}")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("defaults", help="tracked defaults to merge in")
    parser.add_argument("target", help="agy's personal settings file")
    parser.add_argument(
        "--allow-rule",
        action="append",
        default=[],
        metavar="RULE",
        help="extra permissions.allow entry to ensure is present (repeatable)",
    )
    args = parser.parse_args()

    defaults = load(args.defaults, "defaults")
    target = load(args.target, "settings")
    merged = merge(defaults, target, args.allow_rule)

    os.makedirs(os.path.dirname(os.path.abspath(args.target)), exist_ok=True)
    with open(args.target, "w") as handle:
        json.dump(merged, handle, indent=2)
        handle.write("\n")


if __name__ == "__main__":
    main()
