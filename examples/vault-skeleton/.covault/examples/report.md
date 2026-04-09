---
type: report
author: agent
status: done
proposal: "[[proposals/2026-04-09-1430-add-login-ui]]"
domain: auth, ui
change_type: structural_addition
created: 2026-04-09T15:17Z
duration_min: 47
new_facts:
  - "[[facts/2026-04-09-login-leaks-user-existence]]"
anti_patterns_found: 0
hypothesis_verdict: confirmed
predictions_correct: 2
predictions_partial: 1
predictions_wrong: 1
---

## What actually happened
Created `src/pages/login.tsx` and wired it to `useAuth()`. The form
works as planned. While testing, I noticed the API returns different
status codes for unknown users vs wrong passwords — created a fact note.

I did NOT fix the status code issue because that's a backend change
outside the proposal scope.

## Verification
- [P1] correct: All 47 tests passed on first run.
- [P2] wrong: Task took 47 minutes, predicted under 25 (off by ~90%).
  Reason: I underestimated the time for setting up the network error states.
- [P3] partial: Touched login.tsx and use-auth.ts as predicted, but ALSO
  had to update src/middleware/require-auth.ts to handle a new edge case.
- [P4] correct: The endpoint returned `{token: string}` exactly as expected.

## Hypothesis verdict
**Verdict**: confirmed
**Evidence**: `useAuth()` did expose a `login(email, password)` method as
hypothesized. No new auth logic was needed — just the form and wiring.
**Model update**: The auth hook abstraction is reliable and well-documented.
Future auth-related UI tasks can safely assume the hook is the single
entry point.

## Assumptions verdict
- API returns `{ token }` on success: confirmed
- Existing form components usable: confirmed
- Tailwind only, no new CSS: confirmed

## Reflection
**Surprises**: The middleware file `require-auth.ts` needed changes — I did
not predict this at all. The middleware had a hardcoded redirect to `/login`
but the route didn't exist yet, causing a test to fail until I added the page.
**Causal error analysis**: P2 (time estimate) was wrong because I assumed
network error states would be simple. The actual complexity came from the
UX requirement to distinguish between 401 (wrong password), network timeout,
and 5xx errors — three states instead of two. P3 was partial because I
didn't trace the `login` route through the middleware layer during ORIENT.
**Model update**: For UI tasks that add new routes, I should check the
middleware chain during ORIENT — route-dependent middleware is a hidden
coupling. Time estimates for UI with error states should add 50% buffer.
**Anti-patterns**: None discovered in this task.

## Follow-ups
- [ ] Backend should return identical 401 for both auth failures
- [ ] Add rate limiting to /api/auth (separate task)
- [ ] My time estimates for UI work are systematically too optimistic
      (P2 was wrong; check calibration_log.md for the trend)
