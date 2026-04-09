# Changelog

All notable changes to co-vault are documented here.
The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.7.0] — 2026-04-09

Structured reasoning meets cognitive science. The agent now thinks before
it acts, explains why approaches should work, learns from its mistakes,
and never repeats failed strategies. Inspired by techniques from the
[DeepResearch](https://github.com/Cosmic-Game-studios/deepresearch)
autonomous optimization framework.

### Added
- **Deep Read protocol** in ORIENT (PHASE 1, Step 1c): mandatory structured
  reasoning before any proposal. Problem decomposition, constraint inventory,
  causal hypothesis formation, and approach enumeration. Prevents the
  "first idea = only idea" failure mode.
- **Anti-pattern tracking**: failed approaches are recorded as facts with
  `pattern_type: anti-pattern` and loaded during ORIENT (Step 1b) to
  prevent the agent from repeating known-bad strategies.
- **Causal hypothesis** (`## Hypothesis` section) required in every proposal.
  Separates "what I think will happen" (predictions) from "why I think it
  will happen" (hypothesis). Includes falsification conditions.
- **Alternatives considered** (`## Alternatives considered` section) required
  in every proposal. At least one rejected approach must be documented.
- **Change-type classification** in proposal frontmatter: `parametric`,
  `structural_addition`, `structural_removal`, `structural_replacement`,
  `integration`, `architectural`. Each has a risk level that determines
  confirmation behavior alongside `estimated_effort`.
- **Reflection protocol** in VERIFY (PHASE 4, Step 4c): mandatory structured
  reflection after prediction verdicts. Covers surprises, causal error
  analysis, model updates, and anti-pattern candidates.
- **Hypothesis verdict** (`## Hypothesis verdict` section) required in every
  report. Evaluates the causal model separately from predictions.
- **Per-domain calibration** in `calibration_log.md`: prediction accuracy
  broken down by domain, so the agent uses domain-specific confidence.
- **Per-change-type calibration**: accuracy broken down by change type, so
  the agent knows which kinds of changes it's best/worst at predicting.
- **Hypothesis accuracy tracking** in calibration log: confirmed vs
  partially confirmed vs refuted counts.

### Changed
- **Manifest version bumped to 0.7.** Adds `change_types`, `reasoning_protocol`,
  and `fact_types` sections to the manifest.
- `proposal.md` schema upgraded to v3: adds `change_type`, `risk_level`,
  `## Hypothesis`, `## Alternatives considered`.
- `report.md` schema upgraded to v3: adds `change_type`, `hypothesis_verdict`,
  `anti_patterns_found`, `## Hypothesis verdict`, `## Reflection`.
- `fact.md` schema upgraded to v3: adds `pattern_type` field
  (`observation` | `anti-pattern`), new body format for anti-pattern facts.
- `calibration.md` schema upgraded to v3: adds hypothesis tracking,
  anti-pattern count, per-domain table, per-change-type table.
- `maintain-vault.sh` enhanced: now computes per-domain and per-change-type
  calibration tables, tracks hypothesis verdicts, counts anti-patterns.
- Hard rules grew from 20 to 27 (added rules for hypothesis, alternatives,
  change_type, reflection, anti-patterns, Deep Read).

### Notes
- The reasoning protocol adds ~350 tokens per task (Deep Read ~200,
  Reflection ~150). This is a small cost for a significant improvement
  in prediction accuracy and domain learning.
- Anti-patterns follow the same CLS consolidation lifecycle as observations:
  confirmed 3+ times → auto-promoted to `agent+reviewed`.
- All v3 schema changes are backward-compatible with v2 reports: the
  calibration log gracefully handles reports without `change_type` or
  `hypothesis_verdict` fields.

## [0.6.0] — 2026-04-09

A scientifically-grounded redesign of the loop. Predictions become first-class
data, calibration is measured automatically, consolidation follows the brain's
own memory architecture. Zero manual maintenance.

### Added
- **6-phase loop** (was 5): `ORIENT → HYPOTHESIZE → EXECUTE → VERIFY → CONSOLIDATE → REVIEW`.
  Each phase is tagged with its function in cognitive science:
  - ORIENT = situated perception (Hutchins 1995)
  - HYPOTHESIZE = generative model with predictions (Friston 2010, predictive coding)
  - EXECUTE = motor action
  - VERIFY = prediction error checking (Bayesian updating)
  - CONSOLIDATE = memory consolidation (McClelland 1995, CLS theory)
  - REVIEW = cognitive control / conflict resolution
- **`## Predictions` section required in every proposal.** Minimum 3 testable
  predictions with explicit confidence values (0–100%). Without predictions
  there is no calibration signal.
- **`## Verification` section required in every report.** Each prediction
  marked `correct` / `partial` / `wrong` / `untestable`.
- **Auto-maintenance script `bin/maintain-vault.sh`** runs after every
  loop. Six steps: validate → rebuild index → confidence decay →
  fact promotion → archive expired → recompute calibration. Deterministic,
  fast (<2s for 500-note vault), no LLM in the loop.
- **CLS-style fact consolidation**: `confirmation_count >= 3` auto-promotes
  an `agent` fact to `agent+reviewed` (immutable). Mirrors hippocampus →
  neocortex transfer in human memory.
- **Ebbinghaus-like confidence decay**: notes whose `last_confirmed` is
  more than 30 days old get downgraded one confidence step (high → medium → low).
- **Auto-archival of expired notes**: notes past their `valid_until` date
  are moved to `_archive/` with a top comment.
- **Calibration log** (`calibration_log.md`) auto-maintained at the
  vault root. Tracks lifetime prediction accuracy with a Brier-like
  score (0 = perfect, 1 = worst). Read by the agent on session start
  to ground confidence values.
- **Autonomous mode**: trigger phrases `autonomous: <intent>`,
  `fire and forget: <intent>`. Hard limits: feature-branch required,
  max 5 sub-tasks, 30000-token budget, immediate exit on any conflict
  or out-of-scope discovery. Mandatory final report with branch review
  instruction.
- **`examples/dataview-queries.md`**: 15 ready-to-use Dataview queries
  for live dashboards in Obsidian. 10 for project vaults, 5 for person
  vaults.
- **Schemas now declare memory_system mapping**. Each folder is tagged
  procedural / semantic / episodic / working in the manifest, making
  the cognitive-science framing explicit and machine-readable.

### Changed
- **Schema version bumped to 2.** Both vault types. v1 vaults still
  validate (backward-compatible), but new vaults are v2.
- `proposal.md` schema requires the new `## Predictions` section and
  `prediction_count` frontmatter field.
- `report.md` schema requires the new `## Verification` section and
  `predictions_correct`, `predictions_partial`, `predictions_wrong`
  frontmatter fields.
- `fact.md` schema adds `confirmation_count` and `last_confirmed`
  fields for CLS-style consolidation tracking.
- `install.sh` now also installs `validate-vault.sh` and
  `maintain-vault.sh` into the skill bin directory.
- `validate-vault.sh` accepts both schema_version 1 and 2; added
  `calibration` to the required project schemas.
- Hard rules grew from 16 to 20 (added rules for predictions,
  verification, calibration honesty, autonomous mode).

### Notes
- The whole point of v0.6 is to make agent behavior measurable. Every
  prediction goes into the calibration log. Every fact tracked across
  sessions for consolidation. No more "trust me" — there are now
  numbers behind every claim the skill makes.
- Backward compatibility: v1 vaults still validate and run, but they
  won't get the calibration features until they upgrade their schemas.
  No automatic migration is provided yet — manual edit or re-bootstrap.

## [0.5.0] — 2026-04-09

### Added
- **`bin/validate-vault.sh`** — verifies any vault is well-formed. Checks
  manifest schema_version, schema/example presence, frontmatter
  completeness on every note, valid `author:` values, and (for person
  vaults) presence of the `summary:` field and `_index.md`. Exit code 0
  if valid, 1 if any check fails.
- **`examples/person-pre-commit-hook.sh`** — symmetric to the project
  pre-commit hook. Rejects commits that modify `author: user` notes,
  modify existing `corrections/` files (corrections are append-only),
  or shrink `identity/basic.md` dramatically.
- **GitHub Actions CI** (`.github/workflows/validate.yml`) — runs
  `validate-vault.sh` against both skeletons and tests `rebuild-index.sh`
  on every push and PR. Verifies SKILL.md and README.md structural
  invariants.
- **CHANGELOG.md** (this file).
- **CONTRIBUTING.md** with concrete first-issue suggestions.

### Changed
- Project vault manifest now has explicit `scope: project` field (was
  implicit).

### Notes
- Both skeletons now pass validation with zero errors and zero warnings.

## [0.4.0] — 2026-04-09

### Added
- **Person vault** — a second vault scope (`COVAULT_PERSON`) for durable,
  per-human knowledge that follows the user across all projects and all
  agents. One per human, shared everywhere.
- **Six person-vault schemas**: `identity`, `preference`, `pattern`,
  `correction`, `context`, `index`.
- **Five person-vault examples** (one per non-index type) for the agent
  to pattern-match against.
- **`bin/rebuild-index.sh`** — deterministic, no-LLM script that walks
  the person vault, extracts the `summary:` field from each note's
  frontmatter, and rewrites `_index.md` grouped by folder. Warns if the
  index exceeds 200 lines.
- **PERSON LEARNING phase** in SKILL.md — runs after PHASE 4. The agent
  asks four questions (correction? preference? pattern? context change?)
  and only writes if the answer is durable + non-obvious + useful + not
  duplicate.
- **Token-efficiency design**: every person-vault note has a `summary:`
  field. The agent reads `_index.md` (~150 lines for 500 notes) and
  fetches detail files only on demand.
- **`install.sh --person`** flag to bootstrap a person vault.
- **README** sections explaining the two vault scopes and the token
  budget for large person vaults.

### Changed
- SKILL.md ACTIVATION now checks both `COVAULT_PATH` and `COVAULT_PERSON`.
- Hard rule count grew from 12 to 16 (added person-vault-specific rules).
- `install.sh` now also installs `bin/rebuild-index.sh` into the skill
  directory.

## [0.3.0] — 2026-04-09

### Added
- **Self-describing vault** — every vault now has a `.covault/` directory
  with a machine-readable `manifest.yaml`, schema files for each note
  type, and filled-in examples. The agent reads the manifest once per
  session and the relevant schema before each write.
- **Schema versioning** — `schema_version` field in the manifest. The
  skill refuses to operate on a vault with a mismatched schema version
  rather than silently corrupting it.
- **`examples/vault-skeleton/`** — full bootable vault skeleton with
  manifest, 7 schemas, 6 examples, starter index.md, and empty content
  folders with .gitkeep.
- New hard rule: never write a note without reading its schema first
  in the current session.

### Changed
- `install.sh` rewritten to copy the vault skeleton instead of inlining
  mkdir commands. Auto-fills `vault_name` in the manifest based on the
  directory name.
- `BOOTSTRAP` in SKILL.md now delegates to `install.sh` instead of
  recreating the structure inline.
- Phase announcements (`[co-vault: PHASE N/5 — NAME]`) became mandatory.
- Git commits after every phase write became mandatory.

## [0.2.0] — 2026-04-09

### Added
- **Phase announcements** — agent prints `[co-vault: PHASE N/5 — NAME]`
  at the start of every phase so the user always knows where it is.
- **Multi-domain task handling** — PHASE 1 ORIENT now processes a list of
  domains, not just one.
- **ABORT command** — user can say "abort", "stop", or "cancel" mid-task.
  Agent jumps to PHASE 4 with `status: aborted` and documents what was
  left undone.
- **Path hygiene rule** — agent must never read or write outside
  `$COVAULT_PATH` during the loop (except project code in PHASE 3).
- **Slug collision handling** — append `-2`, `-3`, ... if filename exists.

### Changed
- Replaced fragile `xargs` chains in PHASE 1 with `find ... | while read`
  loops that work with spaces and special characters in filenames.
- `co-vault review` REVIEW command output cleaned up; new check for
  notes unlinked from anywhere (archive candidates).

## [0.1.0] — 2026-04-09

### Added
- Initial release.
- 5-phase loop: ORIENT → PROPOSE → EXECUTE → REPORT → REQUEST_REVIEW.
- Author hierarchy with hard `user` immutability:
  `user` > `agent+reviewed` > `agent`.
- Hard conflict-stop on user-authored notes.
- `install.sh` one-shot installer.
- `examples/pre-commit-hook.sh` for git-layer enforcement.
- BOOTSTRAP command for new projects.
- Manual `co-vault review` command.
- README explaining the problem, the solution, and how it differs from
  Claude Code's built-in memory.
- MIT license.

[0.7.0]: https://github.com/Cosmic-Game-studios/co-vault/releases/tag/v0.7.0
[0.6.0]: https://github.com/Cosmic-Game-studios/co-vault/releases/tag/v0.6.0
[0.5.0]: https://github.com/Cosmic-Game-studios/co-vault/releases/tag/v0.5.0
[0.4.0]: https://github.com/Cosmic-Game-studios/co-vault/releases/tag/v0.4.0
[0.3.0]: https://github.com/Cosmic-Game-studios/co-vault/releases/tag/v0.3.0
[0.2.0]: https://github.com/Cosmic-Game-studios/co-vault/releases/tag/v0.2.0
[0.1.0]: https://github.com/Cosmic-Game-studios/co-vault/releases/tag/v0.1.0
