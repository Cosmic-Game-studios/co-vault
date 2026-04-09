# Schema: identity

Stable facts about who the person is. Changes rarely. Mostly user-authored.

## Frontmatter — required
| field            | type   | values                              |
|------------------|--------|-------------------------------------|
| type             | string | `identity`                          |
| author           | enum   | `user` (default) \| `agent` \| `agent+reviewed` |
| topic            | string | short topic key (e.g. `basic`, `languages`, `role`) |
| summary          | string | ONE line, used in index             |
| confidence       | enum   | `low` \| `medium` \| `high`         |
| last_confirmed   | date   | ISO date of last confirmation       |

## Frontmatter — optional
| field    | type | meaning                                       |
|----------|------|-----------------------------------------------|
| sources  | list | references to where this was learned          |
| tags     | list | cross-cutting search tags                     |

## Body
Keep under 30 lines. One topic per file. If a topic grows large, split it.
