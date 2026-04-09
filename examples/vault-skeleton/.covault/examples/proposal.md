---
type: proposal
author: agent
status: pending
domain: auth, ui
created: 2026-04-09T14:30Z
task: "Add a login form with email and password fields"
references:
  - "[[decisions/2026-02-14-stateless-jwt]]"
  - "[[domains/auth]]"
estimated_effort: small
change_type: structural_addition
risk_level: medium
prediction_count: 4
---

## Goal
A working /login page that submits to the existing /api/auth endpoint
and stores the returned JWT in memory (not localStorage).

## Hypothesis
**What**: The existing `useAuth()` hook already handles token storage
and refresh, so the login form only needs to collect credentials and
call the hook — no new auth logic required.
**Why I believe this**: `domains/auth.md` documents the auth hook as
the single entry point, and `decisions/2026-02-14-stateless-jwt`
confirms tokens go in memory.
**Falsification**: If `useAuth()` doesn't expose a `login(email, password)`
method, I will need to add one, making this a larger change than planned.

## Plan
1. Create `src/pages/login.tsx` with form
2. Wire up to existing `useAuth()` hook
3. Add error states for 401 / network errors
4. Run existing test suite

## Predictions
- [P1] confidence: 90% — All existing tests will still pass after my changes.
- [P2] confidence: 70% — Total task time will be under 25 minutes.
- [P3] confidence: 85% — I will modify exactly these files: src/pages/login.tsx (new), src/lib/auth/use-auth.ts (modify).
- [P4] confidence: 60% — The /api/auth endpoint will return the response shape I expect (`{token: string}`).

## Alternatives considered
- **Server-side rendered login page**: Would avoid client-side token handling
  entirely. Rejected because: the project uses SPA architecture per
  `[[domains/ui]]`, and SSR would require a backend template engine we
  don't have.
- **Third-party auth widget (Auth0/Clerk)**: Would be faster to implement.
  Rejected because: `[[decisions/2026-02-14-stateless-jwt]]` specifies
  self-managed JWT, and adding a third-party dependency contradicts
  the project's auth architecture.

## Assumptions
- The /api/auth endpoint returns `{ token: string }` on success
- We use the existing form components in `src/components/forms/`
- Tailwind classes only, no new CSS

## Out of scope
- Password reset flow
- "Remember me" (forbidden by [[decisions/2026-02-14-stateless-jwt]])
- Server-side logout endpoint
