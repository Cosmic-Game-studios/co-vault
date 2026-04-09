#!/usr/bin/env bash
# co-vault pre-commit hook
#
# Install in your VAULT (not this repo):
#   cp examples/pre-commit-hook.sh $COVAULT_PATH/.git/hooks/pre-commit
#   chmod +x $COVAULT_PATH/.git/hooks/pre-commit
#
# It rejects any commit that modifies a file whose frontmatter says
# `author: user`, unless the commit message contains [user-edit].
# This is the hard enforcement layer underneath the soft skill rules.

set -euo pipefail

# Get list of modified (not added, not deleted) markdown files
modified=$(git diff --cached --name-only --diff-filter=M | grep '\.md$' || true)

if [ -z "$modified" ]; then
  exit 0
fi

violations=()
for f in $modified; do
  # Check if the OLD version (HEAD) had author: user
  if git show "HEAD:$f" 2>/dev/null | head -20 | grep -qE '^author:[[:space:]]*user[[:space:]]*$'; then
    violations+=("$f")
  fi
done

if [ ${#violations[@]} -eq 0 ]; then
  exit 0
fi

# Allow if commit message has the explicit override
msg_file="${1:-.git/COMMIT_EDITMSG}"
if [ -f "$msg_file" ] && grep -q '\[user-edit\]' "$msg_file"; then
  exit 0
fi

echo "ERROR: co-vault pre-commit hook"
echo
echo "The following files have 'author: user' and cannot be modified by an agent:"
for f in "${violations[@]}"; do
  echo "  - $f"
done
echo
echo "If YOU (the human) are intentionally editing these, add [user-edit]"
echo "to your commit message. If an agent is trying to override your"
echo "decisions, it should open a conflict note instead."
exit 1
