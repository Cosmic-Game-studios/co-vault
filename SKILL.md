---
name: co-vault
description: Use whenever the user gives you a task in a project where COVAULT_PATH
  is set, OR whenever COVAULT_PERSON is set, OR the user says "bootstrap co-vault",
  "co-vault review", "abort", or "autonomous: <intent>". This skill operates
  against self-describing vaults using a 6-phase loop grounded in cognitive
  science (predictive coding, CLS theory, spaced repetition). Project-vault
  notes are governed by an authority hierarchy where user notes are immutable.
  Person-vault notes are agent-maintained but bounded by token-efficiency rules.
  Auto-maintenance handles consolidation, decay, archival, and calibration.
---

# co-vault — agent operating instructions (v0.6, scientific loop)

You operate against up to two self-describing vaults:

- **Project vault** (`$COVAULT_PATH`) — per-project facts, decisions,
  proposals, reports, conflicts. Loaded per task.
- **Person vault** (`$COVAULT_PERSON`) — durable knowledge about the user
  across all their projects. Cross-agent. Loaded once per session.

The loop has 6 phases. Each phase maps to a documented function in
cognitive science and writes structured data that feeds the next.

Follow these instructions literally. Do not improvise. If you ever lose
track of which phase you are in, restart from PHASE 1.

## CONVENTIONS — applied to both vault types

- **Self-description first**: read `.covault/manifest.yaml` once per
  session per vault. Read `.covault/schemas/<type>.md` and the matching
  example before writing any note of that type for the first time.
- **Timestamp**: `$(date -u +%Y-%m-%dT%H:%MZ)`.
- **Slug**: 2–4 words, lowercase, hyphenated.
- **Filename**: `<YYYY-MM-DD-HHMM>-<slug>.md`. Append `-2`, `-3`, ... on collision.
- **Path hygiene**: never read or write outside the vault paths during
  the loop, except project code in PHASE 3.
- **Phase announcement**: print `[co-vault: PHASE <N>/6 — <NAME>]` at the
  start of every phase. Non-negotiable.
- **Commit after every write**: `git -C <vault> add . && git -C <vault> commit -q -m "<msg>"`.
- **Token efficiency**: never bulk-load a vault. Always go through indexes
  and named files.
- **Run maintenance after CONSOLIDATE**: `bin/maintain-vault.sh <vault>`.

## ACTIVATION CHECK — run first, every session

```bash
PROJECT_VAULT_OK=0
if [ -n "${COVAULT_PATH:-}" ] && [ -f "$COVAULT_PATH/.covault/manifest.yaml" ]; then
  SV=$(grep -E '^schema_version:' "$COVAULT_PATH/.covault/manifest.yaml" | awk '{print $2}')
  case "$SV" in
    1|2) PROJECT_VAULT_OK=1 ;;
    *) echo "co-vault: project vault schema_version=$SV — refusing" ;;
  esac
fi

PERSON_VAULT_OK=0
if [ -n "${COVAULT_PERSON:-}" ] && [ -f "$COVAULT_PERSON/.covault/manifest.yaml" ]; then
  SV=$(grep -E '^schema_version:' "$COVAULT_PERSON/.covault/manifest.yaml" | awk '{print $2}')
  case "$SV" in
    1|2) PERSON_VAULT_OK=1 ;;
    *) echo "co-vault: person vault schema_version=$SV — refusing" ;;
  esac
fi

[ "$PROJECT_VAULT_OK" = "0" ] && [ "$PERSON_VAULT_OK" = "0" ] && \
  echo "co-vault: no vaults active. Skill is dormant."
```

If the project vault is active, run the 6-phase loop on every task.
If the person vault is active, run SESSION START once before any task.

## AUTHORITY RULES — apply to both vault types, non-negotiable

| author value      | your permitted operations                                        |
|-------------------|------------------------------------------------------------------|
| `user`            | READ, CITE via `[[wikilink]]`. NEVER write, edit, move, archive. |
| `agent+reviewed`  | READ, CITE. NEVER write or edit. (auto-promoted from `agent`)    |
| `agent`           | READ, WRITE, EDIT, SUPERSEDE, ARCHIVE.                           |
| (no author field) | TREAT AS BROKEN. Report to user.                                 |

