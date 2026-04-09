#!/usr/bin/env bash
# co-vault installer
# Usage: ./install.sh [vault-path]
#   Default vault path: $HOME/Vaults/default

set -euo pipefail

VAULT_PATH="${1:-$HOME/Vaults/default}"
SKILL_DIR="$HOME/.claude/skills/co-vault"
REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
SKELETON="$REPO_DIR/examples/vault-skeleton"

if [ ! -d "$SKELETON" ]; then
  echo "ERROR: vault skeleton not found at $SKELETON"
  echo "Did you clone the full co-vault repo?"
  exit 1
fi

echo "==> Installing co-vault skill to $SKILL_DIR"
mkdir -p "$SKILL_DIR"
cp "$REPO_DIR/SKILL.md" "$SKILL_DIR/SKILL.md"

if [ -d "$VAULT_PATH/.covault" ]; then
  echo "==> Vault already initialized at $VAULT_PATH (skipping skeleton copy)"
else
  echo "==> Copying vault skeleton to $VAULT_PATH"
  mkdir -p "$VAULT_PATH"
  # Copy everything including dotfiles
  cp -r "$SKELETON/." "$VAULT_PATH/"
  # Set the vault name in the manifest
  PROJECT_NAME=$(basename "$VAULT_PATH")
  sed -i.bak "s|<set during bootstrap>|$PROJECT_NAME|" "$VAULT_PATH/.covault/manifest.yaml"
  rm -f "$VAULT_PATH/.covault/manifest.yaml.bak"
  echo "==> Vault skeleton installed. Schemas live in .covault/schemas/"
fi

if [ ! -d "$VAULT_PATH/.git" ]; then
  (cd "$VAULT_PATH" && git init -q && git add . && git commit -q -m "co-vault: bootstrap")
  echo "==> Initialized git repo in vault."
fi

echo
echo "Done."
echo
echo "Next steps:"
echo "  1. export COVAULT_PATH=\"$VAULT_PATH\""
echo "     (add to ~/.zshrc or ~/.bashrc)"
echo "  2. Edit $VAULT_PATH/index.md to fill in your project."
echo "  3. (Optional) Install the pre-commit hook for hard enforcement:"
echo "       cp $REPO_DIR/examples/pre-commit-hook.sh $VAULT_PATH/.git/hooks/pre-commit"
echo "       chmod +x $VAULT_PATH/.git/hooks/pre-commit"
echo "  4. Start Claude Code (or your agent of choice) in your project."
