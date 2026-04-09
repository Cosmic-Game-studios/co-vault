#!/usr/bin/env bash
# co-vault installer
#
# Usage:
#   ./install.sh [vault-path]              # bootstrap a project vault
#   ./install.sh --person [vault-path]     # bootstrap a person vault
#
# Defaults:
#   project: $HOME/Vaults/default
#   person:  $HOME/.covault/person

set -euo pipefail

MODE="project"
if [ "${1:-}" = "--person" ]; then
  MODE="person"
  shift
fi

if [ "$MODE" = "project" ]; then
  VAULT_PATH="${1:-$HOME/Vaults/default}"
  SKELETON_NAME="vault-skeleton"
else
  VAULT_PATH="${1:-$HOME/.covault/person}"
  SKELETON_NAME="person-vault-skeleton"
fi

SKILL_DIR="$HOME/.claude/skills/co-vault"
REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
SKELETON="$REPO_DIR/examples/$SKELETON_NAME"

if [ ! -d "$SKELETON" ]; then
  echo "ERROR: skeleton not found at $SKELETON"
  echo "Did you clone the full co-vault repo?"
  exit 1
fi

# Install the skill (idempotent)
echo "==> Installing co-vault skill to $SKILL_DIR"
mkdir -p "$SKILL_DIR/bin"
cp "$REPO_DIR/SKILL.md" "$SKILL_DIR/SKILL.md"
cp "$REPO_DIR/bin/rebuild-index.sh" "$SKILL_DIR/bin/rebuild-index.sh"
cp "$REPO_DIR/bin/validate-vault.sh" "$SKILL_DIR/bin/validate-vault.sh"
cp "$REPO_DIR/bin/maintain-vault.sh" "$SKILL_DIR/bin/maintain-vault.sh"
chmod +x "$SKILL_DIR/bin/rebuild-index.sh"
chmod +x "$SKILL_DIR/bin/validate-vault.sh"
chmod +x "$SKILL_DIR/bin/maintain-vault.sh"

# Bootstrap the vault if it doesn't exist yet
if [ -d "$VAULT_PATH/.covault" ]; then
  echo "==> $MODE vault already initialized at $VAULT_PATH (skipping skeleton copy)"
else
  echo "==> Copying $MODE vault skeleton to $VAULT_PATH"
  mkdir -p "$VAULT_PATH"
  cp -r "$SKELETON/." "$VAULT_PATH/"
  PROJECT_NAME=$(basename "$VAULT_PATH")
  sed -i.bak "s|<set during bootstrap>|$PROJECT_NAME|" "$VAULT_PATH/.covault/manifest.yaml"
  rm -f "$VAULT_PATH/.covault/manifest.yaml.bak"
  echo "==> $MODE vault skeleton installed."
fi

# Init git in the vault
if [ ! -d "$VAULT_PATH/.git" ]; then
  (cd "$VAULT_PATH" && git init -q && git add . && git commit -q -m "co-vault: bootstrap ($MODE)")
  echo "==> Initialized git repo in vault."
fi

# Final instructions
echo
echo "Done."
echo
if [ "$MODE" = "project" ]; then
  cat <<INSTR
Next steps:
  1. export COVAULT_PATH="$VAULT_PATH"
     (add to ~/.zshrc or ~/.bashrc)
  2. Edit $VAULT_PATH/index.md to fill in your project.
  3. (Optional, hard enforcement) Install the pre-commit hook:
       cp $REPO_DIR/examples/pre-commit-hook.sh $VAULT_PATH/.git/hooks/pre-commit
       chmod +x $VAULT_PATH/.git/hooks/pre-commit
  4. Start Claude Code in your project. The skill activates automatically.
INSTR
else
  cat <<INSTR
Next steps:
  1. export COVAULT_PERSON="$VAULT_PATH"
     (add to ~/.zshrc or ~/.bashrc — this is ONE vault for ALL your projects)
  2. Edit $VAULT_PATH/identity/basic.md with your basic identity.
  3. Start Claude Code in any project. The agent will load the person vault
     on session start and learn about you over time.
  4. After every write, the index is auto-rebuilt by:
       $SKILL_DIR/bin/rebuild-index.sh "$VAULT_PATH"
INSTR
fi
