# pretty.jq — turn pi's --mode json event stream into a readable live
# view for the tmux pane. Best-effort only: the full-fidelity record is
# the raw .jsonl log (captured upstream via tee), which the agent parses.
#
# Only assistant streaming events carry human-readable text. Everything
# else (session/turn/agent lifecycle events) is silently dropped so the
# pane shows prose, not plumbing. Field accesses are defensive so a
# schema tweak in pi degrades to "less shown", never a jq crash.
(.assistantMessageEvent // empty) as $e
| if   ($e.type == "text_delta")                              then ($e.delta // "")
  elif (($e.type // "") | test("(reasoning|thinking)_delta")) then ($e.delta // "")
  elif (($e.type // "") | test("^tool"))                      then ("\n> " + ($e.name // $e.toolName // "tool") + "\n")
  else empty end
