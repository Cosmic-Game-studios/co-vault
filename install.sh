#!/usr/bin/env bash
# co-vault installer
# Usage: ./install.sh [vault-path]
#   Default vault path: $HOME/Vaults/default

set -euo pipefail

VAULT_PATH="${1:-$HOME/Vaults/default}"
SKILL_DIR="$HOME/.claude/skills/co-vault"

echo "==> Installing co-vault skill to $SKILL_DIR"
mkdir -p "$SKILL_DIR"
cp "$(dirname "$0")/SKILL.md" "$SKILL_DIR/SKILL.md"

echo "==> Creating vault at $VAULT_PATH"
mkdir -p "$VAULT_PATH"/{domains,decisions,facts,proposals,reports,conflicts,_archive}

if [ ! -f "$VAULT_PATH/index.md" ]; then
  cp "$(dirname "$0")/examples/index.template.md" "$VAULT_PATH/index.md"
  echo "==> Created starter index.md — edit it to fill in your project."
fi

if [ ! -d "$VAULT_PATH/.git" ]; then
  (cd "$VAULT_PATH" && git init -q && git add . && git commit -q -m "co-vault: bootstrap")
  echo "==> Initialized git repo in vault."
fi

echo
echo "Done. Add this to your shell rc:"
echo
echo "    export COVAULT_PATH=\"$VAULT_PATH\""
echo
echo "Then start Claude Code and the skill will activate."
