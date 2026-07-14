---
name: live-preview
description: "Launch a project's local dev server and drive it in a visible (headed) playwright-cli browser so the user can watch and interact alongside the agent. Use when asked to preview the site/app locally, open the page in a real browser, give UI/design feedback, or interactively click through a running dev build."
---

# Live preview

Serve a project locally and open it in a **headed** playwright-cli session the
user can see and click in, while the agent inspects and drives the same page.

Builds on the `playwright-cli` skill — read that for the full command set. This
skill is the recipe and the gotchas that make interactive local preview work.

## The three gotchas (why naive attempts fail)

1. **`playwright-cli open` is headless by default.** Without `--headed` the
   browser is invisible and the user can't interact. Always pass `--headed`.
2. **The dev server may already be running.** Starting a second one fails with
   `EADDRINUSE`. If the expected port is already bound, assume the dev server
   is up and skip starting it.

3. **`open` must come before `show`/`snapshot`/`click`.** Use a **named**
   session so the browser persists across turns.

## Step 1 — Find the dev command and port

Inspect the project to determine how it serves locally and on which port.
Common sources:

- `package.json` scripts: `dev`, `start`, `serve` (Vite → 5173, Next → 3000,
  CRA → 3000, Astro → 4321).
- `Makefile` / `Procfile` / `docker-compose.yml` targets.
- A custom server file (e.g. `dev_server.js`) — grep it for the port.

Set these for the snippets below:

```bash
PORT=5173                      # the port the dev server listens on
DEV_CMD="npm run dev"          # the command that starts it
URL="http://localhost:$PORT/"
# Name the session after the project so parallel previews don't collide.
# Prefer the git repo name, fall back to the current directory name.
SESSION=$(basename "$(git rev-parse --show-toplevel 2>/dev/null || pwd)")
```

## Step 2 — Start (idempotent) and open headed

```bash
# If the expected port is already bound, assume the dev server is running and
# leave it alone. Only start one when the port is free.
if lsof -ti:"$PORT" >/dev/null 2>&1; then
  echo "Port $PORT already bound — assuming the dev server is running."
else
  $DEV_CMD >/tmp/live-preview.log 2>&1 &
  # Wait until the freshly started server answers (first build can take a bit)
  until curl -sf -o /dev/null "$URL"; do sleep 1; done
fi

# Open a visible browser pointed at the local app
playwright-cli -s="$SESSION" open "$URL" --headed
```

If the session is already open but headless, reopen it headed:

```bash
playwright-cli -s="$SESSION" close
playwright-cli -s="$SESSION" open "$URL" --headed
```

Confirm with `playwright-cli list` — the session should show `headed: true`.

## Step 3 — Interact

```bash
playwright-cli -s="$SESSION" snapshot          # inspect the page (get refs)
playwright-cli -s="$SESSION" click e15         # act on a ref from the snapshot
playwright-cli -s="$SESSION" reload            # refresh after an edit
```

For UI/design review, hand control to the user — they draw boxes and type
notes, and you receive the annotated screenshot, region snapshot, and comments:

```bash
playwright-cli -s="$SESSION" show --annotate
```

## Step 4 — Edit-and-refresh loop

If the dev server has live reload, the headed window updates itself after edits.
Otherwise force it:

```bash
playwright-cli -s="$SESSION" reload
```

## Step 5 — Cleanup

```bash
playwright-cli -s="$SESSION" close   # close just this browser
kill "$(lsof -ti:"$PORT")"           # stop the dev server on that port (if you started it)
```

## Troubleshooting

- `EADDRINUSE` — the dev server is already up; skip starting it (the
  port-bound check handles this).
- `The browser '<session>' is not open` — run `open` first.
- Invisible window / `headed: false` in `playwright-cli list` — you opened
  headless; close and reopen with `--headed`.
- Stale/zombie browsers — `playwright-cli close-all` or `playwright-cli kill-all`.
