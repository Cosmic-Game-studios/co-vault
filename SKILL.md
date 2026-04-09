---
name: co-vault
description: Use whenever the user gives you a task in a project where COVAULT_PATH
  is set, OR the user says "bootstrap co-vault", "co-vault review", or "abort"
  mid-task. This skill makes you operate against a shared Obsidian vault where
  the user's notes are immutable ground truth. The vault is self-describing — you
  read `.covault/manifest.yaml` once and `.covault/schemas/<type>.md` before each
  write. You MUST follow the 5-phase loop and you MUST NOT silently override notes
  with `author: user`. Works for any project, any language, any stack.
---

# co-vault — agent operating instructions (v0.3, manifest-driven)

You are operating against a shared, self-describing knowledge vault.
Follow these instructions literally. Do not improvise the loop. Do not
skip phases. If you ever lose track of which phase you are in, restart
from PHASE 1.

## CONVENTIONS — applied throughout

- **Self-description first**: the vault declares its own structure in
  `$COVAULT_PATH/.covault/manifest.yaml`. You read this once per session.
  You read `$COVAULT_PATH/.covault/schemas/<type>.md` before writing any
  note of that type for the first time in a session.
- **Timestamp format**: `$(date -u +%Y-%m-%dT%H:%MZ)` (UTC, minute precision).
- **Slug format**: 2–4 words, lowercase, hyphenated.
- **Filename format**: `<YYYY-MM-DD-HHMM>-<slug>.md`.
- **Collision rule**: if filename exists, append `-2`, `-3`, ... until unique.
- **Path hygiene**: never read or write outside `$COVAULT_PATH` during the
  loop, except for project code touched in PHASE 3.
- **Phase announcement**: at the start of every phase, print one line:
  `[co-vault: PHASE <N>/5 — <NAME>]`. Non-negotiable.
- **Commit after every phase write**: after writing any file in the vault,
  run `git -C "$COVAULT_PATH" add . && git -C "$COVAULT_PATH" commit -q -m "<msg>"`.

## ACTIVATION CHECK — run first, every session

```bash
# 1. Vault path must be set
if [ -z "${COVAULT_PATH:-}" ]; then
  echo "co-vault: COVAULT_PATH not set. Skill inactive."
  exit 0
fi

# 2. Manifest must exist — vault is self-describing
if [ ! -f "$COVAULT_PATH/.covault/manifest.yaml" ]; then
  echo "co-vault: no manifest at $COVAULT_PATH/.covault/manifest.yaml"
  echo "co-vault: this vault is uninitialized — run BOOTSTRAP"
  exit 0
fi

# 3. Read the manifest into context
cat "$COVAULT_PATH/.covault/manifest.yaml"

# 4. Verify schema version compatibility
SCHEMA_VERSION=$(grep -E '^schema_version:' "$COVAULT_PATH/.covault/manifest.yaml" \
  | awk '{print $2}')
if [ "$SCHEMA_VERSION" != "1" ]; then
  echo "co-vault: incompatible schema_version $SCHEMA_VERSION (this skill expects 1)"
  echo "co-vault: refusing to operate. Tell the user to update the skill."
  exit 0
fi
```

If `COVAULT_PATH` is not set, ask the user. Do not assume one.
If the manifest is missing, run BOOTSTRAP (see bottom).
If the schema version mismatches, refuse to operate.

## AUTHORITY RULES — non-negotiable

Every note has an `author:` field in its frontmatter. Check it before
every write. The hierarchy comes from the manifest, but you must apply it
without exception:

| author value      | your permitted operations                                        |
|-------------------|------------------------------------------------------------------|
| `user`            | READ, CITE via `[[wikilink]]`. NEVER write, edit, move, archive. |
| `agent+reviewed`  | READ, CITE. NEVER write or edit.                                 |
| `agent`           | READ, WRITE, EDIT, SUPERSEDE, ARCHIVE.                           |
| (no author field) | TREAT AS BROKEN. Report to user. Do not write to it.             |

If you ever feel the urge to modify an `author: user` note, stop. Open a
conflict (PHASE 5) instead.

## SCHEMA LOOKUP — before every write

Before writing a note of type `T` for the first time in a session, run:

```bash
cat "$COVAULT_PATH/.covault/schemas/$T.md"
cat "$COVAULT_PATH/.covault/examples/$T.md"
```

Use the schema to know which frontmatter fields are required. Use the
example to pattern-match the body structure. Do not invent fields. Do not
omit required fields. If your write fails to match the schema, the skill
has failed.

## THE LOOP

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
                                      done   PHASE 5 REQUEST_REVIEW → STOP
```

You will run all 5 phases. You will not collapse PROPOSE into EXECUTE.
You will not skip REPORT because the task was small. You will not silently
proceed past REQUEST_REVIEW.

---

## PHASE 1 — ORIENT

Announce: `[co-vault: PHASE 1/5 — ORIENT]`

Run before reading any project code.

```bash
cd "$COVAULT_PATH"

# 1.1 — read the index
cat index.md

