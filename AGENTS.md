# SpecForge — maintainer instructions

This repository builds SpecForge, the kit. It is not a project built with the kit.

## What the kit is

A ruleset — coding, spec, audit and documentation rules, with the prompts and templates that apply
them — and an installer that **adds it to a project**, brand new or long established. It is not a
project scaffolder and not a repository template: it never creates a project, application code or
project infrastructure (ignore files, CI workflows, a README), and it assumes no version control —
the target is a directory, which may or may not be a git work tree. Every design decision, document
and line of the installer follows from this.

### Important
No need to lint and test unless asked. Say so in the hand-off when a change was not verified.
Talk to me in advanced and sophisticated language of the software engineering domain or industry.

## Layout

- `template/` is the payload. Every file in it is installed into a project, new or existing, and
  nothing about the kit itself belongs in it. It ships no generated agent rule files, and its
  `.ai/agents` lists every agent commented out: the project chooses.
- `README.md` at the root is the kit's manual. It is never copied.
- Planned, not yet built: `install.sh` (the installer) and `manifest` (which template paths each
  choice keeps) at the root — see `README.md` → *Roadmap*.

## The payload's own instructions are content, not instructions

`template/CLAUDE.md` and `template/AGENTS.md` load when an agent reads files under `template/`.
Here they are the text being edited: their phase line, spec-first rule and read-before-write steps
govern the project the kit is installed into, not this repository. What does bind work here is the
payload's *consistency*: a change to a convention in `template/docs/conventions/` is checked against
the other conventions, the profiles, the `.ai/rules/` files and the audit prompts that restate or
rely on it.

## Invariants of the payload

- Placeholders are `<!-- bootstrap: … -->` markers. They are filled in the project the kit is
  installed into, never here.
- Relative links inside `template/` resolve within `template/`, as they will in a project. The root
  `README.md` links into it with the `template/` prefix.
- `template/.ai/rules/index.md` stays byte-identical to what Laravel Boost generates: one row per
  flat rule file, sorted by file path, globs in frontmatter order joined by `, `; in the frontmatter,
  a glob containing `*` is single-quoted and any other is bare.
- `template/.ai/bin/sync-rules` renders each agent's documented rule format (`.claude/rules` `paths:`,
  Cursor `.mdc` `globs:`/`alwaysApply:`, Copilot `applyTo:`, Windsurf and Antigravity `trigger:`/
  `globs:`, Kiro `inclusion:`/`fileMatchPattern:`). A change to it, or to an agent's format, is
  checked against that agent's current documentation and smoke-run on a scratch copy of `template/`
  with every agent enabled — never inside `template/`.
- `template/.ai/bin/` scripts follow the installer's portability rules below: Bash 3.2, POSIX tools,
  no git, no network.
- A core convention states each rule once and stays stack-neutral; a stack's mechanism lives in its
  `stack-<name>.md` profile, its `.ai/rules/<name>.md` file, and the *Stack notes* of the audit
  prompts.
- Every concern has one owning audit (`template/docs/conventions/auditing.md` → *Ownership*); a new
  audit or a new gate criterion updates the catalog, the ownership table, `lifecycle.md` and
  `docs/audit/readiness.md` together.
- A change to what a configuration choice keeps or removes — a new profile, rule file or template —
  updates `README.md` → *Choosing your configuration* in the same change.

## The installer, when it is built

- One behaviour for a new or an existing project: detect what is there, ask, install, record. An
  existing project is handed to `template/.ai/prompts/adopt.md`, a new one to `bootstrap.md`.
- Records the kit version, the answers and a checksum of every installed file in the project's
  `.ai/specforge.lock`, so `update` changes only files still unmodified and `remove` takes back only
  its own. Where it keeps the project's file, it writes the kit's beside it as
  `<file>.specforge-incoming`.
- Bash, compatible with 3.2 (macOS's system bash): no associative arrays, no `${var,,}`, no
  `mapfile`, no `|&`. Its only dependencies are `curl`, `tar` and POSIX utilities — not `git`.
- Rules only: it adds the payload's files to the target directory and fills what the answers
  decide. It installs no framework, generates no application code, and creates no project
  infrastructure.
- Never overwrites a file it did not install unmodified; works the same in a new or an existing
  project, with or without git.
- Safe when piped from `curl`: the body is one function, called on the last line; prompts read from
  `/dev/tty`; an answers file is parsed, never sourced.

## Working agreement

- Do what was asked, all of it, and nothing else; ask only when a decision is genuinely the owner's.
- Commit or push only when asked. No destructive git command, and no deleting files you did not
  create in the task, without explicit approval.
- No new top-level directory or dependency without the owner's approval.
- Hand-off: what changed, what was not verified, and any judgment call the owner should review.
