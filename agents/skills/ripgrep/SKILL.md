---
name: ripgrep
description: "Search for content in the codebase using the `rg` (ripgrep) tool."
---

# ripgrep Skill

Use `ripgrep` (`rg`) to search for text or patterns within files. It is highly optimized and respects `.gitignore` by default.

## Basic Search

Find a literal string:
```bash
rg -F "search_term"
```

Find a pattern using regular expressions:
```bash
rg "pattern_regex"
```

Search in a specific file or directory (defaults to current directory):
```bash
rg "query" path/to/file
```

## Filtering

**By File Type:**
Use `--type` (`-t`) to limit search to specific types (e.g., `rust`, `python`, `json`, `html`).
```bash
rg "search_term" -t rust
```

**By Glob Pattern:**
Use `-g` to include/exclude files based on patterns:
```bash
# Only search in .js and .ts files
rg "query" -g "*.{js,ts}"

# Exclude a specific directory manually
rg "query" --glob "!node_modules/*"
```

## Advanced Output

**Only show matches:**
Use `-o` to only output the matching part of the line.
```bash
rg -o "pattern"
```

**Replace text in output:**
Use `--replace` (or `-r`) to replace the matched portion with a different string.
```bash
rg "old_term" --replace "new_term"
# or
rg "old_term" -r "new_term"
```

## Handling Binary and Hidden Files

By default, `rg` hides binary files and hidden files. To include them:
- Include hidden files: `-u` (or `--hidden`)
- Include binary files: `-a` (or `--text`)
- More intensive search (ignores all defaults): `-uu` or `-uuu`

```bash
# Search including hidden files
rg --hidden "query"

# Force search in everything even if it's a binary file
rg -a "query"
```
