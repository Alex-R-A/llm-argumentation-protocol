#!/bin/bash
# Deploy skill files from kimi-ask to local repo

set -euo pipefail

SRC_DIR="$HOME/.claude/skills/kimi-ask"
DEST_DIR="$HOME/code/codex/kimi-ask"

mkdir -p "$DEST_DIR"

cp "$SRC_DIR/SKILL.md" "$DEST_DIR/"
cp "$SRC_DIR/kimi-wrapper.sh" "$DEST_DIR/"
cp "$SRC_DIR/OUTPUT-FORMAT.md" "$DEST_DIR/"

echo "Copied to $DEST_DIR:"