# 1.2 — infer the relevant DOMAIN(S) from the user's request
#       Tasks may touch multiple domains. Process all of them.
DOMAINS="auth ui"   # space-separated, inferred from user request

# 1.3 — read each domain note (if it exists)
for D in $DOMAINS; do
  [ -f "domains/$D.md" ] && { echo "=== domains/$D.md ==="; cat "domains/$D.md"; echo; }
done

# 1.4 — pull every user-authored note in those domains
for D in $DOMAINS; do
  echo "--- user notes in domain: $D ---"
  find decisions facts -name '*.md' 2>/dev/null | while read f; do
    if grep -qE '^author:[[:space:]]*user[[:space:]]*$' "$f" \
       && grep -qE "domain:.*$D" "$f"; then
      echo "=== $f ==="
      cat "$f"
      echo
    fi
  done
done

# 1.5 — check for OPEN conflicts in those domains
for D in $DOMAINS; do
  find conflicts -name '*.md' 2>/dev/null | while read f; do
    if grep -qE '^status:[[:space:]]*open[[:space:]]*$' "$f" \
       && grep -qE "domain:.*$D" "$f"; then
      echo "OPEN CONFLICT: $f"
    fi
  done
done
```

**Stopping conditions for PHASE 1:**

- If 1.5 reports any open conflict → STOP. Tell the user the conflict
  path. Do not proceed until they resolve it and explicitly say to continue.
- If a `user`-authored note in 1.4 directly contradicts the task the user
  just asked for → STOP. Quote the note. Ask whether it is being revised.
  Do not proceed until they confirm.

If neither condition fires, proceed to PHASE 2.

---

## PHASE 2 — PROPOSE

Announce: `[co-vault: PHASE 2/5 — PROPOSE]`

**Before writing**, read the schema and example:
```bash
cat "$COVAULT_PATH/.covault/schemas/proposal.md"
cat "$COVAULT_PATH/.covault/examples/proposal.md"
```

Then write a proposal file. **Filename**:
`proposals/<timestamp>-<slug>.md` (apply collision rule).

Match the schema exactly. All required frontmatter fields. Body sections
in the order the schema specifies. Use the example as a template.

After writing, commit:
```bash
git -C "$COVAULT_PATH" add . \
  && git -C "$COVAULT_PATH" commit -q -m "propose: <slug>"
```

Then:
1. Print the proposal path to the user.
2. If `estimated_effort` is `medium` or `large`, WAIT for explicit
   confirmation: "yes", "go", "proceed", "ok", or equivalent in any
   language. Do NOT start PHASE 3 until you have it.
3. If `small`, proceed immediately.

---

## PHASE 3 — EXECUTE

Announce: `[co-vault: PHASE 3/5 — EXECUTE]`

Do the actual work on the project code (NOT inside the vault). Rules:

1. Stay strictly inside the scope declared in the proposal. If you must
   touch something in `Out of scope`, STOP, update the proposal, and
   re-confirm with the user.
2. Reference the proposal in commit messages on the project repo:
   `<type>(<scope>): <subject>  [co-vault: <proposal-filename>]`
3. If you discover something that contradicts a `user` note, STOP
   immediately and jump to PHASE 5.
4. If the user says "abort", jump to PHASE 4 with `status: aborted`.

---

## PHASE 4 — REPORT

Announce: `[co-vault: PHASE 4/5 — REPORT]`

**Before writing**, read the schemas you'll need:
```bash
cat "$COVAULT_PATH/.covault/schemas/report.md"
cat "$COVAULT_PATH/.covault/examples/report.md"
# If you'll create new facts:
cat "$COVAULT_PATH/.covault/schemas/fact.md"
cat "$COVAULT_PATH/.covault/examples/fact.md"
```

Write the report. **Filename**: `reports/<same-name-as-proposal>.md`.
Match the schema exactly.

**For each genuinely new piece of knowledge** discovered during EXECUTE,
create a separate atomic file in `facts/`. **One claim per file.** If you
wrote two claims in one file, split them into two.

After all writes, commit:
```bash
git -C "$COVAULT_PATH" add . \
  && git -C "$COVAULT_PATH" commit -q -m "report: <slug> (<status>)"
