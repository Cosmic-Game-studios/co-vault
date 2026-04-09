#!/usr/bin/env bash
# rebuild-index.sh — rebuild the _index.md of a co-vault person vault.
#
# Usage: ./bin/rebuild-index.sh [vault-path]
#   Default: $COVAULT_PERSON
#
# Walks every folder in the vault, extracts the `summary:` field from each
# note's frontmatter, and rewrites _index.md grouped by folder.
#
# Run this after every write to the person vault. It is fast (one find +
# one grep per file) and deterministic (no LLM judgment needed).

set -euo pipefail

VAULT="${1:-${COVAULT_PERSON:-}}"
if [ -z "$VAULT" ]; then
  echo "ERROR: no vault path. Set COVAULT_PERSON or pass as argument." >&2
  exit 1
fi
if [ ! -d "$VAULT" ]; then
  echo "ERROR: vault directory not found: $VAULT" >&2
  exit 1
fi
if [ ! -f "$VAULT/.covault/manifest.yaml" ]; then
  echo "ERROR: not a co-vault (no .covault/manifest.yaml): $VAULT" >&2
  exit 1
fi

cd "$VAULT"

TIMESTAMP=$(date -u +%Y-%m-%dT%H:%MZ)
TMP=$(mktemp)

# Header
cat > "$TMP" <<EOF
---
type: index
author: agent
generated: $TIMESTAMP
note_count: 0
---

# Person vault index

EOF

# Folders to index, in order
FOLDERS="identity preferences patterns corrections context"

NOTE_COUNT=0
for folder in $FOLDERS; do
  [ -d "$folder" ] || continue

  # Find all .md files in the folder, excluding .gitkeep and hidden files
  files=$(find "$folder" -maxdepth 1 -type f -name '*.md' 2>/dev/null | sort)
  [ -z "$files" ] && continue

  # Folder header
  echo "## $folder" >> "$TMP"

  for f in $files; do
    # Extract summary from frontmatter (between --- markers, max line 30)
    summary=$(awk '
      /^---$/ { in_fm = !in_fm; next }
      in_fm && /^summary:/ {
        sub(/^summary:[[:space:]]*/, "")
        gsub(/^"|"$/, "")
        print
        exit
      }
      NR > 30 { exit }
    ' "$f")

    # Use filename without extension as the wikilink target
    base=$(basename "$f" .md)
    wiki="$folder/$base"

    if [ -n "$summary" ]; then
      echo "- [[$wiki]] — $summary" >> "$TMP"
    else
      echo "- [[$wiki]] — *(missing summary in frontmatter)*" >> "$TMP"
    fi
    NOTE_COUNT=$((NOTE_COUNT + 1))
  done

  echo >> "$TMP"
done

# Update note_count in header
sed -i.bak "s/^note_count: 0$/note_count: $NOTE_COUNT/" "$TMP"
rm -f "$TMP.bak"

# Atomic replace
mv "$TMP" "$VAULT/_index.md"

# Warn if index is getting large
LINES=$(wc -l < "$VAULT/_index.md")
if [ "$LINES" -gt 200 ]; then
  echo "WARNING: _index.md has $LINES lines (target: <200)" >&2
  echo "Run REVIEW to find duplicates and archive candidates." >&2
fi

echo "rebuilt _index.md: $NOTE_COUNT notes, $LINES lines"
