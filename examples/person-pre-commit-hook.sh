#!/usr/bin/env bash
# co-vault PERSON pre-commit hook
#
# Install in your PERSON vault (not this repo):
#   cp examples/person-pre-commit-hook.sh $COVAULT_PERSON/.git/hooks/pre-commit
#   chmod +x $COVAULT_PERSON/.git/hooks/pre-commit
#
# Rejects commits that:
#   1. Modify a file with `author: user` (unless commit message has [user-edit])
#   2. Modify a `corrections/` file (corrections are append-only learning)
#   3. Reduce the line count of identity/basic.md by more than 50% (suspect deletion)
#
# This is the hard enforcement layer for the person vault.

set -euo pipefail

# Get list of modified markdown files
modified=$(git diff --cached --name-only --diff-filter=M | grep '\.md$' || true)

if [ -z "$modified" ]; then
  exit 0
fi

# Allow if commit message has the explicit override
msg_file="${1:-.git/COMMIT_EDITMSG}"
if [ -f "$msg_file" ] && grep -q '\[user-edit\]' "$msg_file"; then
  exit 0
fi

violations=()
reasons=()

for f in $modified; do
  # Rule 1: author: user files are immutable to agents
  if git show "HEAD:$f" 2>/dev/null | head -20 | grep -qE '^author:[[:space:]]*user[[:space:]]*$'; then
    violations+=("$f")
    reasons+=("modifies author: user note")
    continue
  fi

  # Rule 2: corrections/ are append-only (you can add new ones, not modify)
  case "$f" in
    corrections/*)
      violations+=("$f")
      reasons+=("modifies existing correction (corrections are append-only)")
      continue
      ;;
  esac

  # Rule 3: identity/basic.md must not shrink dramatically
  if [ "$f" = "identity/basic.md" ]; then
    old_lines=$(git show "HEAD:$f" 2>/dev/null | wc -l)
    new_lines=$(wc -l < "$f")
    if [ "$old_lines" -gt 10 ] && [ "$new_lines" -lt $((old_lines / 2)) ]; then
      violations+=("$f")
      reasons+=("identity/basic.md shrunk from $old_lines to $new_lines lines (suspicious)")
    fi
  fi
done

if [ ${#violations[@]} -eq 0 ]; then
  exit 0
fi

echo "ERROR: co-vault person pre-commit hook"
echo
echo "The following changes are not allowed without explicit override:"
i=0
while [ $i -lt ${#violations[@]} ]; do
  echo "  - ${violations[$i]}: ${reasons[$i]}"
  i=$((i + 1))
done
echo
echo "If YOU (the human) are intentionally making these changes, add"
echo "[user-edit] to your commit message. If an agent is trying to"
echo "modify your corrections or overwrite your identity, this is the"
echo "hook stopping it from happening."
exit 1
