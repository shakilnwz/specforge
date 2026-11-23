#!/usr/bin/env bash
#
# release.sh: check the kit, then build one release's three assets. It publishes nothing.
#
#   ./release.sh v1.2.0 --repo <org>/specforge [--out DIR]
#
# Assets, in DIR (a new temporary directory by default):
#   install.sh                         the installer, its version and repository stamped in
#   specforge-<version>.tar.gz         template/, manifest and VERSION under specforge-<version>/
#   specforge-<version>.tar.gz.sha256  "<sha256>  specforge-<version>.tar.gz"
#
# Checks, before anything is built:
#   every script parses; every manifest line names a known selector and mode and an existing path;
#   template/ carries no generated agent file, no lock, no incoming file, and no agent enabled;
#   .ai/bin/sync-rules --check passes on a scratch copy of template/ (Boost-identical index);
#   install.sh carries each stamp exactly once, and knows the agents sync-rules knows and the
#   profiles the manifest selects.
#
# Portable: bash 3.2 or later and POSIX tools. No git, no network.

set -u

die() { printf 'release: %s\n' "$*" >&2; exit 1; }
problem() { printf 'release: %s\n' "$*" >&2; problems=$((problems + 1)); }

hash_file() {
    if command -v sha256sum >/dev/null 2>&1; then sha256sum < "$1" | awk '{ print $1 }'
    elif command -v shasum >/dev/null 2>&1; then shasum -a 256 < "$1" | awk '{ print $1 }'
    else openssl dgst -sha256 < "$1" | awk '{ print $NF }'
    fi
}

check_kit() {
    problems=0

    for f in install.sh release.sh template/.ai/bin/*; do
        bash -n "$f" 2>/dev/null || problem "$f does not parse"
    done

    while read -r sel path mode extra; do
        case $sel in '' | '#'*) continue ;; esac
        if [ "$sel" = implies ]; then
            for p in "$path" "$mode"; do
                case " laravel dotnet nextjs react vue " in *" $p "*) ;; *) problem "manifest: unknown profile '$p'" ;; esac
            done
            continue
        fi
        case $sel in
            always | profile=laravel | profile=dotnet | profile=nextjs | profile=react | profile=vue | \
            gherkin=yes | gherkin=no | host=github | host=other) ;;
            *) problem "manifest: unknown selector '$sel'" ;;
        esac
        case ${mode:-file} in file | block | seed | generated) ;; *) problem "manifest: unknown mode '$mode'" ;; esac
        [ -z "${extra:-}" ] || problem "manifest: trailing text on the line for $path"
        [ -e "template/$path" ] || problem "manifest: template/$path does not exist"
        case ${mode:-file} in
            block)
                grep -qxF '<!-- specforge:begin -->' "template/$path" && grep -qxF '<!-- specforge:end -->' "template/$path" ||
                    problem "manifest: template/$path is a block file without both specforge markers" ;;
        esac
    done < manifest

    for d in .claude .cursor .github/instructions .windsurf .devin .agents .agent .kiro .gemini; do
        [ -e "template/$d" ] && problem "template/$d exists: generated agent files are never shipped"
    done
    found=$(find template \( -name '*.specforge-incoming' -o -name 'specforge.lock' -o -name '*.specforge-tmp.*' \) -print)
    [ -z "$found" ] || problem "template/ carries installer output: $found"
    enabled=$(awk '!/^[[:space:]]*#/ && NF' template/.ai/agents)
    [ -z "$enabled" ] || problem "template/.ai/agents enables an agent: $enabled (ship them all commented out)"

    agents_ins=$(sed -n "s/^KNOWN_AGENTS='\(.*\)'$/\1/p" install.sh)
    agents_sync=$(sed -n "s/^KNOWN='\(.*\)'$/\1/p" template/.ai/bin/sync-rules)
    [ -n "$agents_ins" ] && [ "$agents_ins" = "$agents_sync" ] ||
        problem "install.sh KNOWN_AGENTS ($agents_ins) differs from sync-rules KNOWN ($agents_sync)"
    profiles_ins=$(sed -n "s/^KNOWN_PROFILES='\(.*\)'$/\1/p" install.sh | tr ' ' '\n' | LC_ALL=C sort | tr '\n' ' ')
    profiles_man=$(sed -n 's/^profile=\([a-z]*\) .*/\1/p' manifest | LC_ALL=C sort -u | tr '\n' ' ')
    [ "$profiles_ins" = "$profiles_man" ] ||
        problem "install.sh KNOWN_PROFILES ($profiles_ins) differs from the manifest's profiles ($profiles_man)"

    for token in '@SPECFORGE_VERSION@' '@SPECFORGE_REPO@'; do
        n=$(grep -cF "$token" install.sh)
        [ "$n" = 1 ] || problem "install.sh carries $token $n times, not once"
    done

    scratch=$(mktemp -d "${TMPDIR:-/tmp}/specforge-release.XXXXXX") || die 'cannot create a temporary directory'
    cp -Rp template/. "$scratch/"
    if ! sync_out=$("$scratch/.ai/bin/sync-rules" --check 2>&1); then
        problem "sync-rules --check fails on template/:"
        printf '%s\n' "$sync_out" | sed 's/^/    /' >&2
    fi
    rm -rf "$scratch"

    [ "$problems" = 0 ] || die "$problems problem(s): nothing was built"
}

