---
type: preference
author: agent
topic: response-length
summary: "Wants short answers for simple questions, detailed for design decisions"
confidence: high
last_confirmed: 2026-04-09
sources:
  - conversation: 2026-03-15
  - conversation: 2026-04-02
  - conversation: 2026-04-09
tags: [communication, response-style]
---

## Preference
For factual questions, the user wants 1-3 sentences max. For architecture
or design questions, they want full reasoning, alternatives, and tradeoffs.

## Examples
- "What's the capital of France?" → "Paris." (one word)
- "Should I use Postgres or MongoDB for this?" → full comparison with reasoning

## Counter-examples
When the user explicitly says "explain in detail" or "be brief", that
overrides the default heuristic.
