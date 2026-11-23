---
paths:
  - '**/*.tsx'
  - '**/middleware.ts'
  - '**/proxy.ts'
  - 'next.config.*'
  - 'src/app/**'
  - 'src/modules/**'
  - 'src/server/**'
---

# Next.js

## Bound conventions
`docs/conventions/stack-nextjs.md` realises the core conventions for every Next.js app, in the mode
ADR-0001 names (full-stack, or a frontend over another app's API). Read it beside the core section it
realises; where the two seem to disagree, the core wins and the profile is a defect to report.

## Traps agents fall into here
- `app/` is routing only. Domain code lives in `src/modules/<module>/`; server code in its `server/`,
  which imports `server-only`.
- Every exported server action and route handler is wrapped by its surface's wrapper from
  `src/server/surfaces.ts`. Authorization lives in the data-access path — never only in a layout, a
  page guard, `proxy.ts` or middleware.
- `'use client'` goes on the smallest leaf that needs it, never on a layout or a page. Props crossing
  to the client are serializable and carry no ORM object.
- Only `NEXT_PUBLIC_*` variables reach the client, and only public values may carry that prefix.
- A mutation revalidates the tags or paths it made stale; per-user data never enters a shared cache.
- Ids, prices and ownership arrive through the validated input and are re-checked — never trusted
  from a closure or a hidden field.

## Framework mechanics
- Check the installed `next` version before relying on an API; the App Router's caching defaults
  change between majors.
- Tooling: ESLint, Prettier, `tsc --noEmit`, run when asked; `knip` for dead code.
- Tests: Vitest titles prefixed `[NNNN.Rn]` (run one with `-t NNNN.Rn`), Playwright tagged
  `{ tag: '@NNNN.Rn' }`.
