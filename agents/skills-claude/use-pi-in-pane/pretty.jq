# pretty.jq — turn pi's --mode json event stream into a readable live
# view for the tmux pane. Best-effort only: the full-fidelity record is
# the raw .jsonl log (captured upstream via tee), which the agent parses.
#
# Assistant deltas carry prose and reasoning. Tool execution events carry
# the completed tool name and arguments; the earlier toolcall_* deltas are
# deliberately ignored because they contain partial JSON and would print a
# marker for every streamed token.
def clean:
  tostring
  | gsub("[[:space:]]+"; " ")
  | sub("^ +"; "")
  | sub(" +$"; "");

def clip:
  clean
  | if length > 180 then .[0:179] + "…" else . end;

def argument_detail:
  (.args // {}) as $args
  | if (($args.command? | type) == "string") then
      $args.command | clip
    elif (($args.path? | type) == "string") then
      ([if $args.offset? != null then "offset \($args.offset)" else empty end,
        if $args.limit? != null then "limit \($args.limit)" else empty end]
       | join(", ")) as $range
      | ($args.path | clip) + (if $range == "" then "" else " (\($range))" end)
    elif (($args.query? | type) == "string") then
      $args.query | clip
    elif (($args.queries? | type) == "array") then
      $args.queries | join("; ") | clip
    elif (($args.url? | type) == "string") then
      $args.url | clip
    elif (($args.urls? | type) == "array") then
      $args.urls | join(", ") | clip
    elif $args == {} then
      ""
    else
      $args | tojson | clip
    end;

def error_detail:
  [(.result.content? // [])[]? | select(.type == "text") | .text]
  | join(" ")
  | clip;

def tool_line($marker; $name; $detail):
  $marker + " " + ($name // "tool")
  + (if $detail == "" then "" else "  " + $detail end)
  + "\n";

(.assistantMessageEvent // {}) as $event
| if .type == "tool_execution_start" then
    tool_line("▸"; .toolName; argument_detail)
  elif .type == "tool_execution_end" and .isError == true then
    tool_line("✗"; .toolName; error_detail)
  elif $event.type == "text_delta" then
    ($event.delta // "")
  elif (($event.type // "") | test("(reasoning|thinking)_delta")) then
    ($event.delta // "")
  else
    empty
  end
