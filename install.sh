#!/usr/bin/env bash
#
# SpecForge install: adds the SpecForge rules (coding, spec, audit and documentation rules, with the
# prompts and templates that apply them) to a project directory, new or existing.
#
#   curl -fsSL https://shakilnwz.github.io/specforge/install.sh | bash
#
# Run `install.sh --help` for its options. update.sh brings the rules to a later release, and
# uninstall.sh takes them back.
#
# It never creates a project, application code or project infrastructure; never overwrites a file
# it did not install unmodified; never commits, stages or branches. Portable: bash 3.2 or later,
# curl, tar and POSIX tools; git only to report on a work tree, when present.
#
# Every statement lives in a function and the only call is on the last line, so a download cut short
# runs nothing. A release inlines lib.sh in place of the line that reads it, below.

. "$(dirname "$0")/lib.sh" || exit 1

show_help() {
    cat <<'EOF'
SpecForge install: adds the SpecForge rules to a project directory, new or existing.

usage: install.sh [options]

options
  --dir DIR        the project directory (default: the current one); it must already exist
  --answers FILE   take the answers from FILE instead of asking; read, never run
  --yes            ask nothing: take what detection found
  --dry-run        print what would change, and change nothing
  --version vX.Y.Z install that release instead of this script's own
  --from PATH      install from a local checkout or release tarball instead of downloading
  --help           this text

EOF
    show_answer_keys
    cat <<'EOF'

A file you already have is never overwritten: the kit's version is written beside it as
<file>.specforge-incoming. What was installed is recorded in .ai/specforge.lock. update.sh brings
the rules to a later release; uninstall.sh takes them back.
EOF
}

cmd_install() {
    if [ -f "$LOCK" ]; then
        v=$(awk '$1 == "version" { print $2; exit }' "$LOCK")
        die "SpecForge ${v:-} is already installed in $TARGET: run update.sh instead"
    fi
    fetch_source
    detect_apps
    cp "$WORK/detected.apps" "$WORK/apps"
    A_STATE=$(detect_state)
    A_AGENTS=$(detect_agents)
    A_GHERKIN=$(detect_gherkin)
    A_HOST=$(detect_host)
    INTERACTIVE=0
    if [ -n "$ANSWERS_FILE" ]; then
        load_answers
    elif [ "$ASSUME_YES" = 0 ]; then
        can_prompt || die 'no terminal to ask on: pass --answers FILE, or --yes to take what was detected'
        INTERACTIVE=1
    fi
    validate_answers
    if [ "$INTERACTIVE" = 1 ]; then
        ask_questions
        validate_answers
    fi
    say ''
    say "SpecForge $KIT_VERSION into $TARGET"
    show_answers
    git_report
    if [ "$INTERACTIVE" = 1 ] && [ "$DRY_RUN" = 0 ]; then confirm; fi
    install_or_update
}

main() {
    setup install 'dir answers yes dry-run version from' "$@"
    cmd_install
}

# One compound command: a download cut anywhere in this line is a syntax error, not a call that
# has lost its arguments.
{ main "$@"; }
