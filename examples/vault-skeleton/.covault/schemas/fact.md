# Schema: fact (v3)

A `fact` is an atomic observation about the system. **One claim per file.**

Facts go through a CLS-style consolidation process:
- New facts start with `author: agent` and `confirmation_count: 1`
- Each time the agent re-observes the same fact, it increments the count
- When `confirmation_count >= 3`, `bin/maintain-vault.sh` auto-promotes
  the fact to `author: agent+reviewed` (becomes immutable)
- The user can also manually promote a fact at any time

This mirrors the hippocampus → neocortex transfer in human memory
(McClelland 1995): rapidly-acquired observations become slow,
stable knowledge only after repeated confirmation.

## Fact types (new in v3)

Facts come in two flavors, distinguished by `pattern_type`:

- **observation** (default) — something that IS true about the system
- **anti-pattern** — an approach that was TRIED and FAILED, and should
  not be repeated. Inspired by DeepResearch's knowledge base system
  which tracks failed approaches to prevent wasted effort.

Anti-patterns are loaded during PHASE 1 ORIENT (Step 1b) to inform
the agent's reasoning before it proposes any changes.

## Frontmatter — required
| field                | type     | values                                |
|----------------------|----------|---------------------------------------|
| type                 | string   | `fact`                                |
| author               | enum     | `agent` \| `agent+reviewed` \| `user` |
| domain               | string   | one of the active domains             |
| pattern_type         | enum     | `observation` \| `anti-pattern` (default: `observation`) |
| created              | string   | UTC timestamp                         |
| confidence           | enum     | `low` \| `medium` \| `high`           |
| confirmation_count   | integer  | how many times this has been re-observed (starts at 1) |
| last_confirmed       | string   | UTC timestamp of most recent confirmation |

## Frontmatter — optional
| field          | type     | meaning                               |
|----------------|----------|---------------------------------------|
| discovered_in  | wikilink | the report this fact came from        |
| superseded_by  | wikilink | newer fact that replaces this one     |
| vitality       | float    | computed by maintainer: count / days_since_last_confirmed |

## Body sections — required (observation facts)
1. `## Claim` — ONE sentence stating the fact
2. `## Evidence` — how it was observed, concretely
3. `## Implication` — what changes for future work

## Body sections — required (anti-pattern facts)
1. `## Claim` — ONE sentence stating what does NOT work and in what context
2. `## Evidence` — what happened when it was tried (link to the report)
3. `## Instead` — what worked instead, or what should be tried next

## Atomicity rule
If the body contains two or more independent claims, split it into two
files. The agent must enforce this on every write.

## Anti-pattern lifecycle
Anti-patterns follow the same CLS consolidation as observations:
- First failure: `confirmation_count: 1`, `confidence: medium`
- Repeated failures: increment `confirmation_count`
- At 3+ confirmations: auto-promoted to `agent+reviewed` (permanent)
- User can override an anti-pattern by writing a decision note that
  explicitly states the approach should be used despite past failures.
