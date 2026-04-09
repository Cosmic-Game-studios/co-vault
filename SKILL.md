---
name: co-vault
description: Use whenever the user gives you a task in a project where COVAULT_PATH
  is set, OR the user says "bootstrap co-vault", OR the user says "co-vault review".
  This skill makes you operate against a shared Obsidian vault where the user's
  notes are immutable ground truth. You MUST follow the 5-phase loop on every task
  and you MUST NOT silently override notes with `author: user`. Works for any
  project, any language, any stack.
---

# co-vault — agent operating instructions

You are operating against a shared knowledge vault. Follow these instructions
literally. Do not improvise the loop. Do not skip phases.

## ACTIVATION CHECK — run first, every session

```bash
# Abort the skill if no vault is configured
if [ -z "${COVAULT_PATH:-}" ]; then
  echo "co-vault: COVAULT_PATH not set. Skill inactive."
  exit 0
fi

# If the path doesn't exist or is empty, you must run BOOTSTRAP (see bottom)
if [ ! -d "$COVAULT_PATH" ] || [ -z "$(ls -A "$COVAULT_PATH" 2>/dev/null)" ]; then
  echo "co-vault: vault missing or empty — run BOOTSTRAP"
fi
```

If the user did not explicitly set `COVAULT_PATH`, do not assume one. Ask.

## AUTHORITY RULES — non-negotiable

Every note has an `author:` field in its frontmatter. You will check it before
every write operation. Apply this table without exception:

| author value      | your permitted operations                                        |
|-------------------|------------------------------------------------------------------|
| `user`            | READ, CITE via `[[wikilink]]`. NEVER write, edit, move, archive. |
| `agent+reviewed`  | READ, CITE. NEVER write or edit.                                 |
| `agent`           | READ, WRITE, EDIT, SUPERSEDE, ARCHIVE.                           |
| (no author field) | TREAT AS BROKEN. Report to user. Do not write to it.             |

If you ever feel the urge to modify an `author: user` note, stop. Open a
conflict (Phase 5) instead.

## THE LOOP — execute on every task

```
ORIENT → PROPOSE → (user confirm) → EXECUTE → REPORT
                                                  │
                                                  ▼
                                        contradiction found?
                                          │            │
                                         no           yes → REQUEST_REVIEW → STOP
                                          │
                                          ▼
                                         done
```

You will run all 5 phases. You will not collapse PROPOSE into EXECUTE. You
will not skip REPORT because the task was small. You will not silently
proceed past REQUEST_REVIEW.

---

## PHASE 1 — ORIENT

Run before reading any project code.

```bash
cd "$COVAULT_PATH"

# 1.1 — read the index
cat index.md

# 1.2 — find the domain(s) relevant to the task
#       infer DOMAIN from the user's request (e.g. "auth", "billing", "ui")
DOMAIN="<infer from user request>"

# 1.3 — pull every user-authored note in that domain
grep -rlE '^author:[[:space:]]*user[[:space:]]*$' decisions facts domains 2>/dev/null \
  | xargs -I{} sh -c 'grep -lE "domain:.*'"$DOMAIN"'" "{}" 2>/dev/null' \
  | xargs -I{} sh -c 'echo "=== {} ==="; cat "{}"; echo'

# 1.4 — check for OPEN conflicts in this domain
grep -lE 'status:[[:space:]]*open' conflicts/*.md 2>/dev/null \
  | xargs grep -l "$DOMAIN" 2>/dev/null
```

**Stopping conditions for Phase 1:**
- If 1.4 returns any file → STOP. Tell the user there is an open conflict
  in this domain. Do not proceed until the user resolves it.
- If a `user`-authored note in 1.3 directly contradicts the task the user
  just asked for → STOP. Tell the user the contradiction and ask whether
  the note is being revised. Do not proceed until they confirm.

If neither stopping condition fires, proceed to Phase 2.

---

## PHASE 2 — PROPOSE

Write a proposal file BEFORE touching any project code.

**Filename:** `proposals/$(date +%Y-%m-%d-%H%M)-<slug>.md`
The slug is 2–4 words, lowercase, hyphenated, derived from the task.

**Exact template — fill in every field:**

```markdown
---
type: proposal
author: agent
status: pending
domain: <subsystem>
created: <ISO timestamp>
task: "<one-line summary of what the user asked for>"
references:
  - "[[<wikilink to every relevant user note from Phase 1>]]"
---

## Goal
<2-3 sentences. What does success look like? How will you know it worked?>

## Plan
1. <concrete step>
2. <concrete step>
3. <concrete step>

## Assumptions
- <each assumption that, if wrong, would invalidate the plan>

## Out of scope
- <files, modules, or systems you will NOT touch in this task>

## Estimated effort
<small | medium | large>
```

After writing the proposal:
1. Print the proposal path to the user.
2. If `Estimated effort` is `medium` or `large`, WAIT for explicit user
   confirmation before Phase 3. Acceptable confirmations: "yes", "go",
   "proceed", "ok", or equivalent in any language.
3. If `small`, you may proceed immediately but must still print the path.

---

## PHASE 3 — EXECUTE

Do the actual work. Rules:

1. Stay inside the scope declared in the proposal. If you discover you must
   touch something in `Out of scope`, stop and update the proposal first.
2. Reference the proposal in commit messages:
   `<type>(<scope>): <subject> [co-vault: proposals/<filename>]`
3. If during execution you discover something that contradicts a `user`
   note, stop immediately and jump to Phase 5.

---

## PHASE 4 — REPORT

After EXECUTE finishes (success, failure, or partial), write a report.

**Filename:** same as the proposal, but in `reports/`. Same timestamp.

**Exact template:**

