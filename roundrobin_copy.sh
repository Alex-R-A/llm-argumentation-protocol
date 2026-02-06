#!/bin/bash
# Deploy skill files from round-robin-ask to local repo

set -euo pipefail

SRC_DIR="$HOME/.claude/skills/round-robin-ask"
DEST_DIR="$HOME/code/codex/round-robin-ask"

mkdir -p "$DEST_DIR"

cp "$SRC_DIR/SKILL.md" "$DEST_DIR/"

echo "Copied to $DEST_DIR:"