build() {
    stage=$(mktemp -d "${TMPDIR:-/tmp}/specforge-stage.XXXXXX") || die 'cannot create a temporary directory'
    trap 'rm -rf "$stage"' EXIT
    name="specforge-$version"
    mkdir "$stage/$name"
    cp -Rp template "$stage/$name/template"
    cp -p manifest "$stage/$name/manifest"
    printf '%s\n' "$version" > "$stage/$name/VERSION"
    (cd "$stage" && tar -czf "$out/$name.tar.gz" "$name") || die 'cannot build the tarball'
    printf '%s  %s\n' "$(hash_file "$out/$name.tar.gz")" "$name.tar.gz" > "$out/$name.tar.gz.sha256"
    sed -e "s|@SPECFORGE_VERSION@|$version|" -e "s|@SPECFORGE_REPO@|$repo|" install.sh > "$out/install.sh"
    chmod 755 "$out/install.sh"
}

main() {
    version=${1-}
    [ $# -gt 0 ] && shift
    repo=
    out=
    while [ $# -gt 0 ]; do
        case $1 in
            --repo) [ $# -ge 2 ] || die '--repo needs <org>/<name>'; repo=$2; shift 2 ;;
            --out) [ $# -ge 2 ] || die '--out needs a directory'; out=$2; shift 2 ;;
            *) die "unknown option: $1" ;;
        esac
    done
    case $version in
        v[0-9]*.[0-9]*.[0-9]*) ;;
        *) die 'usage: ./release.sh vX.Y.Z --repo <org>/specforge [--out DIR]' ;;
    esac
    case $version in *[!v0-9.]*) die "not a version: $version" ;; esac
    case $repo in
        */*) ;;
        *) die '--repo <org>/specforge is required: it is stamped into install.sh' ;;
    esac
    case $repo in *[!A-Za-z0-9._/-]* | */*/* ) die "not a repository: $repo" ;; esac

    cd "$(dirname "$0")" || die 'cannot enter the kit'
    check_kit

    if [ -z "$out" ]; then
        out=$(mktemp -d "${TMPDIR:-/tmp}/specforge-$version.XXXXXX") || die 'cannot create the output directory'
    else
        mkdir -p "$out" || die "cannot create $out"
        out=$(cd "$out" && pwd -P)
    fi
    build

    printf 'Built SpecForge %s in %s\n' "$version" "$out"
    (cd "$out" && ls -l install.sh "specforge-$version.tar.gz" "specforge-$version.tar.gz.sha256")
    printf '\nPublish, after reviewing them:\n'
    printf '  gh release create %s %s/install.sh %s/specforge-%s.tar.gz %s/specforge-%s.tar.gz.sha256 --repo %s --title "SpecForge %s"\n' \
        "$version" "$out" "$out" "$version" "$out" "$version" "$repo" "$version"
}

main "$@"
