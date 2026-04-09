# Schema: context

Life and work context that affects collaboration. More changeable than
identity, more durable than ephemeral conversation state.

## Frontmatter — required
| field            | type   | values                              |
|------------------|--------|-------------------------------------|
| type             | string | `context`                           |
| author           | enum   | `agent` \| `user` \| `agent+reviewed` |
| topic            | string | short topic key                     |
| summary          | string | ONE line, used in index             |
| valid_from       | date   | ISO date when this became true       |
| last_confirmed   | date   | ISO date of last confirmation       |

## Frontmatter — optional
| field        | type | meaning                                |
|--------------|------|----------------------------------------|
| valid_until  | date | ISO date when this stops being true    |
| tags         | list | cross-cutting search tags              |

## Body
Whatever context the agent needs. Keep under 40 lines.
When `valid_until` passes, the note auto-archives on next REVIEW.
