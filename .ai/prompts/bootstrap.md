# Bootstrap a Project

Take a repository that has just received this kit to the close of gate G0 in
[`lifecycle.md`](../../docs/conventions/lifecycle.md): every decision the rest of the project rests
on written down, each app bound to its stack profile, the capabilities in scope listed for
specification, every placeholder filled, nothing built yet.

**Mode:** Writes documents and repository hygiene files only. No application code, no framework
install, no dependency, until the owner approves the stack ADR — then only what G0 requires.
**Output:** filled `AGENTS.md`; `docs/adr/0001-*.md`, `docs/adr/0002-*.md`; a context page in
`docs/architecture/`; `docs/reference/glossary.md`; hygiene files; the kit trimmed to the stacks in
use; updated G0 rows in `docs/audit/readiness.md`; a G0 gate report.
**Inputs:** the owner, who answers the questions below. Never invent an answer the owner did not
give; a placeholder left open is better than a fabricated fact.

## Before you start

1. Confirm the kit is present: `AGENTS.md`, `CLAUDE.md`, `.ai/rules/`, `.ai/prompts/`,
   `docs/conventions/` (core conventions and `stack-*.md` profiles), `docs/templates/`,
   `docs/audit/readiness.md`, `.claude/rules` linking to `.ai/rules`.
2. List every `bootstrap:` marker: `grep -rn 'bootstrap:' AGENTS.md docs .ai .github`.
3. Read `lifecycle.md` → G0, [`documentation.md`](../../docs/conventions/documentation.md) and
   [`specs.md`](../../docs/conventions/specs.md).

## Ask the owner

Ask in one round, grouped, with a recommended default for each where one exists:

1. **Product:** what it does, in two sentences; who uses it (each kind of person); what is out of
   scope.
2. **Capabilities:** the things each kind of person must be able to do, one line each — the
   candidate specs. Mark which are needed for a first release.
3. **Vocabulary:** the domain's core nouns and verbs as the owner says them, and the synonyms in use
   that should be retired.
4. **External systems:** payment, mail, storage, DNS, identity, search — each with its provider if
   chosen.
5. **Stack, per app:** Laravel, .NET or Next.js for the server; Vue or Next.js for the frontend; the
   major versions; database; cache and queue; hosting. The kit ships profiles for
   [Laravel](../../docs/conventions/stack-laravel.md), [.NET](../../docs/conventions/stack-dotnet.md),
   [Next.js](../../docs/conventions/stack-nextjs.md) and [Vue](../../docs/conventions/stack-vue.md).
   For Next.js, also: full-stack, or a frontend over another app's API.
6. **Shape:** single app or monorepo; which apps; which surfaces each app has (who is on the other
   end, which host, which authentication); modular or not — and if modular, the modules, the shared
   kernel and the modularity level (1 code, 2 data, 3 service) from
   [`architecture.md`](../../docs/conventions/architecture.md) → *Modules*. Default: Level 1 unless a
   reason for more is given.
7. **Constraints:** compliance, data residency, accessibility and performance targets, deadlines,
   team size.

## Steps

1. Write **ADR-0001** (stack per app) and **ADR-0002** (shape, surfaces, modules and modularity
   level) from [`adr.md`](../../docs/templates/adr.md), status Proposed, with the alternatives the
   owner weighed.
2. Write the context page `docs/architecture/context.md` from
   [`architecture.md`](../../docs/templates/architecture.md): the people (the actors specs will
   name), every external system in one diagram, and the **capabilities in scope** — one line each,
   numbered in the order they will be specified, each to become `docs/specs/NNNN-<capability>/`.
3. Seed `docs/reference/glossary.md` from [`reference.md`](../../docs/templates/reference.md): one
   row per concept — the term, its one-line meaning, and the names it must not be called.
4. Fill `AGENTS.md`: the **Stacks** table (each app, its path, its profiles); **Architecture
   Overview** from the ADRs; **Common Commands**, **Local Endpoints** and **Database** once the
   environment exists (otherwise leave the marker and say so).
5. **Trim the kit to the stacks in use**, once the owner approves ADR-0001: list the profiles, the
   `.ai/rules/` stack files and the PR-template lines no app uses, and remove them with the owner's
   approval. Never remove a core convention.
6. Adjust the `paths:` globs in `.ai/rules/*.md` to the real layout — app directories in a monorepo,
   module directories when modular — and regenerate `.ai/rules/index.md` to match (Boost's format:
   one row per rule file, sorted by file path, globs joined by `, `).
7. Fill the surface-declaration table in `architecture.md` from ADR-0002, leaving the mechanism
   column to the profile.
8. Repository hygiene for G0.6: ignore files per stack, `.editorconfig`, example environment files
   with no real values. Check history for secrets (`git log -p -S` for key-like prefixes) and report
   any found.
9. CI for G0.8: one job per app running its profile's lint, format check, type check, test and build
   commands — proposed for the owner's approval, as it adds files under `.github/`.
10. Pull-request templates (G0.9) are in `.github/PULL_REQUEST_TEMPLATE/`; fill their placeholders
    for the project's apps.
11. Update the G0 rows of `docs/audit/readiness.md` you can evidence; set **Opened** to today and the
    commit.
12. Run the [`phase-gate`](audits/phase-gate.md) audit for G0 and file its report.

## Done when

- Every `bootstrap:` marker is filled, or listed in the hand-off with the question it waits on.
- The ADRs are written and awaiting the owner's acceptance.
- Every capability in scope is on the context page; the first one is ready to be specified at G1.
- The G0 gate report says plainly whether G0 can close.
- `AGENTS.md`'s **Phase** line is unchanged — advancing it is the owner's decision.
