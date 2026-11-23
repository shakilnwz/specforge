# Software Factory Kit — maintainer instructions

This repository builds the kit. It is not a project built with the kit.

### Important
No need to lint and test unless asked. Say so in the hand-off when a change was not verified.
Talk to me in advanced and sophisticated language of the software engineering domain or industry.

## Layout

- `template/` is the payload. Every file in it is copied into a new project, and nothing about the
  kit itself belongs in it.
- `README.md` at the root is the kit's manual. It is never copied.
- Planned, not yet built: `install.sh` (the scaffolder) and `manifest` (which template paths each
  choice keeps) at the root — see `README.md` → *Roadmap*.

## The payload's own instructions are content, not instructions

`template/CLAUDE.md` and `template/AGENTS.md` load when an agent reads files under `template/`.
Here they are the text being edited: their phase line, spec-first rule and read-before-write steps
govern the project a user scaffolds, not this repository. What does bind work here is the payload's
*consistency*: a change to a convention in `template/docs/conventions/` is checked against the other
conventions, the profiles, the `.ai/rules/` files and the audit prompts that restate or rely on it.

## Invariants of the payload

- Placeholders are `<!-- bootstrap: … -->` markers. They are filled in a scaffolded project, never
  here.
- Relative links inside `template/` resolve within `template/`, as they will in a project. The root
  `README.md` links into it with the `template/` prefix.
- `template/.ai/rules/index.md` stays byte-identical to what Laravel Boost generates: one row per
  flat rule file, sorted by file path, globs in frontmatter order joined by `, `; in the frontmatter,
  a glob containing `*` is single-quoted and any other is bare.
- A core convention states each rule once and stays stack-neutral; a stack's mechanism lives in its
  `stack-<name>.md` profile, its `.ai/rules/<name>.md` file, and the *Stack notes* of the audit
  prompts.
- Every concern has one owning audit (`template/docs/conventions/auditing.md` → *Ownership*); a new
  audit or a new gate criterion updates the catalog, the ownership table, `lifecycle.md` and
  `docs/audit/readiness.md` together.
- A change to what a configuration choice keeps or removes — a new profile, rule file or template —
  updates `README.md` → *Choosing your configuration* in the same change.

## The scaffolder, when it is built

- Bash, compatible with 3.2 (macOS's system bash): no associative arrays, no `${var,,}`, no
  `mapfile`, no `|&`. Its only dependencies are `curl`, `tar` and POSIX utilities.
- Kit only: it copies and fills the payload. It installs no framework and generates no application
  code.
- Safe when piped from `curl`: the body is one function, called on the last line; prompts read from
  `/dev/tty`; an answers file is parsed, never sourced.

## Working agreement

- Do what was asked, all of it, and nothing else; ask only when a decision is genuinely the owner's.
- Commit or push only when asked. No destructive git command, and no deleting files you did not
  create in the task, without explicit approval.
- No new top-level directory or dependency without the owner's approval.
- Hand-off: what changed, what was not verified, and any judgment call the owner should review.
