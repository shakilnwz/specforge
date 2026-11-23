# Next.js Profile

How the core conventions are realised in a Next.js App Router app with React and TypeScript, and
the rules only Next.js needs. Normative for every app the **Stacks** table in `AGENTS.md` assigns to
Next.js. It realises [`architecture.md`](architecture.md), [`coding.md`](coding.md),
[`frontend.md`](frontend.md), [`security.md`](security.md) and [`testing.md`](testing.md); it never
relaxes them. The Next.js and React versions, the ORM and the job host are fixed by the stack ADR.

## Scope

Applies to:

- every `*.ts`, `*.tsx`, `*.css` file of the app, `next.config.*`, `proxy.ts` / `middleware.ts`
- the ORM schema and migrations, when the app owns a database

## Two modes

The stack ADR declares which one the app is; the rules differ.

| Mode | The Next.js server | Business rules live in |
| --- | --- | --- |
| **Full-stack** | Owns entry points (server actions, route handlers), Actions, Queries and the database | This app, under `src/modules/*/server/` |
| **Frontend / BFF** | Renders, and calls a Laravel or .NET API through one generated client; holds the session server-side | The API. The Next.js server holds no business rule and no database |

In BFF mode the API's own profile governs the server rules; this profile governs rendering, the
client, and the BFF layer. Access tokens stay on the Next.js server (an `HttpOnly` cookie or the
server session) and never reach client JavaScript.

## Concepts (full-stack)

| Concept | Next.js |
| --- | --- |
| Entry point | Server action (`'use server'`), route handler (`route.ts`), Server Component doing a plain read |
| Input validation | Zod schema, shared by client and server |
| Command | `Readonly<z.infer<typeof Schema>>` |
| Action | `server/actions/<verb-noun>.ts` exporting one function, wrapped by its surface |
| Query | `server/queries/<name>.ts`, part of the module's data access layer |
| Repository | None by default; the ORM client is the unit of work |
| Model | Prisma or Drizzle schema, per the ADR |
| Response | A mapper returning a named, serializable type — never an ORM object |
| List response | The project's one `Paginated<T>` |
| Job / Listener | A job host (BullMQ, Inngest, Trigger.dev — per ADR), or `after()` for small post-response work |
| Module | `src/modules/<module>/` |
| Surface declaration | `src/server/surfaces.ts`: one action wrapper and one route wrapper per surface |
| Arch tests | `dependency-cruiser` or `eslint-plugin-boundaries`; an arch test over exported actions |
| Formatter | Prettier, with `prettier-plugin-tailwindcss` where Tailwind is used |

## Layout

```
src/
├── app/                          routing only
│   ├── (public)/                 one route group per surface, with its layout
│   ├── (account)/
│   └── (admin)/
│       └── products/
│           ├── page.tsx          reads through a Query, renders module components
│           └── _components/      used by this route alone
├── modules/
│   └── catalog/
│       ├── server/               import 'server-only' — actions, queries, data access
│       │   └── index.ts          the module's server-side public surface
│       ├── ui/                   components the module exposes
│       ├── schemas.ts            Zod schemas
│       └── index.ts              the module's client-safe public surface
├── shared/                       ui/, lib/, hooks/ — domain-agnostic
├── server/                       cross-module server infrastructure: db, auth, surfaces, http client
└── env.ts                        the one place environment variables are read and validated
```

- `app/` holds routing files only — `page`, `layout`, `route`, `loading`, `error`, `not-found` — plus
  `_components/` folders private to one route. A page reads through a Query and composes module
  components; it holds no rule.
- A module is imported only through its two `index.ts` files. `eslint-plugin-boundaries` or
  `dependency-cruiser` fails a deep import into another module and any import of `server/` from a
  client module.

## The server/client boundary

- Components are Server Components unless they need state, effects, event handlers or browser APIs.
  `'use client'` goes on the smallest leaf that needs it, never on a layout or a page.
- Every module under `server/` imports `server-only`, so a client import fails the build.
- Props crossing into a Client Component are serializable Response types — never an ORM record,
  never a field the viewer may not see.
- Only `NEXT_PUBLIC_*` variables reach the client, and only public values may carry that prefix.
  `src/env.ts` validates every variable with Zod at startup.

