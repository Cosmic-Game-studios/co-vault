#!/usr/bin/env bash
# maintain-vault.sh — full auto-maintenance for a co-vault.
#
# Usage: ./bin/maintain-vault.sh <vault-path>
#
# Performs in order:
#   1. Validation — abort if vault is malformed
#   2. Index rebuild (person vaults) — keep _index.md current
#   3. Confidence decay — Ebbinghaus-like forgetting on stale notes
#   4. Fact promotion — confirmation_count >= 3 → agent+reviewed (CLS theory)
#   5. Archival — notes past valid_until move to _archive/
#   6. Calibration update — recompute Brier-like score from reports
#
# Designed to be deterministic, fast, and safe.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
VAULT_RAW="${1:-}"

if [ -z "$VAULT_RAW" ]; then
  echo "Usage: $0 <vault-path>" >&2
  exit 2
fi
if [ ! -d "$VAULT_RAW" ]; then
  echo "ERROR: not a directory: $VAULT_RAW" >&2
  exit 2
fi

VAULT="$(cd "$VAULT_RAW" && pwd)"

if [ ! -f "$VAULT/.covault/manifest.yaml" ]; then
  echo "ERROR: not a co-vault (no manifest): $VAULT" >&2
  exit 2
fi

cd "$VAULT"

SCOPE=$(grep -E '^scope:' .covault/manifest.yaml 2>/dev/null | awk '{print $2}')
[ -z "${SCOPE:-}" ] && SCOPE="project"

NOW=$(date -u +%Y-%m-%dT%H:%MZ)
NOW_EPOCH=$(date -u +%s)
THIRTY_DAYS_AGO=$((NOW_EPOCH - 30*86400))

PROMOTED=0
ARCHIVED=0
DECAYED=0

echo "==> co-vault maintenance starting ($SCOPE vault)"

# ==========================================================================
# Step 1 — Validation
# ==========================================================================
echo "==> [1/6] Validating vault structure..."
"$SCRIPT_DIR/validate-vault.sh" "$VAULT" >/tmp/covault_validate.log 2>&1
VALIDATE_EXIT=$?
if [ "$VALIDATE_EXIT" -ne 0 ]; then
  echo "ABORT: validation failed (exit $VALIDATE_EXIT). Output:"
  cat /tmp/covault_validate.log
  exit 1
fi

# ==========================================================================
# Step 2 — Index rebuild (person vaults)
# ==========================================================================
if [ "$SCOPE" = "person" ]; then
  echo "==> [2/6] Rebuilding person vault index..."
  "$SCRIPT_DIR/rebuild-index.sh" "$VAULT" >/dev/null 2>&1 || {
    echo "WARN: rebuild-index failed"
  }
else
  echo "==> [2/6] Skipping index rebuild (project vault)"
fi

# ==========================================================================
# Step 3 — Confidence decay
# ==========================================================================
echo "==> [3/6] Applying confidence decay to stale notes..."

decay_files=()
while IFS= read -r f; do
  decay_files+=("$f")
done < <(find . -type f -name '*.md' \
  -not -path './.covault/*' \
  -not -path './_archive/*' \
  -not -path './.git/*' 2>/dev/null)

for f in "${decay_files[@]}"; do
  LC=$(grep -m1 -E '^last_confirmed:' "$f" 2>/dev/null | awk '{print $2}' || true)
  [ -z "${LC:-}" ] && continue

  LC_EPOCH=$(date -u -d "$LC" +%s 2>/dev/null || echo "0")
  [ "$LC_EPOCH" = "0" ] && continue
  [ "$LC_EPOCH" -ge "$THIRTY_DAYS_AGO" ] && continue

  CONF=$(grep -m1 -E '^confidence:' "$f" 2>/dev/null | awk '{print $2}' || true)
  case "${CONF:-}" in
    high)
      sed -i.bak 's/^confidence:[[:space:]]*high[[:space:]]*$/confidence: medium/' "$f" 2>/dev/null || true
      rm -f "$f.bak"
      DECAYED=$((DECAYED + 1))
      ;;
    medium)
      sed -i.bak 's/^confidence:[[:space:]]*medium[[:space:]]*$/confidence: low/' "$f" 2>/dev/null || true
      rm -f "$f.bak"
      DECAYED=$((DECAYED + 1))
      ;;
  esac
done

echo "    decayed $DECAYED notes"

# ==========================================================================
# Step 4 — Promote facts with confirmation_count >= 3
# ==========================================================================
echo "==> [4/6] Promoting frequently-confirmed facts..."

if [ -d "facts" ]; then
  promote_files=()
  while IFS= read -r f; do
    promote_files+=("$f")
  done < <(find facts -type f -name '*.md' 2>/dev/null)

  for f in "${promote_files[@]}"; do
    AUTHOR=$(grep -m1 -E '^author:' "$f" 2>/dev/null | awk '{print $2}' || true)
    [ "${AUTHOR:-}" != "agent" ] && continue

    COUNT=$(grep -m1 -E '^confirmation_count:' "$f" 2>/dev/null | awk '{print $2}' || true)
    [ -z "${COUNT:-}" ] && continue
    [ "$COUNT" -lt 3 ] 2>/dev/null && continue

    sed -i.bak 's/^author:[[:space:]]*agent[[:space:]]*$/author: agent+reviewed/' "$f" 2>/dev/null || true
    rm -f "$f.bak"
    PROMOTED=$((PROMOTED + 1))
    echo "    promoted: $f"
  done
