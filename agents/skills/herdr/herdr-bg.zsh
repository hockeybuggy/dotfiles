#!/usr/bin/env zsh
#
# herdr-bg.zsh -- run a command while marking this herdr pane as having
# background work, so the sidebar does not read as plain "idle" while an agent
# is only waiting for the command to finish.
#
# Usage: herdr-bg.zsh [--label TEXT] <command> [args...]

emulate -L zsh
setopt no_unset pipe_fail

SOURCE=agent:bg
TOKEN=bg
TTL_MS=3600000

label=
if [[ ${1:-} == --label ]]; then
    [[ -n ${2:-} ]] || { print -u2 'herdr-bg: --label needs a value'; exit 2; }
    label=$2
    shift 2
fi

(( $# )) || { print -u2 'herdr-bg: no command given'; exit 2; }

# Outside herdr, or with no pane to report against, stay a transparent wrapper.
if [[ -z ${HERDR_ENV:-} || -z ${HERDR_PANE_ID:-} ]]; then
    exec "$@"
fi

[[ -n $label ]] || label="$*"
if (( ${#label} > 40 )); then
    label="${label[1,39]}…"
fi

state_dir=${XDG_STATE_HOME:-$HOME/.local/state}/herdr-bg/${HERDR_PANE_ID//:/_}
mkdir -p $state_dir || exec "$@"

publish() {
    local -a live
    local f

    # Prune markers whose process is gone. A SIGKILLed job never runs its trap,
    # so the next invocation is what heals a marker it left behind.
    for f in $state_dir/*(N); do
        if kill -0 ${f:t} 2>/dev/null; then
            live+=("$(<$f)")
        else
            rm -f $f
        fi
    done

    if (( ${#live} == 0 )); then
        herdr pane report-metadata $HERDR_PANE_ID --source $SOURCE \
            --clear-token $TOKEN --clear-state-labels >/dev/null 2>&1
        return 0
    fi

    local summary=${live[1]}
    if (( ${#live} > 1 )); then
        summary="${#live} jobs · $summary"
    fi

    # Relabel idle, not working: idle is the state the pane lands in once the
    # agent's turn ends, which is the case that reads as nothing happening.
    herdr pane report-metadata $HERDR_PANE_ID --source $SOURCE \
        --token $TOKEN="$summary" \
        --state-label idle="waiting · $summary" \
        --ttl-ms $TTL_MS >/dev/null 2>&1
    return 0
}

print -r -- $label >$state_dir/$$
trap 'rm -f $state_dir/$$; publish' EXIT HUP INT TERM
publish

"$@"
exit $?
