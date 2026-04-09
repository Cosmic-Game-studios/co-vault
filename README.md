# co-vault

**A shared knowledge base between you and your AI coding agents — where your notes are law.**

co-vault is a [Claude Code](https://claude.com/claude-code) skill (also works with Cursor, Aider, or any agent that can read files) that turns an [Obsidian](https://obsidian.md) vault into a multiplayer memory system. You write decisions. Your agent writes plans, reports, and discovered facts. When the agent finds a contradiction between what it observed and what you decided, **it stops and asks you** instead of silently overwriting your knowledge.

> One vault. Many agents. One human in charge.

---

## The problem

If you've used AI coding agents on a real project for more than a week, you know this pain:

- **The agent forgets.** Every new session it re-explores the codebase, re-learns your conventions, re-suggests the dependency you already rejected.
- **The agent overrides you.** You decided last Tuesday "we use raw SQL, no ORM." Today the agent cheerfully suggests Prisma. Again.
- **The agent's memory is locked in.** Claude Code's memory lives in `~/.claude/`. Cursor's lives somewhere else. ChatGPT has its own. You can't share knowledge between tools, and you can't take it with you when a better agent comes out next month.
- **You can't see what it learned.** Auto-memory features write notes in the background. You only find out the agent "remembered" something wrong when it bites you.
- **Your decisions and the agent's guesses look the same.** A note saying "use refresh tokens" written by you (deliberate, after research) is indistinguishable from one written by the agent (a guess from a Stack Overflow snippet). The agent treats them as equally valid. They are not.

co-vault fixes all five.

---

## The idea in one picture

```
                    ┌─────────────────────────┐
                    │   Your Obsidian vault   │
                    │                         │
                    │   index.md  ◄─── you    │
                    │   decisions/ ◄── you    │  ← LAW. Agents can't edit.
                    │   facts/    ◄── agent   │  ← Agent observations.
                    │   proposals/◄── agent   │  ← Plans before action.
                    │   reports/  ◄── agent   │  ← What actually happened.
                    │   conflicts/◄── agent   │  ← BLOCKS work until you decide.
                    └────────────┬────────────┘
                                 │
                ┌────────────────┼────────────────┐
                ▼                ▼                ▼
          ┌──────────┐    ┌──────────┐    ┌──────────┐
          │  Claude  │    │  Cursor  │    │   You    │
          │   Code   │    │          │    │ (mobile, │
          │          │    │          │    │ desktop) │
          └──────────┘    └──────────┘    └──────────┘
```

The vault is just a folder of Markdown files. Anything that can read files can use it. You can edit it from your phone in bed.

---

## What makes it different from Claude Code's built-in memory

| | Claude Code Memory | co-vault |
|---|---|---|
| Storage location | `~/.claude/projects/<x>/memory/` | Anywhere — your vault folder |
| Who can write | Claude Code only | Any agent + you |
| Who can read | Claude Code only | Any agent + you, on any device |
| Authority model | Flat — every note is equal | Hierarchical — `user` > `agent+reviewed` > `agent` |
| Conflict handling | Agent silently merges (Auto-Dream) | Agent **stops** and asks |
| Consolidation | Background, automatic, opaque | Manual, user-triggered, auditable |
| Survives tool change | No | Yes — vault is yours |
| Works offline / on phone | No | Yes (Obsidian Mobile) |
| You can grep/query it | Limited | Full Markdown + Dataview + Obsidian graph |

co-vault is not a replacement for `CLAUDE.md`. They solve different problems. `CLAUDE.md` is *"how the agent should behave."* co-vault is *"what is true about this project, and what did the agent do today."*

---

## Quickstart (60 seconds)

```bash
# 1. Clone this repo and install the skill
git clone https://github.com/Cosmic-Game-studios/co-vault.git
mkdir -p ~/.claude/skills/co-vault
cp co-vault/SKILL.md ~/.claude/skills/co-vault/

# 2. Create a vault for your project
export COVAULT_PATH="$HOME/Vaults/my-project"

# 3. Start Claude Code in your project, then say:
#    "bootstrap co-vault"
#
# The agent will create the folder structure, an empty index.md,
# and the first git commit. You then edit index.md to fill in
# your stack, rules, and current focus.

# 4. (Optional) Open the vault in Obsidian to browse it visually
```

That's it. From now on, every task in this project goes through the loop.

---

## The loop

Every task the agent runs through these 5 phases. No skipping.

### 1. ORIENT
Before touching code, the agent reads `index.md` and greps the vault for `author: user` notes in the relevant domain. If it finds an open conflict, it stops.

### 2. PROPOSE
The agent writes a plan to `proposals/<timestamp>.md` — goal, steps, assumptions, what it will not touch — **before executing**. You see the plan first.

### 3. EXECUTE
The agent does the actual work. Git commits reference the proposal path so the codebase links back to the vault.

### 4. REPORT
The agent writes `reports/<timestamp>.md` — what actually happened, what differed from the plan, which assumptions were wrong. New observations become atomic notes in `facts/`.

### 5. REQUEST_REVIEW *(only if conflict)*
If the agent discovers something that contradicts a `user`-authored note, it **must not silently override it**. It opens `conflicts/<id>.md`, describes the contradiction, and stops working in that domain until you resolve it.

That fifth phase is where most agent memory systems fail. co-vault makes it the only thing that can block the loop.

---

## The author hierarchy (the trick that makes it work)

Every note has a `author:` field in its frontmatter. Three values:

| Value | Meaning | Agent rights |
|---|---|---|
| `user` | You wrote it | **Read-only.** Can cite, can link to. Cannot edit, cannot supersede. |
| `agent+reviewed` | Agent wrote it, you signed off | **Read-only.** Frozen until you unfreeze. |
| `agent` | Agent wrote it, unreviewed | Free to edit, supersede, archive. |

When something the agent observes contradicts a higher-authority note, the agent loses. It cannot rewrite history; it can only ask for the user to reconsider.

This is the entire conceptual core. Everything else in the SKILL.md is just bash and templates that enforce it.

---

## Real example

```
You:    Switch the auth layer to use refresh tokens.

Agent:  [reads index.md]
        [greps domain:auth, author:user]
        → finds decisions/2026-02-14-stateless-jwt.md

        I found a user-authored decision from Feb 14 that explicitly
        chose stateless JWT and rejected refresh tokens for this project.
        The reason given: "no server-side session store, deploys are
        stateless containers."

        Before I proceed, can you confirm this decision is being revised?
        Since that note is author: user, I cannot edit it myself —
        please update it, then I'll continue.

You:    Right, I forgot. The session store changed last week. I'll
        update the decision file now.

[you edit decisions/2026-02-14-stateless-jwt.md, set status: superseded]

You:    Done. Proceed.

Agent:  [writes proposals/2026-04-09-1430-refresh-tokens.md]
        Plan:
          1. Add refresh_tokens table migration
          2. ...
        Assumptions:
          - Redis is available (per index.md)
          - 7-day refresh token lifetime acceptable
        Will not touch: existing JWT signing logic.

        Confirm to proceed?
```

A normal agent would have just started writing refresh token code and contradicted your earlier architectural decision. co-vault made it stop and check.

---

## Vault structure

```
$COVAULT_PATH/
├── index.md          # entry point, hand-curated by you (author: user)
├── domains/          # one file per subsystem (you author)
├── decisions/        # immutable choices (you, or agent+reviewed)
├── facts/            # atomic observations (agent)
├── proposals/        # plans before action (agent)
├── reports/          # results after action (agent)
├── conflicts/        # OPEN questions blocking work
└── _archive/         # never delete, only move here
```

---

## FAQ

**How is this different from just using `CLAUDE.md`?**
`CLAUDE.md` is one file, loaded into context at session start, written by you. co-vault is many files, queried on-demand by the agent, written by both of you, with explicit ownership rules. Use both. They complement each other.

**Does the agent really obey the `author: user` rule?**
The skill is a strong instruction, not a hard enforcement. For real safety, add a pre-commit hook to your vault git repo that rejects commits modifying `author: user` files when the commit is made by an agent tool. A template hook is in `examples/pre-commit-hook.sh`.

**What if I want to use this with Cursor / Aider / something else?**
The SKILL.md is just Markdown. Drop it in whatever the agent reads as system instructions (Cursor rules, Aider conventions, etc.). The bash commands work in any POSIX shell.

**Will the vault become huge?**
That's what the manual `co-vault review` command is for. It surfaces stale proposals, missing reports, unlinked facts, and notes without frontmatter. You decide what gets archived. Nothing happens automatically.

**Why not auto-consolidate like Claude Code's Auto-Dream?**
Because auto-consolidation is what makes agent memory untrustworthy. If you can't tell whether a note is the result of a deliberate decision or a background merge, you can't rely on it. co-vault prefers explicit human review over invisible cleanup.

**Can I use Obsidian plugins?**
Yes, and you should. **Dataview** turns your vault into a queryable database. **Templater** gives you keyboard shortcuts for new notes. **Git** plugin commits your vault from inside Obsidian. None are required, all are recommended.

---

## Roadmap

- [ ] Pre-commit hook to enforce the `author: user` rule at the git layer
- [ ] Dataview query pack for `index.md` (open conflicts, recent reports, stale proposals)
- [ ] Cursor rules port
- [ ] Aider conventions port
- [ ] VS Code extension for one-key "promote to reviewed"
- [ ] Optional embedding-based retrieval as a fallback when grep misses

PRs welcome.

---

## License

MIT. Take it, fork it, change the name, ship it in your own product. If it helps you, a star on this repo is appreciated but not required.

---

## Credits

Built out of frustration with watching AI agents helpfully overwrite carefully-considered architectural decisions for the third time in a week. Inspired by the gap between Claude Code's `~/.claude/` memory and what I actually wanted: a shared notebook, not a private one.
