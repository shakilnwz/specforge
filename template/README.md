# <!-- bootstrap: product name -->

<!-- bootstrap: what the product does and for whom, in two sentences — the same words as the context page in docs/architecture/ -->

## Apps

| App | Path | Stack | Serves |
| --- | --- | --- | --- |
| <!-- bootstrap: app --> | <!-- bootstrap: `path` --> | <!-- bootstrap: stack and major versions, as in ADR-0001 --> | <!-- bootstrap: its surfaces, as in ADR-0002 --> |

## Getting started

<!-- bootstrap: prerequisites, then the one command that boots the local environment — the same command AGENTS.md lists under Common Commands -->

## How this project is built

Behaviour is specified before it is built. Every capability has a spec under `docs/specs/` with
numbered requirements the owner approves; code is written task by task against it, and every
requirement is proved by a test tagged with its ID. Work that changes no behaviour — a refactor, an
upgrade — is a plan under `docs/plans/`. The rules for all of it are in
[`docs/conventions/`](docs/conventions/), and [`AGENTS.md`](AGENTS.md) is where people and AI agents
both start.

| To find | Look in |
| --- | --- |
| What the product must do | `docs/specs/` |
| Why it is built the way it is | `docs/adr/` |
| The rules for code, specs, audits and documents | [`docs/conventions/`](docs/conventions/) |
| How the system is shaped | `docs/architecture/` |
| What each term means | `docs/reference/glossary.md` |
| Where the project stands against its release gates | [`docs/audit/readiness.md`](docs/audit/readiness.md) |

## Contributing

Open a pull request from the template that fits the change — `?template=feature.md`,
`bugfix.md`, `hotfix.md`, or the default — and complete its checklist. A behaviour change names the
spec, tasks and requirement IDs it serves.