```

If no contradiction was found, announce:
`[co-vault: PHASE 5/5 — skipped, no conflict]`
The loop is done.

---

## PHASE 5 — REQUEST_REVIEW (only if contradiction found)

Announce: `[co-vault: PHASE 5/5 — REQUEST_REVIEW]`

Trigger conditions (any of):
- A `user`-authored note states X and you observed not-X.
- A `user`-authored note forbids approach Y and the task requires Y.
- Two `user`-authored notes contradict each other.

When triggered:
1. Stop all work in the affected domain immediately.
2. Read the schema:
   ```bash
   cat "$COVAULT_PATH/.covault/schemas/conflict.md"
   cat "$COVAULT_PATH/.covault/examples/conflict.md"
   ```
3. Write the conflict file. **Filename**: `conflicts/<timestamp>-<slug>.md`.
   Match the schema exactly.
4. Commit:
   ```bash
   git -C "$COVAULT_PATH" add . \
     && git -C "$COVAULT_PATH" commit -q -m "conflict: <slug>"
   ```
5. Print the conflict path.
6. State plainly: "I have stopped work on this task. Please resolve the
   conflict and tell me how to proceed."
7. Do not work on anything else in the same domain until the user
   confirms resolution.

---

## HARD RULES — violating any of these is a failure of the skill

1. **Never edit a file with `author: user`.** Open a conflict instead.
2. **Never delete a file.** Move it to `_archive/` and add a one-line top
   comment explaining why.
3. **Never write a note without reading its schema first** in the current
   session. Schema files live in `.covault/schemas/<type>.md`.
4. **Never write a note without complete frontmatter.** Required fields
   come from the schema.
5. **Never write more than one claim per `facts/` file.** Split it.
6. **Never silently supersede a fact.** Old fact gets `superseded_by:
   [[new-fact]]` in its frontmatter and moves to `_archive/`. Do this
   only for `author: agent` facts. Never for `agent+reviewed` or `user`.
7. **Never auto-consolidate.** Consolidation only happens when the user
   runs the REVIEW command.
8. **Never proceed past an open conflict in the affected domain.**
9. **Never copy text between notes.** Use `[[wikilinks]]`. Duplication is
   how the vault rots.
10. **Never read or write outside `$COVAULT_PATH`** during the loop,
    except for project code in PHASE 3.
11. **Never skip the phase announcement.**
12. **Never operate on a vault with mismatched `schema_version`.**

---

## ABORT command — when the user says "abort"

If the user says "abort", "stop", or "cancel" mid-task:
1. Immediately stop PHASE 3 work.
2. Jump to PHASE 4 with `status: aborted`.
3. In "What actually happened", document what was done, what was left
   undone, and any half-finished state in project code that needs cleanup.
4. Commit and stop.

"Abort" is not "pause". Once aborted, the loop is over. Starting again
means a new PHASE 1.

---

## REVIEW command — only when the user explicitly says it

Trigger phrases: "review the vault", "co-vault review", "vault status".

```bash
cd "$COVAULT_PATH"

echo "=== OPEN CONFLICTS (these block work) ==="
find conflicts -name '*.md' 2>/dev/null | while read f; do
  grep -qE '^status:[[:space:]]*open[[:space:]]*$' "$f" && echo "  $f"
done

echo
echo "=== STALE PROPOSALS (>7 days, no matching report) ==="
find proposals -name '*.md' -mtime +7 2>/dev/null | while read p; do
  base=$(basename "$p")
  [ ! -f "reports/$base" ] && echo "  $p"
done

echo
echo "=== NOTES MISSING FRONTMATTER ==="
find . -name '*.md' \
  -not -path './_archive/*' \
  -not -path './.covault/*' \
  -not -path './.git/*' | while read f; do
  head -1 "$f" | grep -q '^---$' || echo "  $f"
done

echo
echo "=== AGENT FACTS FROM LAST 7 DAYS (review candidates for promotion) ==="
find facts -name '*.md' -mtime -7 2>/dev/null | while read f; do
  grep -qE '^author:[[:space:]]*agent[[:space:]]*$' "$f" && echo "  $f"
done

echo
echo "=== UNLINKED NOTES (archive candidates) ==="
find facts decisions domains -name '*.md' 2>/dev/null | while read f; do
  base=$(basename "$f" .md)
  if ! grep -rq "\[\[.*$base" --include='*.md' \
       --exclude-dir=.covault --exclude-dir=.git --exclude-dir=_archive .; then
    echo "  $f"
  fi
done
```

Present the output as numbered action items. **Do not act on any of them
yourself.** The user decides what to archive, promote, or fix.

---

## BOOTSTRAP — only when vault is uninitialized or user says "bootstrap co-vault"

A correctly initialized vault always has `.covault/manifest.yaml`,
`.covault/schemas/`, and `.covault/examples/` populated. Recreating these
by hand is error-prone. The right way to bootstrap is to run `install.sh`
from the co-vault repo, which copies the vault skeleton.

```bash
# Tell the user this exact instruction:
```

> To bootstrap a vault, run the installer from the co-vault repo:
>
> ```bash
> git clone https://github.com/Cosmic-Game-studios/co-vault.git /tmp/co-vault
> /tmp/co-vault/install.sh "$COVAULT_PATH"
> ```
>
> This creates the manifest, schemas, examples, and empty content folders,
> and makes the first git commit. Then open `index.md` and fill in your
> stack, rules, and current focus. I will not start any task until you
> confirm `index.md` is filled in.

After bootstrap, wait for the user to confirm that `index.md` is filled in.
Do not begin any work until then.

---

## END OF SKILL

If you reached this point without violating any hard rule, you are
operating co-vault correctly. If you are uncertain at any point which
phase you are in, restart from PHASE 1 — re-running ORIENT is cheap;
acting on stale context is expensive.
