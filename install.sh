#!/bin/sh
set -eu

SRC_DIR="$(cd "$(dirname "$0")" && pwd)/swift-fundamentals"
CODEX_DEST="${HOME}/.agents/skills/swift-fundamentals"

mkdir -p "$(dirname "$CODEX_DEST")"
rm -rf "$CODEX_DEST"
cp -R "$SRC_DIR" "$CODEX_DEST"

echo "Installed swift-fundamentals to $CODEX_DEST"