## Server actions and route handlers

**A server action is a public HTTP endpoint.** Anyone can call it with any arguments, whatever the UI
shows.

```ts
export const publishProduct = adminAction(PublishProductSchema, async (command, { user }) => {
    const product = await publishProductAction(command, user);

    revalidateTag(productTag(product.id));

    return toProductResponse(product);
});
```

- Every exported action and route handler is produced by its surface's wrapper from
  `src/server/surfaces.ts`, which parses input with the schema, authenticates for the surface, and
  normalises errors. An arch test fails an export that is not wrapped.
- Record authorization happens inside the Action or the data access layer, every time — never in a
  layout, a page guard or `proxy.ts` alone. Edge middleware is for redirects, headers and locale
  routing; it has been bypassed before.
- Never trust closed-over or hidden-field identifiers: re-read ownership on the server.
- An action returns a discriminated result — `{ ok: true, data } | { ok: false, error }` — for
  expected failures, and throws only for unexpected ones.

## Caching and data fetching

- Every cached read declares its lifetime and its tags; every mutation invalidates the tags it
  affects before returning. A read whose staleness nobody chose is a bug waiting for traffic.
- Data that varies by user is never in a shared cache.
- Server Components fetch close to where data is used, in parallel (`Promise.all`), streamed behind
  `<Suspense>`. No `useEffect` fetch for initial data; client-side fetching (TanStack Query) is for
  interactive state only.
- Lists page on the server from `searchParams` parsed with Zod, and return `Paginated<T>`.

## Database (full-stack)

- Prisma Migrate or Drizzle Kit, per the ADR; migrations are never edited after they ran anywhere but
  your machine.
- State transitions run in a transaction with a row lock (`SELECT … FOR UPDATE` through the ORM's
  parameterised raw query or locking API) or an atomic conditional update whose affected count is
  checked.
- Raw SQL only through tagged templates that parameterise; never string concatenation.

## Security mechanisms

| Rule | Next.js mechanism |
| --- | --- |
| Deny by default | Surface wrappers; an arch test that every action and handler is wrapped |
| Record authorization | Inside the Action / data access layer |
| Raw-HTML sinks | `dangerouslySetInnerHTML` — sanitized server-side HTML only |
| Secrets in bundles | `server-only`; no secret behind `NEXT_PUBLIC_` |
| CSRF | Server actions compare `Origin` to the host; route handlers taking cookie-authenticated mutations check it too |
| Security headers | `headers()` in `next.config` or `proxy.ts`, CSP with nonces where scripts are inline |
| Images | `images.remotePatterns` lists exact hosts |

## Frontend rules

- Files and folders are kebab-case (`product-card.tsx`), matching the routing files; components and
  types are PascalCase; hooks are `use-<thing>.ts` exporting `use<Thing>`.
- No TypeScript `enum`: an `as const` object and its union type. No `I` prefix on interfaces.
- Navigation uses `<Link>` with typed routes (`typedRoutes: true`) or the route helper module; never
  a concatenated string.
- Forms use the same Zod schema as the action — React Hook Form with its resolver, or
  `useActionState`.
- `error.tsx`, `not-found.tsx` and `loading.tsx` exist for every surface's route group; a server
  error's message never reaches the client.
- Images through `next/image`; heavy client-only components through `next/dynamic`.

## Testing

- Vitest for units, Queries and Actions (called directly with a constructed user), and components
  with Testing Library; Playwright for journeys. MSW or the job host's test mode for outbound calls.
- Trace with a title prefix — `it('[0012.R3] refuses a withdrawal above the balance', …)`, filtered
  with `-t 0012.R3` — and with Playwright tags: `test('…', { tag: '@0012.R3' }, …)`.
- An arch test lists every exported server action and route handler and asserts it is wrapped.

## Tooling

- ESLint (Next's `core-web-vitals` rules, `typescript-eslint` strict), Prettier, and `tsc --noEmit`
  are three CI gates.
- Complexity: ESLint's `complexity` rule at 10, or `lizard` run outside the tree.
- Dead code: `knip`. Bundles: `@next/bundle-analyzer`.

---

Related: [`frontend.md`](frontend.md) · [`architecture.md`](architecture.md) · [`security.md`](security.md)
