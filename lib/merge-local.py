#!/usr/bin/env python3
"""Write tracked settings combined with a machine-local overlay.

Used for agents that never rewrite their own config file (Claude Code's
settings.json, OpenCode's opencode.json), so the output can be regenerated
from scratch on every bootstrap. Nested objects are merged, lists are unioned
so tracked and local entries combine, and local scalars win.

Usage:
  merge-local.py <tracked.json> <local.json> <output.json>
"""

import json
import sys


def deep_merge(base, local):
    for key, value in local.items():
        if isinstance(value, dict) and isinstance(base.get(key), dict):
            deep_merge(base[key], value)
        elif isinstance(value, list) and isinstance(base.get(key), list):
            base[key] = base[key] + [v for v in value if v not in base[key]]
        else:
            base[key] = value
    return base


def main():
    if len(sys.argv) != 4:
        sys.exit(__doc__.strip())
    tracked_path, local_path, output_path = sys.argv[1:]
    with open(tracked_path) as handle:
        merged = json.load(handle)
    with open(local_path) as handle:
        deep_merge(merged, json.load(handle))
    with open(output_path, "w") as handle:
        json.dump(merged, handle, indent=2)
        handle.write("\n")


if __name__ == "__main__":
    main()
