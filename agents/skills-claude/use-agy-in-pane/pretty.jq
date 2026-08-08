# pretty.jq — turn agy's --output-format stream-json event stream into a
# readable live view for the tmux pane. Best-effort only: the full-fidelity
# record is the raw .jsonl log (captured upstream via tee), which the agent
# parses.
#
# agent_response steps carry incremental text_delta chunks (both ACTIVE and
# the final DONE carry them, so print whenever one is present). Tool steps
# are only shown on ACTIVE (the start of the call) with a best-guess
# argument, mirroring pi's pretty.jq; the completed output can be long and
# noisy, so it's left to the raw log.
def clean:
  tostring
  | gsub("[[:space:]]+"; " ")
  | sub("^ +"; "")
  | sub(" +$"; "");

def clip:
  clean
  | if length > 180 then .[0:179] + "…" else . end;

def argument_detail:
  (.parameters // {}) as $p
  | ( $p.CommandLine? // $p.TargetFile? // $p.Path? // $p.Query? // $p.Url?
      // $p.Pattern? // $p.Message?
      // ([$p[]? | select(type == "string")] | .[0])
    ) as $val
  | if $val == null then ($p | tojson | clip) else ($val | clip) end;

def tool_line($marker; $name; $detail):
  $marker + " " + ($name // "tool")
  + (if $detail == "" then "" else "  " + $detail end)
  + "\n";

(.step_update // {}) as $su
| if .event == "step_update" and $su.step_type == "tool" and $su.state == "ACTIVE" then
    tool_line("▸"; $su.tool_name; ($su.tool_info // {} | argument_detail))
  elif .event == "step_update" and $su.step_type == "agent_response" and ($su.text_delta // "") != "" then
    $su.text_delta
  else
    empty
  end
