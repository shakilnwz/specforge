---
paths:
  - '**/*.vue'
  - 'apps/*/resources/js/**/*.ts'
  - 'apps/*/src/features/**/*.ts'
  - 'apps/*/src/shared/**/*.ts'
  - 'resources/js/**/*.ts'
  - 'src/features/**/*.ts'
  - 'src/shared/**/*.ts'
---

# Vue

## Bound conventions
`docs/conventions/stack-vue.md` realises `docs/conventions/frontend.md` for every Vue app. Read it
beside the core section it realises.

## Traps agents fall into here
- Route-level views live in `views/`; a view's private partials in `views/<ViewName>/`; never
  `views/partials/`.
- A feature imports another feature only through its `index.ts`; promote shared code to `shared/`.
- Navigation uses named routes, never string-built paths.
- A Pinia store holds state shared across views or surviving navigation; one view's state stays in
  the view.
- `v-html` only on HTML sanitized server-side for that purpose.

## Tooling
`lint` runs ESLint then Prettier; `vue-tsc --noEmit` type-checks before handing off. If a change does
not show in the browser, the dev server or a build may be needed — ask, do not guess.