In project vaults, default author for new notes:
- `user` for decisions, domains, index
- `agent` for proposals, reports, facts, conflicts

In person vaults, default author for new notes is `agent`.

## SCHEMA LOOKUP — before every write

Before writing a note of type `T` for the first time in a session:
```bash
cat "<vault>/.covault/schemas/$T.md"
cat "<vault>/.covault/examples/$T.md"
```
Match the schema. Use the example as a template.

---

## SESSION START — only if COVAULT_PERSON is active

Run ONCE per session, before any task. Loads durable knowledge about the
user without bulk-loading the entire vault.

```bash
cd "$COVAULT_PERSON"
cat .covault/manifest.yaml          # know the schemas
cat _index.md                        # one-line summaries of every note
find corrections -type f -name '*.md' -not -name '.gitkeep' \
  -exec sh -c 'echo "=== $1 ==="; cat "$1"; echo' _ {} \;
[ -f identity/basic.md ] && { echo "=== identity/basic.md ==="; cat identity/basic.md; }
```

That is all the bulk loading. Everything else is fetched on demand based
on the index.

**Token budget rule**: total person vault overhead per session must stay
under ~3000 tokens. If exceeded, run REVIEW and prune.

---

## CALIBRATION AWARENESS — read on every session

If a project vault is active, read its calibration log:
```bash
[ -f "$COVAULT_PATH/calibration_log.md" ] && cat "$COVAULT_PATH/calibration_log.md"
```

This file (auto-maintained by `maintain-vault.sh`) shows your
historical prediction accuracy. Use it to calibrate the confidence
values you assign in PHASE 2 HYPOTHESIZE. If past predictions at "90%"
were only correct 70% of the time, adjust this session's "90%" downward.

---

# THE 6-PHASE LOOP

```
PHASE 1   PHASE 2          PHASE 3   PHASE 4   PHASE 5      PHASE 6
ORIENT  → HYPOTHESIZE    → EXECUTE → VERIFY  → CONSOLIDATE → REVIEW
                                                             (only if conflict)
perception generative      action    prediction memory       conflict
           model with                error      consolidation resolution
           predictions               checking
```

Each phase has a documented function in cognitive science. Each phase
writes structured data that feeds the next. You will run all 6 phases.
You will not collapse phases. You will not skip CONSOLIDATE.

---

## PHASE 1 — ORIENT
*Function: situated perception. Build a model of the current knowledge state.*

Announce: `[co-vault: PHASE 1/6 — ORIENT]`

```bash
cd "$COVAULT_PATH"
cat index.md
DOMAINS="<inferred from user request, space-separated>"

# Read domain notes for each domain touched
for D in $DOMAINS; do
  [ -f "domains/$D.md" ] && { echo "=== domains/$D.md ==="; cat "domains/$D.md"; echo; }
done

# Pull user-authored notes in those domains
for D in $DOMAINS; do
  find decisions facts -type f -name '*.md' 2>/dev/null | while read f; do
    grep -qE '^author:[[:space:]]*user[[:space:]]*$' "$f" \
      && grep -qE "domain:.*$D" "$f" \
      && { echo "=== $f ==="; cat "$f"; echo; }
  done
done

# Check for OPEN conflicts in those domains
for D in $DOMAINS; do
  find conflicts -type f -name '*.md' 2>/dev/null | while read f; do
    grep -qE '^status:[[:space:]]*open[[:space:]]*$' "$f" \
      && grep -qE "domain:.*$D" "$f" \
      && echo "OPEN CONFLICT: $f"
  done
done
```

ALSO, if `COVAULT_PERSON` is active, opportunistically scan the person
vault index for hits on the current task's domains:
```bash
[ -n "${COVAULT_PERSON:-}" ] && grep -iE "($(echo $DOMAINS | tr ' ' '|'))" \
  "$COVAULT_PERSON/_index.md" 2>/dev/null
```
For any hit, `cat` that specific file.

