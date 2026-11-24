---
paths:
  - '**/*.Tests/**'
  - '**/*.spec.js'
  - '**/*.spec.jsx'
  - '**/*.spec.ts'
  - '**/*.spec.tsx'
  - '**/*.test.js'
  - '**/*.test.jsx'
  - '**/*.test.ts'
  - '**/*.test.tsx'
  - 'apps/*/e2e/**'
  - 'apps/*/tests/**'
  - 'e2e/**'
  - 'modules/**/tests/**'
  - 'tests/**'
---

# Tests

## Bound conventions
`docs/conventions/testing.md` binds every path here; the profile's **Testing** section names the
runner and the tag mechanism.

## Every requirement's test cites it
A test proving a requirement carries its ID (`NNNN.Rn`) in the stack's tag mechanism — Pest group,
xUnit trait, Vitest title prefix, Playwright tag, Gherkin tag. The ID lives in the tag, never in a
code comment.

## Red first
An acceptance test is seen failing for the right reason before the code that makes it pass. A fix
ships with a regression test that fails without it; one that passes on the old code proves nothing.

## Mechanics
- Factories and their states, never hand-built models.
- Fake every outbound call, asserting the host as well as the payload.
- Freeze time where a test compares it.
- The real database engine, never an in-memory substitute.
- Run the minimum test that proves the change — one file, one name, or one requirement tag — and
  leave the full suite to CI.

## Never point the suite at a real database
The test database is created by the suite and guarded by name. If the guard trips, fix the
environment — never the guard.
