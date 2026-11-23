# Software Factory Kit

A bootstrap kit that takes a project from a blank repository to a released product under one set
of rules: the rules AI agents and people follow when specifying and writing code, the rules for
auditing that code, and the documents both produce. Copy it into an empty repository, answer the
bootstrap questions, and the project starts at gate G0 with every later gate already defined.

It is spec-driven — behaviour is specified, approved and traced to tests before and while it is
built — and stack-aware: one set of core conventions, realised per stack by profiles for
**Laravel**, **ASP.NET Core**, **Next.js** and **Vue**, mixed freely across the apps of a monorepo.

Derived from the rulesets of the zuus monorepo (`~/code/zuus` at `30443ad8b`, 2026-11-22):
its `AGENTS.md`, `docs/conventions/`, `docs/templates/`, app-level conventions, pull-request
templates and audit prompt, generalised and extended.

## What is in it

```
AGENTS.md                         Entry point for every agent: authority order, stacks, spec-driven
                                  development, read-before-write, phase, project overview
CLAUDE.md                         Imports AGENTS.md for Claude Code
.claude/rules -> ../.ai/rules     Claude Code loads each rule file when a matching path is touched
.ai/
  rules/                          Path-scoped agent rules, in Laravel Boost's format
    index.md                      Glob → rule file; the same file Boost regenerates
    general.md backend.md frontend.md database.md tests.md specs.md docs.md audits.md   — core
    laravel.md dotnet.md nextjs.md vue.md                                               — per stack
  prompts/
    bootstrap.md                  Runbook for Phase 0
    audits/                       One runnable prompt per audit type (18)
docs/
  conventions/                    Normative rules
    architecture.md coding.md frontend.md security.md testing.md   — how code is written, any stack
    specs.md                                                       — how behaviour is specified
    stack-laravel.md stack-dotnet.md stack-nextjs.md stack-vue.md  — how each stack realises the core
    documentation.md auditing.md lifecycle.md                      — how the project is run
  templates/                      One template per document type (13), spec/design/tasks among them
  audit/readiness.md              Living tracker of every gate criterion, starting at 0 of 40
.github/PULL_REQUEST_TEMPLATE/    default, feature, bugfix, hotfix — spec, requirement and convention checklists
```

### The four rule sets

| Rule set | Lives in | Read by |
| --- | --- | --- |
| **Spec rules** — what is built, and how it is proved | `docs/conventions/specs.md`; `docs/templates/{spec,design,tasks}.md`, `feature.feature` | The owner and agents before any behaviour change |
| **Code rules** — how code is shaped and written | `docs/conventions/{architecture,coding,frontend,security,testing}.md` and the `stack-*.md` profiles, routed to by `.ai/rules/*` | Agents before any edit; reviewers on every PR |
| **Audit rules** — how code is examined | `docs/conventions/auditing.md` (protocol, ownership, severity, evidence, verification) and `.ai/prompts/audits/*` (what each audit checks, with stack notes) | Whoever runs an audit, person or agent |
| **Document rules** — where findings and decisions go | `docs/conventions/documentation.md`, `docs/templates/*`, `docs/audit/`, `docs/reports/` | Everyone writing a document |

`docs/conventions/lifecycle.md` ties them together: five phases, each closed by a gate whose
criteria name the specs that must be Implemented, the audits that must have run, and the severity
they must be clean of.

### Core and profiles

The core conventions speak one vocabulary — entry point, Command, Action, Query, Model, Response,
surface, module — and state each rule once. A profile maps that vocabulary onto a stack (a Laravel
FormRequest and Spatie Data object, a .NET `sealed record` and `internal` handler, a Next.js Zod
schema and wrapped server action) and adds the stack's own traps. A profile may sharpen a core rule
or follow a language idiom where it says so; it never relaxes one. Bootstrap removes the profiles
no app uses.

### Spec-driven development

Every capability goes through one loop: **specify** (EARS requirements with permanent IDs,
scenarios including refusals, quantified non-functional requirements, an out-of-scope list) →
**clarify** (`[NEEDS CLARIFICATION]` markers answered by the owner) → **approve** (the owner only)
→ **design** (with a constitution check against the conventions) → **tasks** (tests first) →
**implement** → **verify** (a scoped spec-conformance audit). Traceability runs requirement → task
→ tagged test → code in every stack, so "is R3 proved?" is one grep. Overreach — behaviour no
requirement asks for — is a defect, found by the spec-conformance audit's reverse sweep.

## Bootstrapping a project

1. Copy the kit into the new repository, keeping the symlink:
   `rsync -a --exclude .git <kit>/ <project>/` — or start the project from this repository.
2. Ask the agent to run [`.ai/prompts/bootstrap.md`](.ai/prompts/bootstrap.md). It asks the
   product, capabilities, vocabulary, stack-per-app and shape questions; writes ADR-0001 (stacks),
   ADR-0002 (shape and modularity level), the context page and the glossary seed; fills `AGENTS.md`;
   proposes removing unused profiles; and runs the G0 gate audit.