**Stopping conditions:**
- Open conflict in domain → STOP, ask user.
- User-authored note contradicts the task → STOP, quote it, ask user.

---

## PHASE 2 — HYPOTHESIZE
*Function: build a generative model with explicit, testable predictions.*
*Science: predictive coding (Friston 2010); active inference.*

Announce: `[co-vault: PHASE 2/6 — HYPOTHESIZE]`

Read schema and example:
```bash
cat "$COVAULT_PATH/.covault/schemas/proposal.md"
cat "$COVAULT_PATH/.covault/examples/proposal.md"
```

Write `proposals/<timestamp>-<slug>.md` matching the schema. Critically:

- **`## Predictions` is required.** Minimum 3 predictions, each with a
  confidence number (0-100%) and a clearly testable claim.
- Use the calibration log (loaded earlier) to ground confidence values.
  If your historical "80%" predictions were only correct 60% of the time,
  use 60% this time.
- Testable means: there is a clear way to mark each prediction as
  correct / partial / wrong / untestable in the matching report.

Commit:
```bash
git -C "$COVAULT_PATH" add . && git -C "$COVAULT_PATH" commit -q -m "hypothesize: <slug>"
```

Print the proposal path. If `estimated_effort` is `medium` or `large`,
WAIT for explicit user confirmation. If `small`, proceed.

---

## PHASE 3 — EXECUTE
*Function: motor action. Touch project code.*

Announce: `[co-vault: PHASE 3/6 — EXECUTE]`

Do the actual work in project code (NOT in vaults).

Rules:
1. Stay strictly inside the proposal's `Out of scope` constraints.
2. Reference the proposal in commit messages on the project repo:
   `<type>(<scope>): <subject>  [co-vault: <proposal-filename>]`
3. If you discover a contradiction with a `user` note, STOP and jump
   straight to PHASE 6.
4. If the user says "abort", jump to PHASE 4 with `status: aborted`.
5. **Track prediction-relevant data while you work**: time elapsed,
   files touched, tests passing/failing. You will need this in PHASE 4.

---

## PHASE 4 — VERIFY
*Function: prediction error checking. Compare each prediction to reality.*
*Science: predictive processing; Bayesian updating.*

Announce: `[co-vault: PHASE 4/6 — VERIFY]`

For each prediction in the matching proposal, mark it as:
- `correct` — prediction matched reality
- `partial` — directionally right but off in degree
- `wrong` — contradicted by reality
- `untestable` — no evidence either way (rare; usually means a bad prediction)

These verdicts go into the report's `## Verification` section in PHASE 5.

**Be honest.** Marking a wrong prediction as "partial" to make yourself
look good corrupts the calibration log and degrades all future planning.

---

## PHASE 5 — CONSOLIDATE
*Function: write to memory. Update calibration. Promote stable facts.*
*Science: Complementary Learning Systems (McClelland 1995); memory consolidation.*

Announce: `[co-vault: PHASE 5/6 — CONSOLIDATE]`

Read schemas:
```bash
cat "$COVAULT_PATH/.covault/schemas/report.md"
cat "$COVAULT_PATH/.covault/examples/report.md"
cat "$COVAULT_PATH/.covault/schemas/fact.md"        # if creating new facts
```

**Step 5a — Write the report.** Filename: `reports/<same-name-as-proposal>.md`.
Match the schema. Include the `## Verification` section with verdicts from
PHASE 4. Set `predictions_correct`, `predictions_partial`, `predictions_wrong`
in frontmatter.

**Step 5b — Write any new facts.** For each genuinely new piece of
knowledge from PHASE 3, write a separate atomic file in `facts/`. One
claim per file. Set `confirmation_count: 1` and `last_confirmed: <now>`.

**Step 5c — Re-confirm existing facts.** If during PHASE 3 you observed
something that confirms an existing `agent`-authored fact, update its
`confirmation_count` (increment) and `last_confirmed` (now). Do NOT
duplicate the fact.

**Step 5d — Commit.**
```bash
git -C "$COVAULT_PATH" add . && git -C "$COVAULT_PATH" commit -q -m "consolidate: <slug>"
```

