#!/usr/bin/env bash
#
# SpecForge update: brings a project's SpecForge rules to this script's release.
#
#   curl -fsSL https://shakilnwz.github.io/specforge/update.sh | bash
#
# Run `update.sh --help` for its options. install.sh adds the rules to a project, and uninstall.sh
# takes them back.
#
# It replaces only what is still as the kit installed it: a file the project changed stays the
# project's, with the kit's version beside it when that version has changed too. Portable: bash 3.2
# or later, curl, tar and POSIX tools; git only to report on a work tree, when present.
#
# Every statement lives in a function and the only call is on the last line, so a download cut short
# runs nothing. A release inlines lib.sh in place of the line that reads it, below.

. "$(dirname "$0")/lib.sh" || exit 1

show_help() {
    cat <<'EOF'
SpecForge update: brings a project's SpecForge rules to this script's release.

usage: update.sh [options]

options
  --dir DIR        the project directory (default: the current one)
  --reconfigure    ask the questions again, defaulting to the recorded answers
  --answers FILE   replace the recorded answers key by key with FILE's; read, never run
  --dry-run        print what would change, and change nothing
  --version vX.Y.Z update to that release instead of this script's own
  --from PATH      update from a local checkout or release tarball instead of downloading
  --help           this text

EOF
    show_answer_keys
    cat <<'EOF'

Only files still as the kit installed them are replaced. A file you changed is kept, and the kit's
version is written beside it as <file>.specforge-incoming when that version has changed too. A file
you deleted is not restored.
EOF
}

cmd_update() {
    if [ -n "$ANSWERS_FILE" ] && [ "$RECONFIGURE" = 1 ]; then
        usage_error 'use either --answers FILE or --reconfigure, not both'
    fi
    [ -f "$LOCK" ] || die "SpecForge is not installed in $TARGET (no $LOCK_REL): run install.sh"
    cp "$LOCK" "$WORK/lock.old"
    fetch_source
    A_STATE=$(awk '$1 == "answer" && $2 ~ /^state=/ { sub(/^state=/, "", $2); print $2; exit }' "$WORK/lock.old")
    A_GHERKIN=$(awk '$1 == "answer" && $2 ~ /^gherkin=/ { sub(/^gherkin=/, "", $2); print $2; exit }' "$WORK/lock.old")
    A_HOST=$(awk '$1 == "answer" && $2 ~ /^host=/ { sub(/^host=/, "", $2); print $2; exit }' "$WORK/lock.old")
    awk '$1 == "answer" && $2 ~ /^app=/ { sub(/^answer[ \t]+app=/, ""); print }' "$WORK/lock.old" > "$WORK/apps"
    if [ -f "$TARGET/.ai/agents" ]; then
        A_AGENTS=$(awk '!/^[[:space:]]*#/ && NF { printf "%s ", $1 }' "$TARGET/.ai/agents")
    else
        A_AGENTS=$(awk '$1 == "answer" && $2 ~ /^agents=/ { sub(/^answer[ \t]+agents=/, ""); print; exit }' "$WORK/lock.old")
    fi
    A_AGENTS=$(squeeze "$A_AGENTS")
    AGENTS_BEFORE=$A_AGENTS
    cp "$WORK/apps" "$WORK/apps.before"
    if [ -n "$ANSWERS_FILE" ]; then
        load_answers
    elif [ "$RECONFIGURE" = 1 ]; then
        can_prompt || die 'no terminal to ask on: pass --answers FILE'
        validate_answers
        ask_questions
    fi
    validate_answers
    AGENTS_CHANGED=0
    [ "$A_AGENTS" != "$AGENTS_BEFORE" ] && AGENTS_CHANGED=1
    APPS_CHANGED=0
    cmp -s "$WORK/apps" "$WORK/apps.before" || APPS_CHANGED=1
    say ''
    old=$(awk '$1 == "version" { print $2; exit }' "$WORK/lock.old")
    say "SpecForge ${old:-?} to $KIT_VERSION in $TARGET"
    show_answers
    git_report
    if [ "$RECONFIGURE" = 1 ] && [ "$DRY_RUN" = 0 ]; then confirm; fi
    install_or_update
}

main() {
    setup update 'dir answers reconfigure dry-run version from' "$@"
    cmd_update
}

# One compound command: a download cut anywhere in this line is a syntax error, not a call that
# has lost its arguments.
{ main "$@"; }
