#!/bin/bash
# Deploy all skill files from ~/.claude/skills to local repo

set -euo pipefail

DIR="$(cd "$(dirname "$0")" && pwd)"

"$DIR/copy_codex.sh"
"$DIR/claude_copy.sh"
"$DIR/gemini_copy.sh"
"$DIR/kimi_copy.sh"
"$DIR/roundrobin_copy.sh"

echo "All skills copied."
