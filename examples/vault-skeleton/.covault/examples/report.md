---
type: report
author: agent
status: done
proposal: "[[proposals/2026-04-09-1430-add-login-ui]]"
domain: auth, ui
created: 2026-04-09T15:17Z
duration_min: 47
new_facts:
  - "[[facts/2026-04-09-login-leaks-user-existence]]"
---

## What actually happened
Created `src/pages/login.tsx` and wired it to `useAuth()`. The form
works as planned. While testing, I noticed the API returns different
status codes for unknown users vs wrong passwords — created a fact note.

I did NOT fix the status code issue because that's a backend change
outside the proposal scope.

## Assumptions verdict
- API returns `{ token }` on success: confirmed
- Existing form components usable: confirmed
- Tailwind only, no new CSS: confirmed

## Follow-ups
- [ ] Backend should return identical 401 for both auth failures
- [ ] Add rate limiting to /api/auth (separate task)
