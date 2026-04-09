---
name: co-vault
description: Use whenever the user gives you a task in a project where COVAULT_PATH
  is set, OR whenever COVAULT_PERSON is set (to load durable knowledge about the
  user across all projects), OR the user says "bootstrap co-vault", "co-vault
  review", or "abort". This skill operates against TWO kinds of self-describing
  vaults — a project vault (per-project) and a person vault (per-human, cross-
  project, cross-agent). User notes are immutable. Agent writes are governed by
  schemas declared in `.covault/`. Works for any project, any language, any stack.
---

# co-vault — agent operating instructions (v0.4, dual scope)

You operate against up to two self-describing vaults:

- **Project vault** (`$COVAULT_PATH`) — per-project facts, decisions, proposals,
  reports, conflicts. Loaded per task.
- **Person vault** (`$COVAULT_PERSON`) — durable knowledge about the user
  across all their projects. Cross-agent. Loaded once per session.

Both vaults are self-describing: each has `.covault/manifest.yaml`,
`.covault/schemas/<type>.md`, `.covault/examples/<type>.md`. You read the
manifest once per session and the relevant schema before each write.

Follow these instructions literally. Do not improvise. If you ever lose
track of which phase you are in, restart from PHASE 1.

## CONVENTIONS — applied to both vault types

- **Self-description first**: read `.covault/manifest.yaml` once per session
  for each vault. Read `.covault/schemas/<type>.md` and the matching example
  before writing any note of that type for the first time.
- **Timestamp**: `$(date -u +%Y-%m-%dT%H:%MZ)`.
- **Slug**: 2–4 words, lowercase, hyphenated (project) or canonical topic
  key (person).
- **Filename collision**: append `-2`, `-3`, ... until unique.
- **Path hygiene**: never read or write outside the vault paths during the
  loop, except for project code in PHASE 3.
- **Phase announcement**: print `[co-vault: PHASE <N>/5 — <name>]` at the
  start of every phase. Non-negotiable.
- **Commit after every write**: `git -C <vault> add . && git -C <vault> commit -q -m "<msg>"`.
- **Token efficiency**: never bulk-load a vault. Always go through indexes
  and named files.

## ACTIVATION CHECK — run first, every session

```bash
# --- Project vault ---
PROJECT_VAULT_OK=0
if [ -n "${COVAULT_PATH:-}" ]; then
  if [ -f "$COVAULT_PATH/.covault/manifest.yaml" ]; then
    SV=$(grep -E '^schema_version:' "$COVAULT_PATH/.covault/manifest.yaml" | awk '{print $2}')
    if [ "$SV" = "1" ]; then
      PROJECT_VAULT_OK=1
    else
      echo "co-vault: project vault schema_version=$SV (expected 1) — refusing"
    fi
  else
    echo "co-vault: COVAULT_PATH set but no manifest — run BOOTSTRAP"
  fi
fi

# --- Person vault ---
PERSON_VAULT_OK=0
if [ -n "${COVAULT_PERSON:-}" ]; then
  if [ -f "$COVAULT_PERSON/.covault/manifest.yaml" ]; then
    SV=$(grep -E '^schema_version:' "$COVAULT_PERSON/.covault/manifest.yaml" | awk '{print $2}')
    if [ "$SV" = "1" ]; then
      PERSON_VAULT_OK=1
    else
      echo "co-vault: person vault schema_version=$SV (expected 1) — refusing"
    fi
  else
    echo "co-vault: COVAULT_PERSON set but no manifest — run BOOTSTRAP --person"
  fi
fi

if [ "$PROJECT_VAULT_OK" = "0" ] && [ "$PERSON_VAULT_OK" = "0" ]; then
  echo "co-vault: no vaults active. Skill is dormant."
fi
```

If `COVAULT_PERSON` is active, immediately run the SESSION START sequence
below. If `COVAULT_PATH` is active, run the LOOP per task as usual.

## AUTHORITY RULES — apply to both vault types, non-negotiable

