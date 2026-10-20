#!/bin/sh
# SPDX-License-Identifier: MPL-2.0
set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/opencode"
SKILL_ID="chinese-first"
SKILL_DIR="$CONFIG_DIR/skills/$SKILL_ID"
SOURCE="$SCRIPT_DIR/SKILL.md"

if [ ! -f "$SOURCE" ]; then
  echo "SKILL.md was not found next to this script: $SOURCE" >&2
  exit 1
fi

mkdir -p "$SKILL_DIR"
cp "$SOURCE" "$SKILL_DIR/SKILL.md"
echo "Installed skill to $SKILL_DIR"

case "$SKILL_DIR/SKILL.md" in
  "$HOME"/*)
    REL=${SKILL_DIR#"$HOME"/}
    INSTRUCTION_PATH="~/$REL/SKILL.md"
    ;;
  *)
    INSTRUCTION_PATH="$SKILL_DIR/SKILL.md"
    ;;
esac

CONFIG="$CONFIG_DIR/opencode.jsonc"
if [ ! -f "$CONFIG" ] && [ -f "$CONFIG_DIR/opencode.json" ]; then
  CONFIG="$CONFIG_DIR/opencode.json"
fi

if [ ! -f "$CONFIG" ]; then
  mkdir -p "$CONFIG_DIR"
  cat > "$CONFIG" <<EOF
{
  "\$schema": "https://opencode.ai/config.json",
  "instructions": [
    "$INSTRUCTION_PATH"
  ]
}
EOF
  echo "Created $CONFIG with the default language instruction."
  echo "Restart OpenCode or run: opencode reload"
  exit 0
fi

if grep -q 'chinese-first' "$CONFIG"; then
  echo "Config already references chinese-first: $CONFIG"
  echo "Restart OpenCode or run: opencode reload"
  exit 0
fi

if grep -Eq '^[[:space:]]*"instructions"[[:space:]]*:' "$CONFIG"; then
  echo "Config already has an instructions array. Add this path manually:"
  echo "  $INSTRUCTION_PATH"
  echo "File: $CONFIG"
  exit 2
fi

BACKUP="$CONFIG.bak-$(date +%Y%m%d-%H%M%S)"
cp "$CONFIG" "$BACKUP"

SNIPPET=$(mktemp)
TMP=$(mktemp)
trap 'rm -f "$SNIPPET" "$TMP"' EXIT

cat > "$SNIPPET" <<EOF
  "instructions": [
    "$INSTRUCTION_PATH"
  ],
EOF

awk -v snippet="$SNIPPET" '
  { print }
  !done && index($0, "{") {
    while ((getline line < snippet) > 0) print line
    close(snippet)
    done = 1
  }
' "$CONFIG" > "$TMP"

mv "$TMP" "$CONFIG"
echo "Backed up config to $BACKUP"
echo "Added the instructions entry to $CONFIG"
echo "Restart OpenCode or run: opencode reload"
