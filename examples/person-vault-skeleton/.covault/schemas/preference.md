# Schema: preference

How the person prefers things done. Agent-observed, user-correctable.

## Frontmatter — required
| field            | type   | values                                       |
|------------------|--------|----------------------------------------------|
| type             | string | `preference`                                 |
| author           | enum   | `agent` (default) \| `user` \| `agent+reviewed` |
| topic            | string | short topic key (e.g. `response-length`, `code-style-go`) |
| summary          | string | ONE line, used in index                      |
| confidence       | enum   | `low` \| `medium` \| `high`                  |
| last_confirmed   | date   | ISO date                                     |

## Frontmatter — optional
| field    | type   | meaning                                      |
|----------|--------|----------------------------------------------|
| sources  | list   | conversations where this was observed         |
| tags     | list   | cross-cutting search tags                     |
| context  | string | when this preference applies                  |

## Body
1. `## Preference` — one-line statement
2. `## Examples` — concrete examples of the preference in action
3. `## Counter-examples` — when the preference does NOT apply (if any)

Keep under 40 lines.