| author value      | your permitted operations                                        |
|-------------------|------------------------------------------------------------------|
| `user`            | READ, CITE via `[[wikilink]]`. NEVER write, edit, move, archive. |
| `agent+reviewed`  | READ, CITE. NEVER write or edit.                                 |
| `agent`           | READ, WRITE, EDIT, SUPERSEDE, ARCHIVE.                           |
| (no author field) | TREAT AS BROKEN. Report to user. Do not write to it.             |

In the **project vault**, the default author for new notes is `agent` for
proposals/reports/facts/conflicts, and `user` for decisions/index/domains.

In the **person vault**, the default author is `agent` — the agent observes
and writes; the user can override or correct any time.

## SCHEMA LOOKUP — before every write

Before writing a note of type `T` for the first time in a session, in
either vault, run:

```bash
cat "<vault>/.covault/schemas/$T.md"
cat "<vault>/.covault/examples/$T.md"
```

Match the schema. Use the example as a template. Do not invent fields.
Do not omit required fields.

---

## SESSION START — only if COVAULT_PERSON is active

Run ONCE per session, before any task. This loads durable knowledge about
the person into context.

```bash
cd "$COVAULT_PERSON"

# 1. Read the manifest (already done in ACTIVATION)
# 2. Read the index — small file, lists every note with one-line summary
cat _index.md

# 3. Always load all corrections — these are priority
find corrections -name '*.md' -not -name '.gitkeep' 2>/dev/null | while read f; do
  echo "=== $f ==="
  cat "$f"
  echo
done

# 4. Always load core identity
[ -f identity/basic.md ] && { echo "=== identity/basic.md ==="; cat identity/basic.md; echo; }
```

That is all the bulk loading you do for the person vault. Everything else
is fetched on demand: when a task touches a topic that the index suggests
has a relevant preference / pattern / context note, you `cat` exactly that
file.

**Token budget rule**: total person vault overhead per session must stay
under ~3000 tokens. The index + corrections + basic identity should fit
this. If they do not, run REVIEW and prune.

---

## THE LOOP — for every task in the project vault

Only runs if `COVAULT_PATH` is active. Same 5 phases as before. The person
vault is consulted opportunistically inside ORIENT and PERSON LEARNING.

```
PHASE 1 ORIENT  →  PHASE 2 PROPOSE  →  (user confirm if not small)
                                              │
                                              ▼
                                       PHASE 3 EXECUTE
                                              │
                                              ▼
                                       PHASE 4 REPORT
                                              │
                                              ▼
                                  contradiction discovered?
                                       │            │
                                      no           yes
                                       │            │
                                       ▼            ▼
                              PERSON LEARNING   PHASE 5 REQUEST_REVIEW → STOP
                                       │
                                       ▼
                                      done
```

### PHASE 1 — ORIENT

Announce: `[co-vault: PHASE 1/5 — ORIENT]`

```bash
cd "$COVAULT_PATH"
cat index.md
DOMAINS="<inferred from user request, space-separated>"

# Load relevant domain notes
for D in $DOMAINS; do
  [ -f "domains/$D.md" ] && { echo "=== domains/$D.md ==="; cat "domains/$D.md"; echo; }
done

# Pull user-authored notes in those domains
for D in $DOMAINS; do
  find decisions facts -name '*.md' 2>/dev/null | while read f; do
    grep -qE '^author:[[:space:]]*user[[:space:]]*$' "$f" \
      && grep -qE "domain:.*$D" "$f" \
      && { echo "=== $f ==="; cat "$f"; echo; }
  done
done

# Check for OPEN conflicts in those domains
for D in $DOMAINS; do
  find conflicts -name '*.md' 2>/dev/null | while read f; do
    grep -qE '^status:[[:space:]]*open[[:space:]]*$' "$f" \
      && grep -qE "domain:.*$D" "$f" \
      && echo "OPEN CONFLICT: $f"
  done
done
```

**ALSO**, if the person vault is active, scan the index for relevant
preferences and patterns:

