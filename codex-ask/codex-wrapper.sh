#!/bin/bash
# Codex CLI wrapper for codex-ask skill
#
# Provides a simplified interface to Codex CLI for the deliberation protocol.
# Handles session creation, resumption, and response extraction.
#
# Usage:
#   codex-wrapper.sh new "prompt" [reasoning_effort]
#   codex-wrapper.sh resume SESSION_ID "prompt" [reasoning_effort]
#
# Arguments:
#   new              Start a new Codex session
#   resume           Continue an existing session
#   prompt           The question or follow-up to send to Codex
#   reasoning_effort Optional: "high" (default) or "xhigh" for complex tasks
#
# Output:
#   new:    Two lines - session_id on first line, response on subsequent lines
#   resume: Response only (session_id already known)
#
# Exit codes:
#   0  Success
#   1  Error (message printed to stderr with "ERROR:" prefix)
#
# Dependencies:
#   - codex CLI installed and authenticated
#   - bash 3.0+ (uses here-strings)
#
# Compatibility:
#   Linux and macOS (POSIX-compliant sed/awk, standard bash)

set -euo pipefail

# Model configuration - change here to use a different model
MODEL="gpt-5.2"

# Print error message to stderr and exit
die() { echo "ERROR: $*" >&2; exit 1; }

# Run a command, capture output, and die on failure
# Args: label (for error context), command and args
run_or_die() {
    local label=$1; shift
    local out
    out=$("$@" 2>&1) || die "$label: $out"
    # Check for Codex error responses that don't set exit code
    [[ $out == Error:* ]] && die "$out"
    printf '%s' "$out"
}

# Extract session id from Codex CLI plain text header
# Expects line format: "session id: <UUID>"
extract_session_id() {
    sed -n 's/^session id: //p'
}

# Extract response body from Codex CLI output
# Response is between "codex" marker and "tokens used" footer
extract_response() {
    awk '/^codex$/{found=1; next} /^tokens used$/{found=0} found{print}'
}

# Start a new Codex session
# Args: prompt, reasoning_effort (optional, defaults to "high")
# Output: session_id on first line, response on subsequent lines
codex_new() {
    local prompt=$1 effort=${2:-high}
    local out session_id response

    out=$(run_or_die "codex" codex e \
        --sandbox read-only \
        --skip-git-repo-check \
        -c "model=\"$MODEL\"" \
        -c "model_reasoning_effort=\"$effort\"" \
        -c 'model_reasoning_summary="none"' \
        -c 'hide_agent_reasoning=true' \
        -c 'model_verbosity="low"' \
        - <<<"$prompt")

    session_id=$(extract_session_id <<<"$out")
    [[ -n $session_id ]] || die "no session_id in output"

    response=$(extract_response <<<"$out")
    [[ -n $response ]] || die "no response in output"

    echo "$session_id"
    echo "$response"
}

# Resume an existing Codex session
# Args: session_id, prompt, reasoning_effort (optional, defaults to "high")
# Output: response only
codex_resume() {
    local session_id=$1 prompt=$2 effort=${3:-high}
    local out response

    out=$(run_or_die "codex resume" codex e \
        --sandbox read-only \
        --skip-git-repo-check \
        -c "model=\"$MODEL\"" \
        -c "model_reasoning_effort=\"$effort\"" \
        -c 'model_reasoning_summary="none"' \
        -c 'hide_agent_reasoning=true' \
        -c 'model_verbosity="low"' \
        resume "$session_id" \
        - <<<"$prompt")

    response=$(extract_response <<<"$out")
    # Fall back to raw output if extraction fails (e.g., error messages)
    if [[ -n $response ]]; then
        echo "$response"
    else
        echo "$out"
    fi
}

# Main dispatch
case "${1:-}" in
    new)    shift; codex_new "$@" ;;
    resume) shift; codex_resume "$@" ;;
    *)      echo "Usage: $0 {new|resume} ..." >&2; exit 1 ;;
esac
