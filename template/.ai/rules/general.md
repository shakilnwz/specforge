---
paths:
  - '**'
---

# General

## Authority and the read-before-write protocol live in AGENTS.md
`AGENTS.md` ranks every source of rules and lists the steps before any edit. This file holds only
the standing working agreement for agents; it never restates a convention.

## Do what was asked, all of it, and nothing else
A bug fix changes what the bug needs: no opportunistic refactor, rename or reformat beside it —
those are their own change. When the task is a refactor, refactor aggressively (`AGENTS.md`).
Finish the job rather than handing back a half-done one; ask only when a decision is genuinely
the owner's.

## Behaviour starts from an approved spec
Before writing code that changes behaviour, find its spec in `docs/specs/` and its task in
`tasks.md`. No spec, or one not yet Approved: draft or amend it and stop for the owner — do not
build ahead of approval. Build what the requirements say and nothing they do not: no extra option,
endpoint, mode or setting, however useful it looks. A discovery that changes behaviour goes back
into the spec, not into the code. Work with no behaviour change — a refactor, an upgrade — needs no
spec, and changes no test's expectations.

## Rules are written once, in `.ai/rules/`
The `ai-*` files under an agent's own directory (`.claude/rules/`, `.cursor/rules/`,
`.github/instructions/`, `.windsurf/rules/`, `.agents/rules/`, `.kiro/steering/`) are generated.
Edit the source in `.ai/rules/`, then run `.ai/bin/sync-rules`; an edit to a generated file is
lost, and `.ai/bin/check` fails CI until it is.

## Approval before structure or dependencies
Do not add, remove or upgrade a dependency, create a new top-level directory, add a module, or
change a convention without the owner's approval in the session. Propose it with the reason.

## Destructive commands
Never run `migrate:fresh`, `migrate:reset`, `db:wipe`, `db:seed` against a non-test database,
`git reset --hard`, `git push --force`, `git clean`, or delete files you did not create in this
task, without explicit approval for that command in this session.

## No verification scripts
Do not write throwaway verification scripts or tinker sessions when a test can prove the
behaviour. Write the test (see `docs/conventions/testing.md`); run it when asked.

## Sub-agent and tool output is a lead, not a fact
A finding, diff or summary produced by a sub-agent or tool is unverified until you have read the
code it points at. Never pass a line number or class name on from memory.

## Hand-off
End with what changed, which spec and tasks it served, what was not verified (lint, tests, a
browser check), which audit rows, task boxes or status lines moved, and any rule you recorded.
State failures plainly.

## Commits
Commit or push only when asked. A commit that closes an audit finding updates the finding's row in
the same commit.
