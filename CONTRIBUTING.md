# Contributing to co-vault

co-vault is small on purpose. The whole pitch is "your agent won't lie or
drift" — every feature added must reinforce that, never weaken it. The
bar for adding things is high.

This guide tells you what kinds of contributions are welcome, what aren't,
and how to make a PR likely to be merged.

## Philosophy — non-negotiable

Read these before opening any issue or PR. They're not just suggestions.

1. **No silent magic.** Anything that runs in the background without the
   user knowing is rejected on principle. The whole point of this project
   is auditability. If your feature needs to "just figure things out" or
   "automatically optimize", it doesn't belong here.

2. **The author hierarchy is sacred.** PRs that loosen the `user`
   immutability rule, add exceptions, or introduce a fourth authority
   level will not be merged. The hierarchy is the entire trust model.

3. **The vault is self-describing.** Schemas live in `.covault/schemas/`,
   not in SKILL.md. If you add a new note type, add a schema and an
   example for it. The agent should never need to memorize anything that
   isn't declared in the manifest.

4. **Token efficiency matters.** Person vault writes must be bounded:
   short notes, summary fields, on-demand loading. Project vault writes
   must commit and stay atomic. Anything that risks bloating context
   gets rejected.

5. **Test against a real agent.** Before opening a PR, run your changes
   through Claude Code (or your tool of choice) and confirm the agent
   actually behaves as documented. The most common reason a PR fails
   review is that it works in theory but the agent ignores it in practice.

## What's welcome

- **Cursor / Aider / other agent ports** of `SKILL.md`. The skill is just
  Markdown — port it to whatever rules format your tool uses, keeping the
  loop and authority rules intact.
- **Translations** of the README and SKILL.md (German, Spanish, French,
  Japanese, Chinese — anything).
- **Real-world example vaults** in `examples/` that show what a populated
  vault looks like in use.
- **Dataview query packs** for `index.md` (open conflicts, recent reports,
  stale proposals — the kind of dashboard you'd want in Obsidian).
- **CI improvements** — more validation checks, faster builds, better
  error messages from `validate-vault.sh`.
- **Documentation fixes** — typos, unclear examples, missing edge cases.
- **Bug reports with reproductions** — especially "I told the agent X
  and it did Y instead of Z" with the conversation transcript.

## What's not welcome

- **New note types just for the sake of it.** If your use case fits an
  existing schema with a new tag, prefer that.
- **Features that bypass the author hierarchy.**
- **Background daemons, auto-consolidation, "smart" merging, ML-based
  anything.** All of these introduce silent magic.
- **Token-expensive features** that add to per-session context without
  a clear payoff measurable in vault hygiene or behavior.
- **Renames or refactors of the manifest schema** without a clear v2
  migration path. Breaking the schema breaks every existing vault.

## Process

1. **Issues for ideas, PRs for fixes.** If you want to add a new feature,
   open an issue first so we can discuss whether it fits the philosophy.
   Don't write 800 lines of code and then find out it's against the rules.
2. **Small PRs.** One concept per PR. A PR that touches the schema,
   the SKILL.md loop, the README, and adds a new tool is too big — split it.
3. **Update the CHANGELOG.** Every PR adds a line under `[Unreleased]`
   in `CHANGELOG.md`.
4. **Run validation locally** before pushing:
   ```bash
   ./bin/validate-vault.sh examples/vault-skeleton
   ./bin/validate-vault.sh examples/person-vault-skeleton
   ./bin/rebuild-index.sh examples/person-vault-skeleton
   ```
   CI will run the same checks. Save yourself the round-trip.
5. **Be patient.** This is a side project. Reviews may take days, not
   hours.

## Good first contributions

- **Translate the README** into your language.
- **Add a new example vault** under `examples/<your-language-or-stack>/`
  showing what a populated vault looks like in your domain.
- **Improve `validate-vault.sh`** — add more checks, friendlier errors,
  exit code semantics.
- **Write a Dataview query** for one common task (e.g. "show me all
  decisions I made in the last 30 days") and add it to a new
  `examples/dataview-queries.md` file.
- **Cursor port**: take SKILL.md and produce `.cursorrules` equivalent
  with the loop, the author hierarchy, the schema lookup. Stash it under
  `examples/cursor/`.

## Code style

- Bash scripts: `set -euo pipefail` at the top, `shellcheck`-clean.
- Markdown: 80-column wrap where possible, no trailing whitespace.
- YAML: 2-space indent, no tabs, lowercase keys.
- Filenames: lowercase, hyphenated, descriptive.

## License

By contributing, you agree that your contributions will be licensed
under the MIT License (the project's license).

---

If you read this far and you're still interested: thank you. Open an
issue and say hi.