```bash
[ -n "${COVAULT_PERSON:-}" ] && grep -iE "($(echo $DOMAINS | tr ' ' '|'))" \
  "$COVAULT_PERSON/_index.md" 2>/dev/null
```

For each hit, `cat` that specific file. Do not bulk-load.

**Stopping conditions:**
- Open conflict in domain → STOP, ask user.
- User-authored note contradicts the task → STOP, quote it, ask user.

### PHASE 2 — PROPOSE

Announce: `[co-vault: PHASE 2/5 — PROPOSE]`

Read schemas:
```bash
cat "$COVAULT_PATH/.covault/schemas/proposal.md"
cat "$COVAULT_PATH/.covault/examples/proposal.md"
```

Write `proposals/<timestamp>-<slug>.md` matching the schema. Commit.
Print path. Wait for confirmation if `estimated_effort` ≠ `small`.

### PHASE 3 — EXECUTE

Announce: `[co-vault: PHASE 3/5 — EXECUTE]`

Do the work in project code (NOT in vaults). Stay inside the proposal
scope. Reference the proposal in commit messages. If contradiction found,
jump to PHASE 5. If user says "abort", jump to PHASE 4 with `status: aborted`.

### PHASE 4 — REPORT

Announce: `[co-vault: PHASE 4/5 — REPORT]`

Read schemas (`report.md`, `fact.md`). Write `reports/<same-name>.md` and
one atomic file in `facts/` per genuinely new piece of knowledge. Commit.

If no contradiction found, proceed to **PERSON LEARNING** (below) and
then announce `[co-vault: PHASE 5/5 — skipped, no conflict]` to end the loop.

### PHASE 5 — REQUEST_REVIEW (only if contradiction)

Announce: `[co-vault: PHASE 5/5 — REQUEST_REVIEW]`

Read schema (`conflict.md`). Write `conflicts/<timestamp>-<slug>.md` matching
the schema. Commit. Print path. State: "I have stopped work on this task.
Please resolve the conflict and tell me how to proceed." Stop.

---

## PERSON LEARNING — runs after PHASE 4 (skipped on conflict/abort)

Only runs if `COVAULT_PERSON` is active. This is where the person vault
grows organically.

Ask yourself these four questions:

1. **Did the user correct me on something during this task?**
   → Write a `corrections/<topic>.md` matching `correction.md` schema.
2. **Did I observe a stable preference I haven't recorded?**
   → Check `_index.md` for an existing matching preference. If exists,
   update `last_confirmed` and increment evidence. If not, write
   `preferences/<topic>.md`.
3. **Did I observe a behavioral pattern (3+ instances)?**
   → Same: check index, update or create `patterns/<topic>.md`.
4. **Did the person's life/work context change?**
   → Update or create `context/<topic>.md`.

**Strict criteria for writing a new note** — all must be true:

- The fact is **durable** (not specific to this one session).
- The fact is **non-obvious** (not "user uses a computer").
- The fact has **utility** (would change agent behavior in the future).
- A similar fact does not already exist in the index — if it does,
  **update** instead of duplicating.

After ANY write to the person vault, run:
```bash
"$COVAULT_REPO/bin/rebuild-index.sh" "$COVAULT_PERSON"
git -C "$COVAULT_PERSON" add . && git -C "$COVAULT_PERSON" commit -q -m "person: <slug>"
```

(`COVAULT_REPO` is the path to the cloned co-vault repo. If unset,
fall back to `~/.claude/skills/co-vault/bin/rebuild-index.sh`.)

If you can't decide whether something is worth recording: **don't**.
Silence is better than vault rot.

---

## HARD RULES — violating any of these is a failure of the skill

