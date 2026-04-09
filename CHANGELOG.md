# Changelog

All notable changes to co-vault are documented here.
The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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

[0.5.0]: https://github.com/Cosmic-Game-studios/co-vault/releases/tag/v0.5.0
[0.4.0]: https://github.com/Cosmic-Game-studios/co-vault/releases/tag/v0.4.0
[0.3.0]: https://github.com/Cosmic-Game-studios/co-vault/releases/tag/v0.3.0
[0.2.0]: https://github.com/Cosmic-Game-studios/co-vault/releases/tag/v0.2.0
[0.1.0]: https://github.com/Cosmic-Game-studios/co-vault/releases/tag/v0.1.0
