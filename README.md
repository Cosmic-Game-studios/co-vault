# co-vault

> **A shared knowledge base between you and your AI coding agents — where your notes are law.**

![status: alpha](https://img.shields.io/badge/status-alpha-orange) ![license: MIT](https://img.shields.io/badge/license-MIT-blue) ![works with: Claude Code, Cursor, Aider](https://img.shields.io/badge/works%20with-Claude%20Code%20%C2%B7%20Cursor%20%C2%B7%20Aider-purple)

---

## TL;DR

Your AI coding agent forgets everything between sessions. The memory features that exist (Claude Code's `~/.claude/`, Cursor rules, etc.) are private to that one tool, can be silently overwritten, and treat your hard-won decisions as equal to the agent's first-draft guesses.

co-vault is a [Claude Code](https://claude.com/claude-code) skill that turns [Obsidian](https://obsidian.md) folders into **two kinds of multiplayer memory**:

- 🗂️ **Project vault** — facts, decisions, and history about one specific project. One per project.
- 👤 **Person vault** — durable knowledge about *you* (how you prompt, what you prefer, what you've corrected the agent on). One per human, shared across **all** your projects and **all** your agents.

Both are just folders of Markdown:

- 📂 **One folder of Markdown** — works on any OS, any agent, any device.
- 🧠 **Self-describing vaults** — manifest + schemas live next to the data, so any LLM can pick it up without prior knowledge.
- 🔒 **Your notes are immutable** — agents can read them, cite them, but never edit them.
- 🛑 **Conflicts stop the agent** — when its observations contradict your decisions, it asks instead of overwriting.
- 🔁 **5-phase loop on every task** — ORIENT → PROPOSE → EXECUTE → REPORT → REQUEST_REVIEW. No silent steps.
- 🔌 **Tool-agnostic** — works with Claude Code today, Cursor/Aider/anything-with-files tomorrow.

If you've ever yelled at your AI for the third time in a week *"I told you we don't use Prisma"*, this is for you.

---

## The problem, in five concrete pains

If you've used AI coding agents on a real project for more than a week, you've felt these:

1. **The agent forgets.** New session, blank slate. It re-explores the codebase, re-suggests the dependency you already rejected, re-asks about your conventions.
2. **The agent overrides you.** Tuesday: you decide *"raw SQL only, no ORM."* Thursday: the agent cheerfully proposes Prisma. Again.
3. **Memory is locked into one tool.** Claude Code's lives in `~/.claude/`. Cursor's lives somewhere else. ChatGPT has its own. You can't share knowledge between agents, and you lose it when a better one ships next month.
4. **You can't see what the agent learned.** Auto-memory writes notes silently. You only find out it "remembered" something wrong when it bites you.
5. **Your decisions and the agent's guesses look the same.** A note saying "use refresh tokens" written by you (deliberate, after research) is indistinguishable from one written by the agent (a guess from a Stack Overflow snippet). The agent treats them as equally valid. They are not.

co-vault fixes all five.

---

## The idea in one picture

```
                    ┌─────────────────────────┐
                    │   Your Obsidian vault   │
                    │                         │
                    │   index.md   ◄── you    │ ◄── LAW. Agents can't edit.
                    │   decisions/ ◄── you    │
                    │   facts/     ◄── agent  │ ◄── Atomic observations.
                    │   proposals/ ◄── agent  │ ◄── Plans before action.
                    │   reports/   ◄── agent  │ ◄── What actually happened.
                    │   conflicts/ ◄── agent  │ ◄── BLOCKS work until you resolve.
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

The vault is just a folder of Markdown files. Anything that can read files can use it. You can edit it from your phone in bed, push it to a private GitHub repo, or hand it to a teammate.

---

## How a co-vault note actually looks

This is the entire trick. Every note has an `author:` field in its frontmatter:

**A user-authored decision (immutable to agents):**
```markdown
---
type: decision
author: user
domain: auth
created: 2026-02-14T09:30Z
---

## Decision
We use stateless JWT, 15-minute access tokens, no refresh tokens.

## Why
Deploys are stateless containers. No server-side session store.
Refresh tokens would require Redis, which we explicitly don't want
in this project.

## Status
active
```

**An agent-authored fact (the agent can edit this freely):**
```markdown
---
type: fact
author: agent
domain: auth
created: 2026-04-09T14:32Z
discovered_in: "[[reports/2026-04-09-1430-add-login-ui]]"
confidence: high
---

## Claim
The /login endpoint returns 401 instead of 403 for unknown users,
which leaks user existence.

## Evidence
Tested with curl against the dev environment. See report for full trace.

## Implication
Should return 401 for both cases. See [[decisions/2026-02-14-stateless-jwt]].
```

**An agent fact that has been promoted by you (now immutable):**
```markdown
---
type: fact
author: agent+reviewed
reviewed_by: ronald
reviewed_at: 2026-04-10
---
```

The `author:` field is the entire authority system. When the agent reads a note, it knows whether it can modify it (`agent`) or only cite it (`user` / `agent+reviewed`).

---

## Two vault scopes: project + person

co-vault has two distinct kinds of vault. They use the same machinery (manifest, schemas, examples, author hierarchy) but solve different problems.

### Project vault (`COVAULT_PATH`)

One per project. Lives wherever you want — usually `~/Vaults/<project-name>/`.

Stores: decisions, facts, proposals, reports, conflicts, domains. Everything that is true about *that one codebase*. Cleared when the project ends.

Workflow: the 5-phase loop runs on every task. The agent reads the project vault before touching code, writes a proposal, executes, reports, and surfaces conflicts.

### Person vault (`COVAULT_PERSON`)

**One per human.** Lives in `~/.covault/person/` by default. **Shared across every project you ever work on, with every agent you ever use.**

Stores: identity, preferences, patterns, corrections, context. Everything the agent learns about *you* — how you prompt, what tone you want, what you've corrected the agent on, which technical preferences are stable across all your projects.

Workflow: loaded once per session. The agent reads the index (small), all corrections (priority), and your basic identity. It fetches specific preference/pattern/context files only when relevant to the current task. After every meaningful task, it asks itself *"did I learn anything durable about the user?"* — if yes, it writes a new note and rebuilds the index.

```
~/.covault/person/
├── .covault/
│   ├── manifest.yaml         # scope: person, schema_version: 1
│   ├── schemas/              # 6 schemas: identity, preference, pattern, correction, context, index
│   └── examples/             # 5 filled-in examples
├── _index.md                 # auto-rebuilt by bin/rebuild-index.sh
├── identity/                 # who you are (mostly user-authored)
├── preferences/              # how you like things (agent-observed)
├── patterns/                 # how you actually work (agent-observed)
├── corrections/              # things the agent got wrong (priority loaded)
├── context/                  # life/work context (job, projects)
└── _archive/
```

### Why split them?

Because they have completely different lifecycles, sizes, and trust models.

A project vault is small and bounded — it dies when the project does. A person vault grows over years and follows you between tools. A project vault is mostly user-authored (your decisions are law). A person vault is mostly agent-authored (the agent observes, you correct). Mixing them would mean the agent's casual observations about your prompt style would sit next to your hard architectural decisions for a specific project — and one of the two would inevitably contaminate the other.

### How they work together

When you start a new task in a project, both vaults activate:

1. **Session start**: agent loads person vault index, all corrections, and your identity. ~3000 tokens.
2. **Per task**: agent runs the 5-phase loop on the project vault as normal. During PHASE 1 (ORIENT), it also greps the person vault index for hits matching the current task's domain — if it finds any, it loads those specific preference/pattern files.
3. **End of task**: agent runs PERSON LEARNING — did I learn anything new about the user during this task? If yes, write to the person vault and rebuild the index. If no, do nothing.

The result: every project benefits from everything the agent has ever learned about you, without any project's specifics leaking into other projects.

### Token efficiency for large person vaults

The person vault is designed to grow without burning context:

- **Every note has a `summary:` field** in its frontmatter — one line describing the note's content.
- **The `_index.md` is auto-rebuilt** after every write. It lists every note with its summary, grouped by folder. A vault with 500 notes produces an index of ~150 lines.
- **The agent reads the index, not the notes.** Only when the index suggests a hit does it `cat` a specific file.
- **Notes are bounded**: 30–50 lines max per note. One topic per file.
- **Stale notes decay**: REVIEW surfaces notes that haven't been confirmed in 180+ days. You decide whether to refresh, archive, or delete.
- **Total session overhead**: ~3000 tokens for the bulk-loaded parts (manifest + index + corrections + identity), plus ~500–1500 tokens for the on-demand lookups during a task. Acceptable even for vaults with hundreds of notes.

---

## The science behind co-vault

Every design decision in v0.6 maps to a peer-reviewed concept from cognitive science. This is not buzzword garnish — each citation corresponds to a concrete mechanism in the loop.

| Concept | Citation | How co-vault uses it |
|---|---|---|
| **Memory systems theory** | Tulving 1972; Squire 2004 | Vault folders are explicitly tagged in the manifest as `procedural` (`schemas/`), `semantic` (`facts/`, `decisions/`, `domains/`), or `episodic` (`proposals/`, `reports/`, `conflicts/`). Storage strategy mirrors how human memory is organized. |
| **Predictive coding** | Friston 2010; Clark 2013 | Every proposal must contain `## Predictions` — minimum 3 testable claims with confidence values. Without explicit predictions there is no measurable learning signal. The agent builds a generative model, then measures prediction error in the matching report. |
| **Active inference** | Friston 2017 | The proposal's `## Assumptions` section makes hidden beliefs explicit so they can be tested. The agent doesn't just react — it commits to claims and checks them. |
| **Complementary Learning Systems** | McClelland, McNaughton, O'Reilly 1995 | Two-stage consolidation: new agent observations start as `author: agent` (fast, mutable). After 3+ confirmations across sessions, `bin/maintain-vault.sh` auto-promotes them to `author: agent+reviewed` (immutable). This mirrors hippocampus → neocortex transfer. |
| **Brier scoring** | Brier 1950; Tetlock 2015 | The `calibration_log.md` tracks how well-calibrated the agent's prediction confidence is over time. A Brier-like score (lower = better) is recomputed after every report. The agent reads this on session start to ground future confidence values. |
| **Ebbinghaus forgetting curve** | Ebbinghaus 1885 | Notes whose `last_confirmed` is older than 30 days have their confidence downgraded one step (high → medium → low). Knowledge that isn't refreshed loses reliability — same as in human memory. |
| **Working memory limits** | Miller 1956 (7±2); Cowan 2001 (4±1) | Hard token budget per session, hard limit on simultaneously loaded notes. The vault is queried via small indexes, not bulk reads. |
| **Dual-process theory** | Kahneman 2011 | `estimated_effort: small` proposals proceed automatically (System 1). `medium` and `large` require explicit user confirmation (System 2). |
| **Distributed cognition** | Hutchins 1995 | The vault IS distributed cognition — the human, the agent, and the artifact (Markdown files) form a single cognitive system. The author hierarchy makes the division of labor explicit. |
| **Schema theory** | Bartlett 1932; Piaget 1952 | The 6-phase loop is itself a schema: minor observations are assimilated into existing facts (`confirmation_count++`); contradictions trigger accommodation (a `conflict` note that blocks work until restructured). |

**The 6-phase loop, mapped:**

```
PHASE 1 ORIENT       → situated perception (Hutchins)
PHASE 2 HYPOTHESIZE  → generative model with predictions (Friston)
PHASE 3 EXECUTE      → motor action
PHASE 4 VERIFY       → prediction error checking (Bayesian updating)
PHASE 5 CONSOLIDATE  → memory consolidation (McClelland CLS)
PHASE 6 REVIEW       → executive control / accommodation (only on conflict)
```

Each phase writes structured data that feeds the next. Each phase has a measurable output. None of this is metaphor — predictions get verdicts, verdicts feed the calibration log, the calibration log changes future confidence values. It is a closed loop with a real learning signal.

---

## What makes this different from everything else

| | Claude Code Memory | Cursor Rules | RAG / Vector DB | MCP Memory Tool | **co-vault** |
|---|---|---|---|---|---|
| Storage | `~/.claude/` | `.cursorrules` | Embedding store | API-managed | Your folder |
| Who can write | Claude only | You only | Indexer | Agent only | **You + any agent** |
| Cross-tool | ❌ | ❌ | Sometimes | One protocol | ✅ |
| You can edit on phone | ❌ | Manual | ❌ | ❌ | ✅ via Obsidian Mobile |
| Authority hierarchy | Flat | N/A (static) | Flat | Flat | ✅ `user` > `agent+reviewed` > `agent` |
| Conflict handling | Silent merge (Auto-Dream) | N/A | Top-K wins | Agent decides | ✅ Agent **stops** |
| Auditable changes | Limited | Yes (git) | ❌ | ❌ | ✅ Full git history |
| Survives tool change | ❌ | ❌ | Maybe | ❌ | ✅ |
| Setup cost | None | Low | High | Medium | Low (60s) |

co-vault is **not a replacement** for `CLAUDE.md` / `.cursorrules`. They solve different problems:
- `CLAUDE.md` / `.cursorrules` = *"how the agent should behave"* (style, conventions, always loaded)
- co-vault = *"what is true about this project, and what did the agent do today"* (facts, decisions, history, queried on demand)

Use both.

---

## Quickstart — 60 seconds

```bash
# 1. Clone this repo
git clone https://github.com/Cosmic-Game-studios/co-vault.git
cd co-vault

# 2a. Bootstrap a project vault (one per project)
./install.sh ~/Vaults/my-project
export COVAULT_PATH="$HOME/Vaults/my-project"

# 2b. Bootstrap a person vault (one per human, shared across all projects)
./install.sh --person ~/.covault/person
export COVAULT_PERSON="$HOME/.covault/person"

# 3. Edit the seed files
#    - $COVAULT_PATH/index.md       — your project's stack, rules, focus
#    - $COVAULT_PERSON/identity/basic.md  — who you are

# 4. Add the env vars to ~/.zshrc or ~/.bashrc so they persist

# 5. Start Claude Code in your project. Both vaults activate automatically.
```

That's it. The project vault gates every task through the 5-phase loop. The person vault loads on session start and learns about you over time.

---

## The loop, step by step

The agent runs every task through these 5 phases. It announces each phase out loud (`[co-vault: PHASE 2/5 — PROPOSE]`), so you always know where it is.

### 1. ORIENT
Reads `index.md`, greps the vault for `author: user` notes in the relevant domain, and checks for open conflicts. **If anything you wrote contradicts the task, it stops and asks you.**

### 2. PROPOSE
Writes a plan to `proposals/<timestamp>.md` — goal, steps, assumptions, what it will not touch. For non-trivial tasks, it waits for your confirmation. **You see the plan first.**

### 3. EXECUTE
Does the actual work. Project commits reference the proposal path so the codebase links back to the vault.

### 4. REPORT
Writes `reports/<timestamp>.md` — what actually happened, what differed from the plan, which assumptions were wrong. New observations become atomic notes in `facts/`.

### 5. REQUEST_REVIEW *(only if a conflict was discovered)*
If during execution it found something that contradicts a `user` note, it **does not silently override**. It opens `conflicts/<id>.md`, describes the contradiction, and stops working in that domain until you resolve it.

That last phase is where most agent memory systems fail. co-vault makes it the only thing that can block the loop.

---

## Real example

```
You:    Switch the auth layer to use refresh tokens.

Agent:  [co-vault: PHASE 1/5 — ORIENT]
        Reading index.md...
        Grepping author: user notes in domain: auth...
        → Found decisions/2026-02-14-stateless-jwt.md

        I found a user-authored decision from Feb 14 that explicitly chose
        stateless JWT and rejected refresh tokens for this project. The
        reason given: "no server-side session store, deploys are stateless
        containers."

        Before I proceed, can you confirm this decision is being revised?
        Since that note is author: user, I cannot edit it myself —
        please update it, then I'll continue.

You:    Right, I forgot. The session store changed last week. I'll
        update the decision file now.

[you edit decisions/2026-02-14-stateless-jwt.md, set status: superseded]

You:    Done. Proceed.

Agent:  [co-vault: PHASE 2/5 — PROPOSE]
        Writing proposals/2026-04-09-1430-refresh-tokens.md...

        Plan:
          1. Add refresh_tokens table migration
          2. Add /auth/refresh endpoint
          3. Update client SDK to handle 401 → refresh → retry
        Assumptions:
          - Redis is available (per index.md)
          - 7-day refresh token lifetime acceptable
        Out of scope: existing JWT signing logic.
        Estimated effort: medium

        Confirm to proceed?
```

A normal agent would have just started writing refresh-token code and contradicted the architectural decision from two months ago. co-vault made it stop and check.

---

## Vault structure (self-describing)

```
$COVAULT_PATH/
├── .covault/                    # ← machine-readable schema, read by agents
│   ├── manifest.yaml            # version, folders, conventions, loop definition
│   ├── schemas/
│   │   ├── decision.md          # frontmatter + body schema for each note type
│   │   ├── fact.md
│   │   ├── proposal.md
│   │   ├── report.md
│   │   ├── conflict.md
│   │   ├── domain.md
│   │   └── index.md
│   └── examples/                # filled-in instances the agent pattern-matches
│       └── (one per note type)
├── index.md                     # entry point, hand-curated by you (author: user)
├── domains/                     # one file per subsystem (you author)
├── decisions/                   # immutable choices (you, or agent+reviewed)
├── facts/                       # atomic observations (agent)
├── proposals/                   # plans before action (agent)
├── reports/                     # results after action (agent)
├── conflicts/                   # OPEN questions blocking work
└── _archive/                    # never delete, only move here
```

### Why `.covault/` exists — the vault is self-describing

Most agent-memory systems force the agent to memorize file layouts and
field names from documentation. co-vault inverts this: the vault declares
its own structure in a machine-readable manifest, and every note type has
a schema and an example the agent can load on demand.

This means:

- **One read = full schema knowledge.** The agent reads
  `.covault/manifest.yaml` once on session start and knows every folder,
  every note type, every required field, every convention.
- **Versioned.** The manifest has a `schema_version`. If the agent and the
  vault disagree on the version, the agent refuses to operate instead of
  silently corrupting your data.
- **Pattern-matchable.** Before writing any note, the agent reads
  `.covault/schemas/<type>.md` and `.covault/examples/<type>.md`. It
  copies the example structure and fills it in. No invented fields.
- **Tool-agnostic by construction.** Any LLM that can read YAML and
  Markdown can use this vault. The schema is not hidden in a SKILL.md
  somewhere; it lives next to the data.
- **Forward compatible.** When the schema evolves to v2, you bump
  `schema_version`, write a migration, and old agents either upgrade or
  refuse — they never quietly do the wrong thing.

---

## Hard enforcement (optional but recommended)

The skill is a strong instruction, not a hard guarantee. For real safety, use the included pre-commit hook in your vault's git repo:

```bash
cp examples/pre-commit-hook.sh $COVAULT_PATH/.git/hooks/pre-commit
chmod +x $COVAULT_PATH/.git/hooks/pre-commit
```

This rejects any commit that modifies a file with `author: user`, unless the commit message contains `[user-edit]`. If an agent ever tries to silently override one of your decisions, the commit fails and you find out immediately.

---

## FAQ

**How is this different from `CLAUDE.md` / `.cursorrules`?**
Those define *how the agent behaves* (style, conventions, always loaded into context). co-vault defines *what is true about your project and what the agent has been doing*. They complement each other. Use both.

**Will the agent really obey the `author: user` rule?**
The skill is a strong instruction, not hard enforcement. For real guarantees, use the pre-commit hook (above). It enforces the rule at the git layer where instructions can't lie.

**Doesn't this just become CLAUDE.md with extra steps?**
No — three differences. First, `CLAUDE.md` is one file loaded once at session start; co-vault is many files queried on demand based on the current task. Second, `CLAUDE.md` is written only by you; co-vault is co-authored with explicit ownership. Third, `CLAUDE.md` has no concept of conflict — co-vault stops the agent when its observations clash with your decisions.

**Will the vault grow forever?**
That's what the manual `co-vault review` command is for. It surfaces stale proposals, missing reports, unlinked facts, notes without frontmatter, and archive candidates. You decide what gets archived. **Nothing happens automatically** — that's a deliberate choice, because silent consolidation is what makes agent memory untrustworthy.

**Can I use this with Cursor / Aider / something else?**
Yes. The `SKILL.md` is just Markdown — drop it into whatever the agent reads as system instructions. The bash commands work in any POSIX shell. Cursor/Aider ports are on the roadmap.

**Why not just use a vector DB or RAG?**
Vector retrieval is great for finding *similar* content, terrible for enforcing *authority*. There is no embedding that says "this fact came from the human and must not be overridden." co-vault is not about retrieval quality; it's about respecting human decisions. Use both if you want.

**Can I use Obsidian plugins?**
Yes, and you should. **Dataview** turns your vault into a queryable database. **Templater** gives you keyboard shortcuts for new notes. **Git** plugin commits from inside Obsidian. None are required, all are recommended.

**What about teams?**
Each developer points `COVAULT_PATH` at the same shared git repo. The pre-commit hook keeps everyone honest. Conflicts that span developers' decisions become normal git merge conflicts plus co-vault `conflicts/` notes — explicit, discussable, reviewable.

---

## Roadmap

- [x] 5-phase loop with phase announcements
- [x] **6-phase loop grounded in cognitive science** (predictive coding, CLS, Brier scoring)
- [x] **Predictions + verification on every task** for measurable calibration
- [x] **Auto-maintenance** (decay, promotion, archival, calibration) — zero manual pflege
- [x] **Autonomous mode** with hard branch / token / sub-task limits
- [x] **Dataview query pack** for live Obsidian dashboards
- [x] Author hierarchy with hard `user` immutability
- [x] Self-describing vault (`.covault/manifest.yaml` + schemas + examples)
- [x] Schema versioning with refusal-on-mismatch
- [x] **Person vault (cross-project, cross-agent)** with auto-rebuilt index
- [x] Token-efficient loading (index + on-demand fetch, not bulk)
- [x] PERSON LEARNING phase after each task
- [x] Pre-commit hook for git-layer enforcement (project + person)
- [x] Manual REVIEW command (project + person)
- [x] BOOTSTRAP for new projects and new person vaults
- [x] ABORT command for mid-task cancellation
- [x] Validation script + GitHub Actions CI
- [ ] Cursor `.cursorrules` port
- [ ] Aider conventions port
- [ ] Dataview query pack for `index.md` (open conflicts, recent reports, stale proposals)
- [ ] VS Code extension for one-key "promote to reviewed"
- [ ] Optional embedding-based retrieval as a fallback when grep misses

PRs welcome. See [Contributing](#contributing) below.

---

## Contributing

This project is small on purpose. Before opening a PR:

1. **Issues for ideas, PRs for fixes.** If you want to add a new feature, open an issue first so we can discuss whether it fits the philosophy. The bar for adding things is high — co-vault stays small or it stops being trustworthy.
2. **No silent magic.** Anything that runs in the background without the user knowing is rejected on principle. The whole point of this project is auditability.
3. **Test your changes against a real agent.** Run the SKILL.md through Claude Code (or your tool of choice) and confirm it actually behaves as documented.
4. **The author hierarchy is sacred.** PRs that loosen the `user` immutability rule will not be merged.

Good first contributions:
- Cursor / Aider port of `SKILL.md`
- Dataview queries for `index.md`
- Translations of the README
- Real-world examples in `examples/`

---

## Status

🚧 **Alpha.** The interface (frontmatter fields, phase names, file layout) may change before v1.0. Pin a commit if you're using this in production.

If you find a bug, an unclear instruction, or a way the agent misbehaves against the SKILL.md, please open an issue with the conversation transcript. The most valuable feedback is "I told it X and it did Y instead of Z."

---

## License

MIT. Take it, fork it, change the name, ship it in your own product. If it helps you, a star on this repo is appreciated but not required.

---

## Credits

Built out of frustration with watching AI agents helpfully overwrite carefully-considered architectural decisions for the third time in a week. Inspired by the gap between Claude Code's `~/.claude/` memory and what I actually wanted: a shared notebook, not a private one.

If co-vault saves you from one bad refactor, it has paid for itself.

---

<sub>If you found this useful, consider starring the repo — it helps other people find it. And if you build something on top, I'd love to see it.</sub>