1. **Never edit a file with `author: user`.** Open a conflict instead.
2. **Never delete a file.** Move to `_archive/` with a top-comment reason.
3. **Never write a note without reading its schema first** in the current session.
4. **Never write a note without complete frontmatter.**
5. **Never write more than one claim per `facts/` file** (project vault).
6. **Never write more than one topic per file** (person vault).
7. **Never silently supersede.** Use `superseded_by:` and move old to `_archive/`.
8. **Never auto-consolidate.** Only on user-triggered REVIEW.
9. **Never proceed past an open conflict in the affected domain.**
10. **Never copy text between notes.** Use `[[wikilinks]]`.
11. **Never read or write outside the vaults** during the loop, except project code in PHASE 3.
12. **Never skip the phase announcement.**
13. **Never operate on a vault with mismatched `schema_version`.**
14. **Never bulk-load the person vault.** Use the index, fetch on demand.
15. **Never write to the person vault without rebuilding the index afterwards.**
16. **Never duplicate a note.** Search the index first, update if exists.

---

## ABORT command — when the user says "abort", "stop", "cancel"

Stop PHASE 3 immediately. Jump to PHASE 4 with `status: aborted`.
Document what was done, what was left undone, what needs cleanup.
Commit. Stop. Do NOT run PERSON LEARNING after an abort.

---

## REVIEW command — only when the user explicitly says it

Trigger phrases: "review the vault", "co-vault review", "vault status",
"review the project vault", "review the person vault".

Determine which vault(s) the user means; if unclear, do both.

### Project vault review
```bash
cd "$COVAULT_PATH"
echo "=== OPEN CONFLICTS ==="
find conflicts -name '*.md' 2>/dev/null | while read f; do
  grep -qE '^status:[[:space:]]*open[[:space:]]*$' "$f" && echo "  $f"
done
echo
echo "=== STALE PROPOSALS (>7 days, no report) ==="
find proposals -name '*.md' -mtime +7 2>/dev/null | while read p; do
  base=$(basename "$p")
  [ ! -f "reports/$base" ] && echo "  $p"
done
echo
echo "=== AGENT FACTS LAST 7 DAYS (promotion candidates) ==="
find facts -name '*.md' -mtime -7 2>/dev/null | while read f; do
  grep -qE '^author:[[:space:]]*agent[[:space:]]*$' "$f" && echo "  $f"
done
```

### Person vault review
```bash
cd "$COVAULT_PERSON"
echo "=== INDEX SIZE ==="
wc -l _index.md
echo
echo "=== STALE NOTES (last_confirmed >180 days ago) ==="
find . -name '*.md' -not -path './_archive/*' -not -path './.covault/*' \
  -not -path './.git/*' | while read f; do
  last=$(grep -E '^last_confirmed:|^last_observed:' "$f" 2>/dev/null \
    | head -1 | awk '{print $2}')
  [ -z "$last" ] && continue
  if [ "$(date -d "$last" +%s 2>/dev/null || echo 0)" -lt \
       "$(date -d '180 days ago' +%s)" ]; then
    echo "  $f (last confirmed: $last)"
  fi
done
echo
echo "=== LOW-CONFIDENCE NOTES ==="
find . -name '*.md' 2>/dev/null | while read f; do
  grep -qE '^confidence:[[:space:]]*low[[:space:]]*$' "$f" && echo "  $f"
done
```

Present output as numbered action items. **Do not act on them yourself.**
The user decides what to archive, promote, or fix.

---

## BOOTSTRAP — when vaults are uninitialized

Tell the user this exact instruction:

> To bootstrap a project vault, run from the co-vault repo:
>
> ```bash
> ./install.sh "$COVAULT_PATH"
> ```
>
> To bootstrap a person vault (one per human, cross-project):
>
> ```bash
> ./install.sh --person "$COVAULT_PERSON"
> ```
>
> After bootstrap, edit `index.md` (project) or `identity/basic.md`
> (person) before starting work.

Wait for the user to confirm bootstrap is complete.

---

## END OF SKILL

If you reached this point without violating any hard rule, you are
operating co-vault correctly. If uncertain which phase you are in, restart
from PHASE 1 — re-running ORIENT is cheap; acting on stale context is
expensive.