```markdown
---
type: report
author: agent
status: <done | failed | partial>
proposal: "[[proposals/<filename>]]"
domain: <same as proposal>
created: <ISO timestamp>
duration_min: <integer>
new_facts:
  - "[[facts/<slug-of-each-new-fact>]]"
---

## What actually happened
<honest narrative. Include what differed from the plan and why.>

## Assumptions verdict
- <each assumption from the proposal>: confirmed | refuted | untested

## Follow-ups
- [ ] <thing you noticed but did not fix>
- [ ] <thing you noticed but did not fix>
```

**For each genuinely new piece of knowledge** discovered during EXECUTE,
create a separate atomic file in `facts/`. One claim per file. Template:

```markdown
---
type: fact
author: agent
domain: <subsystem>
created: <ISO timestamp>
discovered_in: "[[reports/<filename>]]"
confidence: <low | medium | high>
---

## Claim
<one sentence stating the fact>

## Evidence
<how you observed it>

## Implication
<what changes for future work>
```

Atomic means: if you wrote two claims in one file, split it into two files.

---

## PHASE 5 — REQUEST_REVIEW (only if contradiction found)

Trigger conditions for entering Phase 5 (any of):
- A `user`-authored note states X and you observed not-X.
- A `user`-authored note forbids approach Y and the task requires Y.
- Two `user`-authored notes contradict each other.

When triggered, you MUST:
1. Stop all work in the affected domain immediately.
2. Write a conflict file.
3. Tell the user clearly and wait.

**Filename:** `conflicts/$(date +%Y-%m-%d-%H%M)-<slug>.md`

**Exact template:**

```markdown
---
type: conflict
author: agent
status: open
created: <ISO timestamp>
domain: <subsystem>
contradicts: "[[<wikilink to the user note>]]"
discovered_in: "[[reports/<filename>]]"
---

## The user's claim
> <quote the relevant section of the user note verbatim>

## What I observed
<your evidence, concretely>

## Why this matters
<consequence if unresolved>

## Options for resolution
1. **User note stands** → I will revert <specific change>.
2. **User note is updated** → user must edit <path> themselves; I cannot.
3. **Both true under different conditions** → split the user note into two
   conditional decisions; user must do this edit.
```

After writing the conflict file:
1. Print the conflict path.
2. State plainly: "I have stopped work on this task. Please resolve the
   conflict and tell me how to proceed."
3. Do not work on anything else in the same domain until the user confirms
   resolution.

---

## HARD RULES — violating any of these is a failure of the skill

1. **Never edit a file with `author: user`.** Open a conflict instead.
2. **Never delete a file.** Move it to `_archive/` and add a one-line
   comment at the top explaining why.
3. **Never write a note without complete frontmatter.** Notes without
   frontmatter are invisible to queries and useless.
4. **Never write more than one claim per `facts/` file.** Split it.
5. **Never silently supersede a fact.** Old fact gets `superseded_by:
   [[new-fact]]` in its frontmatter and moves to `_archive/`. Do this only
   for `author: agent` facts. Never for `agent+reviewed` or `user`.
6. **Never auto-consolidate.** Consolidation only happens when the user
   runs the REVIEW command.
7. **Never proceed past an open conflict in the affected domain.**
8. **Never copy text between notes.** Use `[[wikilinks]]`. Duplication is
   how the vault rots.

---

## REVIEW command — only when the user explicitly says it

Trigger phrases: "review the vault", "co-vault review", "vault status".

Run this exact sequence:

```bash
cd "$COVAULT_PATH"

echo "=== OPEN CONFLICTS (these block work) ==="
grep -lE 'status:[[:space:]]*open' conflicts/*.md 2>/dev/null || echo "(none)"

echo
echo "=== STALE PROPOSALS (>7 days, no matching report) ==="
for p in proposals/*.md; do
  [ -f "$p" ] || continue
  base=$(basename "$p")
  if [ ! -f "reports/$base" ] && [ -n "$(find "$p" -mtime +7 2>/dev/null)" ]; then
    echo "  $p"
  fi
done

echo
echo "=== NOTES MISSING FRONTMATTER ==="
for f in $(find . -name '*.md' -not -path './_archive/*'); do
  if ! head -1 "$f" | grep -q '^---$'; then
    echo "  $f"
  fi
done

echo
echo "=== AGENT FACTS FROM LAST 7 DAYS (review candidates for promotion) ==="
find facts -name '*.md' -mtime -7 2>/dev/null | while read f; do
  if grep -q '^author:[[:space:]]*agent[[:space:]]*$' "$f"; then
    echo "  $f"
  fi
done
```

After running, present the output to the user as numbered action items.
**Do not act on any of them yourself.** The user decides what to archive,
promote, or fix. You only report.

---

## BOOTSTRAP — only when COVAULT_PATH is empty or the user says "bootstrap co-vault"

```bash
mkdir -p "$COVAULT_PATH"/{domains,decisions,facts,proposals,reports,conflicts,_archive}

cat > "$COVAULT_PATH/index.md" <<'EOF'
---
author: user
type: index
project: <fill in>
---

# <Project> co-vault

## Stack & ground truth
- <fill in>

## Active domains
- <link domain notes here as you create them>

## Hard rules I care about
1. <fill in>

## Current focus
<one paragraph>
EOF

cd "$COVAULT_PATH" && git init -q && git add . && git commit -q -m "co-vault: bootstrap"
```

After bootstrap, tell the user exactly this:

> Vault bootstrapped at `$COVAULT_PATH`. Open `index.md` and fill in the
> stack, rules, and current focus. Those become my ground truth. I will
> not start any task until you confirm the index is filled in.

Then wait. Do not begin any work until the user confirms.

---

## END OF SKILL

If you reached this point without violating any rule above, you are
operating co-vault correctly.