3. Accept or amend the ADRs. Advance `AGENTS.md`'s **Phase** line when the gate report says G0 can
   close — that step is the owner's, never the agent's.
4. For a Laravel app with Laravel Boost, run `php artisan boost:install` after step 1. Boost
   appends its own block to `CLAUDE.md` and `AGENTS.md`, keeps `.ai/rules/index.md` in the format
   already here, and owns `.ai/rules/boost/` — never put a hand-written rule there, it is deleted
   on every sync.

A non-modular app reads every module path as the app root. A monorepo gives each app its own
`docs/` and `.ai/rules/`, with globs relative to that app. A stack with no profile here gets one
written from `docs/templates/convention.md` before its first line of code, through an ADR.

## Running an audit

Ask for it by name: *"run the security audit"*. The agent opens
`.ai/prompts/audits/security.md`, follows [`auditing.md`](docs/conventions/auditing.md), reads the
stack profile of every app in scope, and writes a report or updates a living audit. Every audit is
read-only; fixes are separate changes. Each concern has one owning audit, so a finding is filed once.

| When | Audits |
| --- | --- |
| Closing G1 — foundation | architecture-conformance, modularity (when modular), dependencies, operations |
| Each spec reaching Implemented | spec-conformance, scoped to that spec |
| Closing G2 — feature complete | spec-conformance, consistency, bugs, database-schema, frontend, test-coverage; architecture-conformance and modularity re-run |
| Closing G3 — hardened | security, bugs, performance, simplification, dead-code, complexity, naming, consistency, modularity, documentation-drift, frontend, operations |
| Every gate and every release | phase-gate |
| After an incident, upgrade, port or cross-module refactor | the targeted ones in `auditing.md` → *Cadence* |

## Extending the kit

- **A new code rule:** append it under the matching heading of the core convention it belongs to,
  with its reason, and its realisation in each profile that needs one; add an arch test when it is
  mechanically checkable.
- **A new stack:** write `docs/conventions/stack-<name>.md` from `docs/templates/convention.md`,
  mapping every row of the core concepts table; add `.ai/rules/<name>.md` with its globs; add its row
  to `AGENTS.md`'s profile table and a row of stack notes to every audit prompt; regenerate
  `.ai/rules/index.md`.
- **A new area convention:** start from `docs/templates/convention.md`, bind its paths in
  `AGENTS.md`'s path table and in an `.ai/rules/` file, regenerate `.ai/rules/index.md`.
- **A new audit type:** start from `docs/templates/audit-prompt.md`, add it to the catalog and the
  ownership table in `auditing.md`, and to a gate in `lifecycle.md` if it is required.
- **A durable decision or trap found while working:** record it in `.ai/rules/` (Boost's
  `record-rule`, or by hand in the same format), never in personal agent memory.

## What changed from zuus

- Project-specific facts (apps, mounts, domains, tenancy, commands) became `bootstrap:`
  placeholders; the rules around them were kept.
- `AGENTS.md` gained an explicit authority order (Approved specs in it), a read-before-write
  protocol that starts at the spec, a stacks table, and the phase line.
- The conventions were split into a stack-neutral core and four profiles. zuus's Laravel and Vue
  mechanics live in `stack-laravel.md` and `stack-vue.md` intact; .NET and Next.js profiles are
  new and realise the same rules.
- `architecture.md` gained the layer responsibility matrix, module boundaries (promised by zuus's
  `AGENTS.md` but absent from its file) as governed seams with three declared modularity levels and
  invisible edges, and asynchronous-work rules.
- `coding.md` gained rules distilled from zuus's own reports — query placement, Command purity,
  `Get*` Actions, hand-rolled payloads, enum predicates, naming discrepancies, migration history,
  cascades, indexes, unknown-vs-no errors, fail-loud config — plus size and complexity thresholds.
- `frontend.md` merges three zuus sources that disagreed (root frontend rules, commerce
  `frontend-structure.md`, `admin-assets.md`) into one rule set; the root rules won conflicts.
- `specs.md`, `security.md`, `testing.md`, `documentation.md`, `auditing.md` and `lifecycle.md` are
  new. Feature files became executable acceptance criteria written *before* the code, where zuus
  described behaviour after it.
- Templates gained verification, `Prior` and **Not checked** fields; `spec.md`, `design.md`,
  `tasks.md` and `audit-prompt.md` are new.
- The single database-schema prompt became a catalog of eighteen audit prompts sharing one
  structure, with an ownership table so no concern is audited twice — spec conformance (including
  overreach), consistency, simplification, naming and modularity among them.
- Pull-request checklists link the conventions instead of restating them — zuus's restated
  checklist had drifted from its own `architecture.md` (mandatory Repository hop, PHPUnit) — and
  name the spec, tasks and requirement IDs they serve.
