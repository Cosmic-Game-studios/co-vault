---
type: pattern
author: agent
topic: prompt-style-direct
summary: "Skips greetings, often asks questions without context, expects inference"
confidence: high
observed_count: 47
last_observed: 2026-04-09
---

## Pattern
The user typically writes terse, context-free prompts. They expect the
agent to infer scope from prior conversation or to ask one focused
clarifying question rather than guess.

## Observations
- 2026-03-15: "fix the bug" with no further context (was about an earlier file)
- 2026-04-02: "make it faster" referring to a function discussed yesterday
- 2026-04-09: "what about edge cases" with no specified subject

## Implication for agent behavior
- Look at the most recent topic in conversation as the implicit subject
- If two interpretations exist, ask one clarifying question (not three)
- Do NOT interpret terseness as rudeness or impatience
