#!/usr/bin/env bash
#
# SpecForge uninstall: takes the SpecForge rules back out of a project.
#
#   curl -fsSL https://shakilnwz.github.io/specforge/uninstall.sh | bash
#
# Run `uninstall.sh --help` for its options. install.sh adds the rules to a project, and update.sh
# brings them to a later release.
#
# It takes back only what .ai/specforge.lock records and is still unmodified: a file the project
# changed is kept. It downloads nothing. Portable: bash 3.2 or later and POSIX tools.
#
# Every statement lives in a function and the only call is on the last line, so a download cut short
# runs nothing. A release inlines lib.sh in place of the line that reads it, below.

. "$(dirname "$0")/lib.sh" || exit 1

show_help() {
    cat <<'EOF'
SpecForge uninstall: takes the SpecForge rules back out of a project.

usage: uninstall.sh [options]

options
  --dir DIR        the project directory (default: the current one)
  --dry-run        print what would change, and change nothing
  --help           this text

It deletes every file it installed that is still unmodified, the generated agent rule files, and
.ai/specforge.lock; it takes the rules' block out of AGENTS.md and CLAUDE.md. A file you changed is
kept.
EOF
}

cmd_uninstall() {
    [ -f "$LOCK" ] || die "SpecForge is not installed in $TARGET (no $LOCK_REL)"
    cp "$LOCK" "$WORK/lock.old"
    say "Uninstalling SpecForge from $TARGET"
    set +f
    for d in $AGENT_DIRS; do
        for f in "$TARGET/$d"/ai-*; do
            [ -f "$f" ] || continue
            if grep -qF "$GEN_MARK" "$f"; then drop "$f"; note removed "$(relpath "$f")"; fi
        done
    done
    set -f
    while read -r kind a b c; do
        case $kind in
            file | seed | generated | incoming)
                p=$b
                dest="$TARGET/$p"
                [ -e "$dest" ] || continue
                if [ -f "$dest" ] && [ ! -L "$dest" ] && [ "$(hash_file "$dest")" = "$a" ]; then
                    drop "$dest"
                    note removed "$p"
                else
                    note left "$p"
                fi ;;
            block)
                p=$c
                dest="$TARGET/$p"
                [ -e "$dest" ] || [ -L "$dest" ] || continue
                if [ -L "$dest" ] || [ ! -f "$dest" ]; then
                    note left "$p"
                elif [ "$b" != - ] && [ "$(hash_file "$dest")" = "$b" ]; then
                    drop "$dest"
                    note removed "$p"
                elif extract_block "$dest" > "$WORK/block.cur" && [ "$(hash_file "$WORK/block.cur")" = "$a" ]; then
                    strip_block "$dest" > "$WORK/stripped"
                    put "$WORK/stripped" "$dest"
                    note stripped "$p"
                else
                    note left "$p"
                fi ;;
        esac
    done < "$WORK/lock.old"
    drop "$LOCK"
    awk '$1 == "dir" { print $3 }' "$WORK/lock.old" | LC_ALL=C sort -r > "$WORK/dirs"
    while read -r d; do
        [ "$DRY_RUN" = 1 ] || rmdir "$TARGET/$d" 2>/dev/null || true
    done < "$WORK/dirs"
    say ''
    if [ "$DRY_RUN" = 1 ]; then say 'Dry run: nothing was changed.'; fi
    say "  removed $(count removed), block taken out of $(count stripped), kept because you changed them $(count left)"
    if [ "$(count stripped)" -gt 0 ]; then
        say '  The rules block was taken out of:'
        list stripped
    fi
    if [ "$(count left)" -gt 0 ]; then
        say '  Kept, because you changed them:'
        list left
    fi
}

main() {
    setup uninstall 'dir dry-run' "$@"
    cmd_uninstall
}

# One compound command: a download cut anywhere in this line is a syntax error, not a call that
# has lost its arguments.
{ main "$@"; }
