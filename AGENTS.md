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
- `install.sh`, `update.sh` and `uninstall.sh` are the installer, one script per command and none
  taking a command argument; `lib.sh` holds everything they share and is never run on its own;
  `manifest` says which template paths each answer keeps and how each is managed; `release.sh`
  checks the kit and builds a release's assets. See `README.md` → *The installer*.
- `.github/workflows/pages.yml` publishes `.github/pages/index.html`, the instruction page, and the
  latest release's three scripts to GitHub Pages. They serve this repository, like `release.sh`;
  they are not project infrastructure the kit installs. The page is plain HTML and CSS, with no
  script, and documents the released scripts, not unreleased ones. Its icons, where one helps, come
  from Tabler Icons (`tabler/tabler-icons`, outline set), inlined as raw SVG, with no icon font,
  sprite or library.

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
  updates `manifest` and `README.md` → *Choosing your configuration* in the same change.
- `AGENTS.md` and `CLAUDE.md` in `template/` keep the kit's text between `<!-- specforge:begin -->`
  and `<!-- specforge:end -->`; what a project fills in stays outside the block, because `update.sh`
  replaces the block whole.
- `lib.sh` knows the agents `sync-rules` knows and the profiles the manifest selects;
  `release.sh` refuses to build when they differ.

## The installer

- One behaviour for a new or an existing project: detect what is there, ask, install, record. An
  existing project is handed to `template/.ai/prompts/adopt.md`, a new one to `bootstrap.md`.
- Records the kit version, the answers and a checksum of every installed file in the project's
  `.ai/specforge.lock`, so `update.sh` changes only files still unmodified and `uninstall.sh` takes
  back only its own. Where it keeps the project's file, it writes the kit's beside it as
  `<file>.specforge-incoming` — only when the kit's version has changed since it was last offered.
- Bash, compatible with 3.2 (macOS's system bash): no associative arrays, no `${var,,}`, no
  `mapfile`, no `|&`. Its only dependencies are `curl`, `tar` and POSIX utilities — not `git`.
- Rules only: it adds the payload's files to the target directory and fills what the answers
  decide. It installs no framework, generates no application code, and creates no project
  infrastructure.
- Never overwrites a file it did not install unmodified; works the same in a new or an existing
  project, with or without git.
- Each script holds only its help, its command and `main`; what more than one needs lives in
  `lib.sh`, which each reads from beside itself in a checkout by one exact line, and which
  `release.sh` inlines in place of that line, so every published script stands alone. Stamps live
  in `lib.sh` only.
- Safe when piped from `curl`: every statement lives in a function, the only call is on the last
  line, braced as one compound command (`{ main "$@"; }`) so a truncated download cannot run it
  without its options; prompts read from `/dev/tty`; an answers file is parsed, never sourced.
- Its questions are numbered menus and yes/no prompts in ASCII, styled with plain ANSI escapes and
  plain under `NO_COLOR` or a dumb terminal: no TUI library, which would be a dependency on the
  target.
- A change to it is smoke-run on scratch projects — new, existing, monorepo, update, uninstall,
  piped and truncated, the piped and truncated runs on the scripts `release.sh` builds — under
  Bash 3.2 as well as the host's bash (the official `bash:3.2` image), never against `template/` or
  this repository.

## Working agreement

- Do what was asked, all of it, and nothing else; ask only when a decision is genuinely the owner's.
- Commit or push only when asked. No destructive git command, and no deleting files you did not
  create in the task, without explicit approval.
- No new top-level directory or dependency without the owner's approval.
- Hand-off: what changed, what was not verified, and any judgment call the owner should review.