**Step 5e — Run auto-maintenance.** This is mandatory:
```bash
"$COVAULT_REPO/bin/maintain-vault.sh" "$COVAULT_PATH"
```
(`COVAULT_REPO` defaults to `~/.claude/skills/co-vault`.)

The maintainer will:
- Decay confidence on stale notes
- Promote facts with `confirmation_count >= 3` to `agent+reviewed`
- Archive notes past `valid_until`
- Recompute the calibration log
- Validate the vault and abort if anything is malformed

If `COVAULT_PERSON` is active, also run **PERSON LEARNING** (next section)
and then run maintain on the person vault too.

If no contradiction was found, announce:
`[co-vault: PHASE 6/6 — skipped, no conflict]`
The loop is done.

---

## PERSON LEARNING — runs inside CONSOLIDATE if COVAULT_PERSON is active

Ask yourself four questions:

1. **Did the user correct me on something during this task?**
   → Write `corrections/<topic>.md` matching the `correction.md` schema.
2. **Did I observe a stable preference I haven't recorded?**
   → Check `_index.md` for a matching preference. If exists, update
   `last_confirmed`. If not, write `preferences/<topic>.md`.
3. **Did I observe a behavioral pattern (3+ instances)?**
   → Same: check, update or create `patterns/<topic>.md`.
4. **Did the person's life/work context change?**
   → Update or create `context/<topic>.md`.

**Strict criteria for any new note** — all four must be true:
- **Durable** (not session-specific)
- **Non-obvious** (not "user uses a computer")
- **Useful** (would change agent behavior in the future)
- **Not duplicate** (search the index first)

After any write, run:
```bash
"$COVAULT_REPO/bin/maintain-vault.sh" "$COVAULT_PERSON"
```

If you can't decide whether something is worth recording: don't.

---

## PHASE 6 — REVIEW (only if contradiction found)
*Function: cognitive control. Resolve a clash between observation and ground truth.*

Announce: `[co-vault: PHASE 6/6 — REVIEW]`

Trigger conditions (any of):
- A `user`-authored note states X and you observed not-X.
- A `user`-authored note forbids approach Y and the task requires Y.
- Two `user`-authored notes contradict each other.

When triggered:
1. Stop all work in the affected domain immediately.
2. Read schema:
   ```bash
   cat "$COVAULT_PATH/.covault/schemas/conflict.md"
   ```
3. Write `conflicts/<timestamp>-<slug>.md` matching the schema.
4. Commit.
5. Print conflict path.
6. State: "I have stopped work on this task. Please resolve the conflict
   and tell me how to proceed."
7. Do NOT continue. Do NOT run CONSOLIDATE on a conflicted task. Do NOT
   work on anything else in the same domain.

---

# AUTONOMOUS MODE

When the user says "autonomous: <intent>" or "fire and forget: <intent>"
or "run autonomously and report back: <intent>".

## Hard limits — non-negotiable
- **Must run on a feature branch.** If you are on `main`, create one
  named `co-vault/<timestamp>-<slug>` first. Refuse to start if a clean
  branch can't be created.
- **Maximum 5 sub-tasks per autonomous run.**
- **Hard token budget: 30000 tokens per run.** Track and abort if exceeded.
- **Any conflict in any sub-task immediately exits autonomous mode** and
  drops back to interactive. Do not continue with other sub-tasks.
- **Any out-of-scope discovery exits autonomous mode.**
- **Final report is mandatory.**

## Procedure

1. **Create branch** if not on one:
   ```bash
   BRANCH="co-vault/$(date -u +%Y%m%d-%H%M)-<slug>"
   git checkout -b "$BRANCH"
   ```

2. **Write a master plan** to `proposals/<timestamp>-autonomous-<slug>.md`
   listing every sub-task, with `type: master_proposal` in frontmatter.
   Each sub-task gets its own one-line entry with effort estimate.

3. **Wait for ONE user confirmation of the master plan.** This is your
   only checkpoint before running autonomously. Do not proceed without
   explicit "yes" or equivalent.

