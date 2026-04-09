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
prediction_count: 4
---

## Goal
A working /login page that submits to the existing /api/auth endpoint
and stores the returned JWT in memory (not localStorage).

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

## Assumptions
- The /api/auth endpoint returns `{ token: string }` on success
- We use the existing form components in `src/components/forms/`
- Tailwind classes only, no new CSS

## Out of scope
- Password reset flow
- "Remember me" (forbidden by [[decisions/2026-02-14-stateless-jwt]])
- Server-side logout endpoint
