#!/bin/bash
# Codex CLI wrapper for codex-ask skill
# Usage:
#   codex-wrapper.sh new "prompt" [reasoning_effort]
#   codex-wrapper.sh resume SESSION_ID "prompt" [reasoning_effort]
#
# Output:
#   new: Two lines - session_id, then response
#   resume: Response only
#
# Model is hardcoded to gpt-5.2

set -euo pipefail

command -v jq >/dev/null || { echo "ERROR: 'jq' not found. Install jq (JSON processor): brew install jq / apt install jq" >&2; exit 1; }

MODEL="gpt-5.2"

die() { echo "ERROR: $*" >&2; exit 1; }

run_or_die() {
    local label=$1; shift
    local out
    out=$("$@" 2>&1) || die "$label: $out"
    [[ $out == Error:* ]] && die "$out"
    printf '%s' "$out"
}

# Extract last agent_message from JSON output
extract_response() {
    jq -rs '[.[] | select(.type=="item.completed" and .item.type=="agent_message")] | last | .item.text // empty'
}

codex_new() {
    local prompt=$1 effort=${2:-high}
    local out session_id response

    out=$(run_or_die "codex" codex e --json --full-auto --skip-git-repo-check -m "$MODEL" -c "model_reasoning_effort=\"$effort\"" "$prompt")

    session_id=$(jq -rs '[.[] | select(.type=="thread.started")] | first | .thread_id // empty' <<<"$out")
    [[ -n $session_id ]] || die "no session_id in output"

    response=$(extract_response <<<"$out")
    [[ -n $response ]] || die "no agent_message in output"

    echo "$session_id"
    echo "$response"
}

codex_resume() {
    local session_id=$1 prompt=$2 effort=${3:-high}
    local out response

    out=$(run_or_die "codex resume" codex e resume "$session_id" --json --skip-git-repo-check -c "model_reasoning_effort=\"$effort\"" "$prompt")

    response=$(extract_response <<<"$out")
    [[ -n $response ]] || die "no agent_message in output"

    echo "$response"
}

case "${1:-}" in
    new)    shift; codex_new "$@" ;;
    resume) shift; codex_resume "$@" ;;
    *)      echo "Usage: $0 {new|resume} ..." >&2; exit 1 ;;
esac