4. **For each sub-task in order**, run the full 6-phase loop:
   - Auto-confirm `small` and `medium` proposals (NOT `large`).
   - Treat any conflict, any out-of-scope discovery, any `large` effort
     as an exit signal.
   - Track cumulative tokens. If approaching budget, exit.

5. **Final report**: write `reports/<timestamp>-autonomous-<slug>.md`
   summarizing every sub-task that ran, its result, every file in
   project code that was changed, every vault file that was written,
   any sub-tasks that were skipped due to exit conditions.
   End the report with exactly:
   > Review the branch `<branch-name>` and decide: merge, fix, or discard.

6. **Stop and notify the user.** Do not auto-merge. Do not run further
   tasks until the user reviews.

## Why these limits exist
- The branch limit prevents runaway changes from polluting `main`.
- The sub-task limit prevents the agent from getting lost in a long chain
  where prediction errors compound.
- The token budget prevents pathological loops.
- The conflict-exit prevents the agent from working around your decisions
  in autonomous mode where you're not actively watching.

If the user pushes back ("just do it, ignore the limits"), refuse and
explain that autonomous mode without these guards is a footgun.

---

# HARD RULES — violating any of these is a failure of the skill

1. **Never edit a file with `author: user`.** Open a conflict instead.
2. **Never edit a file with `author: agent+reviewed`.** Same rule.
3. **Never delete a file.** Move to `_archive/` with a top-comment reason.
4. **Never write a note without reading its schema first** in the current session.
5. **Never write a note without complete frontmatter.**
6. **Never write a proposal without `## Predictions`** containing at least
   3 testable predictions with confidence values.
7. **Never write a report without `## Verification`** marking every
   prediction from the matching proposal.
8. **Never write more than one claim per `facts/` file.**
9. **Never write more than one topic per file** in person vault.
10. **Never silently supersede.** Use `superseded_by:` and move old to `_archive/`.
11. **Never auto-consolidate semantic content.** Only the deterministic
    `bin/maintain-vault.sh` may modify confidence, promotion, archival.
12. **Never proceed past an open conflict in the affected domain.**
13. **Never copy text between notes.** Use `[[wikilinks]]`.
14. **Never read or write outside the vaults** during the loop, except
    project code in PHASE 3.
15. **Never skip the phase announcement.**
16. **Never operate on a vault with mismatched `schema_version`.**
17. **Never bulk-load the person vault.**
18. **Never duplicate a note.** Search the index first; update if exists.
19. **Never inflate prediction verdicts.** Mark wrong predictions as
    wrong, even if it makes the calibration log look bad.
20. **Never enter autonomous mode without a feature branch.**

---

## ABORT command — when the user says "abort", "stop", "cancel"

1. Stop PHASE 3 immediately.
2. Jump to PHASE 5 (CONSOLIDATE) with report `status: aborted`.
3. In `## What actually happened`, document what was done, what was
   left undone, what needs cleanup.
4. Mark all open predictions as `untestable`.
5. Commit. Run maintain-vault. Stop.
6. Do NOT run PERSON LEARNING after an abort.

"Abort" is not "pause". Once aborted, the loop is over.

---

## REVIEW command — only when the user explicitly says it

Trigger phrases: "review the vault", "co-vault review", "vault status".

Run `bin/maintain-vault.sh` first (it includes validation), then present
the maintenance output as numbered action items. Do NOT make decisions
on archive / promote / fix yourself. The user decides.

---

## BOOTSTRAP — when vaults are uninitialized

Tell the user this exact instruction:

> To bootstrap a project vault:
>
> ```bash
> ./install.sh "$COVAULT_PATH"
> ```
>
> To bootstrap a person vault:
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
operating co-vault correctly. If uncertain which phase you are in,
restart from PHASE 1 — re-running ORIENT is cheap; acting on stale
context is expensive.

The whole point of this skill is to make agent behavior predictable,
auditable, and improvement-trackable over time. Every prediction you
make goes into the calibration log. Every fact you observe goes into
consolidation. Every conflict you find blocks work until the human
decides. Nothing happens silently. Nothing happens without a record.

That is the contract.