fi

echo "    promoted $PROMOTED facts to agent+reviewed"

# ==========================================================================
# Step 5 — Archive expired notes
# ==========================================================================
echo "==> [5/6] Archiving expired notes..."

archive_files=()
while IFS= read -r f; do
  archive_files+=("$f")
done < <(find . -type f -name '*.md' \
  -not -path './.covault/*' \
  -not -path './_archive/*' \
  -not -path './.git/*' 2>/dev/null)

for f in "${archive_files[@]}"; do
  VU=$(grep -m1 -E '^valid_until:' "$f" 2>/dev/null | awk '{print $2}' || true)
  [ -z "${VU:-}" ] && continue

  VU_EPOCH=$(date -u -d "$VU" +%s 2>/dev/null || echo "0")
  [ "$VU_EPOCH" = "0" ] && continue
  [ "$VU_EPOCH" -ge "$NOW_EPOCH" ] && continue

  base=$(basename "$f")
  mkdir -p _archive
  {
    echo "<!-- archived $NOW: valid_until=$VU passed -->"
    cat "$f"
  } > "_archive/$base"
  rm "$f"
  ARCHIVED=$((ARCHIVED + 1))
  echo "    archived: $f (expired $VU)"
done

echo "    archived $ARCHIVED expired notes"

# ==========================================================================
# Step 6 — Calibration update (project vaults only)
# ==========================================================================
if [ "$SCOPE" = "project" ]; then
  echo "==> [6/6] Updating calibration log..."

  TOTAL_PRED=0
  TOTAL_CORRECT=0
  TOTAL_PARTIAL=0
  TOTAL_WRONG=0

  if [ -d "reports" ]; then
    report_files=()
    while IFS= read -r f; do
      report_files+=("$f")
    done < <(find reports -type f -name '*.md' 2>/dev/null)

    for report in "${report_files[@]}"; do
      PC=$(grep -m1 -E '^predictions_correct:' "$report" 2>/dev/null | awk '{print $2}' || echo "0")
      PP=$(grep -m1 -E '^predictions_partial:' "$report" 2>/dev/null | awk '{print $2}' || echo "0")
      PW=$(grep -m1 -E '^predictions_wrong:' "$report" 2>/dev/null | awk '{print $2}' || echo "0")
      PC=${PC:-0}; PP=${PP:-0}; PW=${PW:-0}
      TOTAL_CORRECT=$((TOTAL_CORRECT + PC))
      TOTAL_PARTIAL=$((TOTAL_PARTIAL + PP))
      TOTAL_WRONG=$((TOTAL_WRONG + PW))
      TOTAL_PRED=$((TOTAL_PRED + PC + PP + PW))
    done
  fi

  if [ "$TOTAL_PRED" -gt 0 ]; then
    NUMER=$((TOTAL_WRONG * 1000 + TOTAL_PARTIAL * 250))
    BRIER_X1000=$((NUMER / TOTAL_PRED))
    BRIER_INT=$((BRIER_X1000 / 1000))
    BRIER_FRAC=$((BRIER_X1000 % 1000))
    BRIER=$(printf "%d.%03d" "$BRIER_INT" "$BRIER_FRAC")
  else
    BRIER="0.000"
  fi

  cat > calibration_log.md <<CALIB
---
type: calibration
author: agent
last_updated: $NOW
total_predictions: $TOTAL_PRED
total_correct: $TOTAL_CORRECT
total_partial: $TOTAL_PARTIAL
total_wrong: $TOTAL_WRONG
brier_score: $BRIER
---

# Calibration log

This file is auto-maintained by \`bin/maintain-vault.sh\`. It aggregates
prediction outcomes from every report in this vault.

## Lifetime totals
- **Total predictions made**: $TOTAL_PRED
- **Correct**: $TOTAL_CORRECT
- **Partial**: $TOTAL_PARTIAL
- **Wrong**: $TOTAL_WRONG
- **Brier-like score**: $BRIER (lower is better, 0 = perfect, 1 = worst)

## Interpretation
- A score below 0.20 means the agent is well-calibrated.
- A score above 0.40 means the agent is over-confident on average.
- The agent reads this file on session start to ground its prediction
  confidence in past performance.

*Last updated: $NOW*
CALIB

  echo "    calibration: $TOTAL_PRED predictions, brier=$BRIER"
else
  echo "==> [6/6] Skipping calibration update (person vault)"
fi

# ==========================================================================
echo
echo "==> maintenance complete"
echo "    decayed:  $DECAYED"
echo "    promoted: $PROMOTED"
echo "    archived: $ARCHIVED"
exit 0
