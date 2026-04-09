#!/usr/bin/env bash
# validate-vault.sh — verify a co-vault is well-formed.
#
# Usage:
#   ./bin/validate-vault.sh <vault-path>
#
# Exit code 0 if the vault is valid, 1 if any check fails.
# Prints findings to stdout (errors) and stderr (warnings).
#
# Checks:
#   1. .covault/manifest.yaml exists and has supported schema_version
#   2. .covault/schemas/ contains all schema files referenced by manifest
#   3. .covault/examples/ contains an example for each note type
#   4. Every .md note (outside .covault, _archive, .git) has frontmatter
#   5. Every note's frontmatter has type + author fields
#   6. Author values are one of: user | agent | agent+reviewed
#   7. (person vault only) every note has a `summary:` field
#   8. (person vault only) _index.md exists

set -uo pipefail

SUPPORTED_SCHEMA_VERSION=1
ERRORS=0
WARNINGS=0

err() { echo "ERROR: $*"; ERRORS=$((ERRORS + 1)); }
warn() { echo "WARN:  $*" >&2; WARNINGS=$((WARNINGS + 1)); }
ok()  { echo "ok:    $*"; }

VAULT="${1:-}"
if [ -z "$VAULT" ]; then
  echo "Usage: $0 <vault-path>" >&2
  exit 2
fi
if [ ! -d "$VAULT" ]; then
  echo "ERROR: not a directory: $VAULT" >&2
  exit 2
fi

cd "$VAULT" || exit 2

# ---------- 1. Manifest ----------
MANIFEST=".covault/manifest.yaml"
if [ ! -f "$MANIFEST" ]; then
  err "missing $MANIFEST — vault is not initialized"
  exit 1
fi

SCHEMA_VERSION=$(grep -E '^schema_version:' "$MANIFEST" | awk '{print $2}')
if [ -z "$SCHEMA_VERSION" ]; then
  err "$MANIFEST has no schema_version field"
elif [ "$SCHEMA_VERSION" != "$SUPPORTED_SCHEMA_VERSION" ]; then
  err "$MANIFEST schema_version=$SCHEMA_VERSION (expected $SUPPORTED_SCHEMA_VERSION)"
else
  ok "manifest schema_version=$SCHEMA_VERSION"
fi

SCOPE=$(grep -E '^scope:' "$MANIFEST" | awk '{print $2}')
if [ -z "$SCOPE" ]; then
  warn "$MANIFEST has no scope field (assuming 'project')"
  SCOPE="project"
elif [ "$SCOPE" != "project" ] && [ "$SCOPE" != "person" ]; then
  err "$MANIFEST scope=$SCOPE (expected 'project' or 'person')"
fi
ok "vault scope: $SCOPE"

# ---------- 2. Schemas exist ----------
SCHEMA_DIR=".covault/schemas"
if [ ! -d "$SCHEMA_DIR" ]; then
  err "missing $SCHEMA_DIR"
else
  if [ "$SCOPE" = "project" ]; then
    REQUIRED_SCHEMAS="decision fact proposal report conflict domain index"
  else
    REQUIRED_SCHEMAS="identity preference pattern correction context index"
  fi
  for s in $REQUIRED_SCHEMAS; do
    if [ ! -f "$SCHEMA_DIR/$s.md" ]; then
      err "missing schema: $SCHEMA_DIR/$s.md"
    fi
  done
  ok "all required schemas present"
fi

# ---------- 3. Examples exist ----------
EXAMPLE_DIR=".covault/examples"
if [ ! -d "$EXAMPLE_DIR" ]; then
  warn "missing $EXAMPLE_DIR (recommended)"
else
  if [ "$SCOPE" = "project" ]; then
    REQUIRED_EXAMPLES="decision fact proposal report conflict domain"
  else
    REQUIRED_EXAMPLES="identity preference pattern correction context"
  fi
  for e in $REQUIRED_EXAMPLES; do
    if [ ! -f "$EXAMPLE_DIR/$e.md" ]; then
      warn "missing example: $EXAMPLE_DIR/$e.md"
    fi
  done
fi

# ---------- 4-7. Walk every content note ----------
NOTE_COUNT=0
NOTES_WITHOUT_FRONTMATTER=0
NOTES_WITHOUT_TYPE=0
NOTES_WITHOUT_AUTHOR=0
NOTES_WITH_BAD_AUTHOR=0
NOTES_WITHOUT_SUMMARY=0

VALID_AUTHORS="user agent agent+reviewed"

while IFS= read -r f; do
  NOTE_COUNT=$((NOTE_COUNT + 1))

  # Frontmatter must start at line 1 with ---
  if ! head -1 "$f" | grep -q '^---$'; then
    err "no frontmatter: $f"
    NOTES_WITHOUT_FRONTMATTER=$((NOTES_WITHOUT_FRONTMATTER + 1))
    continue
  fi

  # Extract frontmatter (between first two ---)
  FM=$(awk 'BEGIN{c=0} /^---$/{c++; if(c==2) exit; next} c==1{print}' "$f")

  # type field
  if ! echo "$FM" | grep -qE '^type:[[:space:]]*[a-z]+'; then
    err "missing 'type:' in frontmatter: $f"
    NOTES_WITHOUT_TYPE=$((NOTES_WITHOUT_TYPE + 1))
  fi

  # author field
  AUTHOR=$(echo "$FM" | grep -E '^author:' | head -1 | awk '{print $2}')
  if [ -z "$AUTHOR" ]; then
    err "missing 'author:' in frontmatter: $f"
    NOTES_WITHOUT_AUTHOR=$((NOTES_WITHOUT_AUTHOR + 1))
  else
    case " $VALID_AUTHORS " in
      *" $AUTHOR "*) ;;
      *)
        err "invalid author '$AUTHOR' in $f (must be: $VALID_AUTHORS)"
        NOTES_WITH_BAD_AUTHOR=$((NOTES_WITH_BAD_AUTHOR + 1))
        ;;
    esac
  fi

  # Person vault: summary required
  if [ "$SCOPE" = "person" ]; then
    if ! echo "$FM" | grep -qE '^summary:'; then
      err "missing 'summary:' in person vault note: $f"
      NOTES_WITHOUT_SUMMARY=$((NOTES_WITHOUT_SUMMARY + 1))
    fi
  fi
done < <(find . -type f -name '*.md' \
  -not -path './.covault/*' \
  -not -path './_archive/*' \
  -not -path './.git/*' \
  -not -name '_index.md')

ok "walked $NOTE_COUNT notes"

# ---------- 8. Person vault: _index.md must exist ----------
if [ "$SCOPE" = "person" ]; then
  if [ ! -f "_index.md" ]; then
    err "person vault missing _index.md (run bin/rebuild-index.sh)"
  else
    INDEX_LINES=$(wc -l < "_index.md")
    if [ "$INDEX_LINES" -gt 200 ]; then
      warn "_index.md is $INDEX_LINES lines (target: <200) — run REVIEW"
    else
      ok "_index.md is $INDEX_LINES lines"
    fi
  fi
fi

# ---------- Summary ----------
echo
echo "=========================================="
echo "Validation summary"
echo "  notes walked:            $NOTE_COUNT"
echo "  errors:                  $ERRORS"
echo "  warnings:                $WARNINGS"
echo "=========================================="

if [ "$ERRORS" -gt 0 ]; then
  exit 1
fi
exit 0
