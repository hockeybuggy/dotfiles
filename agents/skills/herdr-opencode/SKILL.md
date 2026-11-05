---
name: herdr-opencode
description: "Drive an OpenCode agent running in another herdr pane: interrupt or stop it, answer its permission prompts, prompt it, read its answer, and resume it if it exits. Use whenever `herdr agent list` or `herdr agent get` reports `agent: opencode` for the pane you're about to touch, or when the user asks to stop, interrupt, cancel, unblock or check on an OpenCode agent. Read alongside the `herdr` skill, which covers finding panes and the general `herdr agent` commands."
---

# Driving OpenCode agents in herdr

The `herdr` skill covers finding a pane and the generic `herdr agent`
commands. This skill covers what is specific to OpenCode's TUI (tested on
OpenCode 2.2 and herdr 0.9.5). Check the pane really is OpenCode first:

```zsh
herdr agent get "$pane"   # .result.agent.agent == "opencode"
```

herdr also reports the OpenCode session id at `.result.agent.agent_session.value`
(`ses_…`). That id is what the `opencode api` fallbacks below need.

## Interrupting a running turn: `esc` twice

One `esc` does not stop OpenCode. It only arms the interrupt: the status
line changes from `esc interrupt` to `esc again to interrupt`, and the arm
expires after a few seconds. Send both presses in one call:

```zsh
herdr agent send-keys "$pane" esc esc
herdr agent get "$pane"   # agent_status should now be done or idle
```

Interrupting also kills the shell commands the turn started.

If the status is still `working`, read the screen. The TUI may be on a dialog
or on a different session tab. Interrupt through the API instead, which
doesn't depend on what the screen shows:

```zsh
sid="$(herdr agent get "$pane" \
  | python3 -c 'import json,sys; print(json.load(sys.stdin)["result"]["agent"]["agent_session"]["value"])')"
opencode api post "/api/session/$sid/interrupt"   # {"interrupted":true}
```

## Never send `ctrl+c` to stop it

In OpenCode, `ctrl+c` clears the prompt input, and with an empty input a
single `ctrl+c` **exits OpenCode** and drops the pane back to its shell. If
that happens by accident, resume the same session in the pane:

```zsh
herdr pane run "$pane" "opencode -s $sid"
```

Only exit OpenCode when the user asks for it.

## Permission prompts

When a tool needs approval, herdr reports the pane as `blocked`, and the
screen shows:

```
△ Permission required
$ <the command>
 Allow once   Always allow   Reject        ctrl+f fullscreen  ⇆ select  enter confirm
```

`herdr agent prompt` refuses with `agent_blocked` while it is up. As with any
blocked agent, ask the user before answering. Then:

| Answer | Keys |
| --- | --- |
| Allow once (highlighted by default) | `enter` |
| Always allow | `right enter` |
| Reject | `right right enter`, or `esc` |

`left` and `right` move the highlight; `tab` does not. Rejecting, whether by
`Reject` or `esc`, ends the whole turn rather than letting the agent try
something else, so the agent goes `done` and waits for a new prompt.

## Prompting

`herdr agent prompt "$pane" '…' --wait --timeout <ms>` works as described in
the `herdr` skill. `--timeout` is rejected without `--wait`. Slash commands
such as `/compact` or `/new` go through `agent prompt` too, but only send them
when the user asks.

## Reading its answer

`herdr agent read "$pane" --source visible` shows the transcript while it
fits on screen. When the answer has scrolled off or the screen looks blank,
read the session's messages from the API. They come back newest first:

```zsh
opencode api get "/api/session/$sid/message" | python3 -c '
import json,sys
for m in json.load(sys.stdin)["data"]:
    if m["type"] == "assistant":
        print("".join(c.get("text", "") for c in m.get("content", []) if c.get("type") == "text"))
        break'
```
