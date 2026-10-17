#!/usr/bin/env bash
# Regression test: CI must not take its toolchain from upstream at run time
# (issues #416, #418 and #440).
#
# All three are the same failure class: a version or ref that no string in
# this repo chooses, so an upstream release or branch deletion turns main red
# with no commit here. An unversioned `brew install chezmoi` picked up
# chezmoi 2.72.0, a minor release that rejected this repo's .chezmoiignore;
# the deletion of the Homebrew/actions `master` branch broke every job that
# referenced `setup-homebrew@master`; `python-version: '3.x'` and an unpinned
# `pip install pre-commit` let a Python or pre-commit release change the
# Linters job, which gates both Build jobs.
#
# Static checks (default mode, offline; run by the `ci-pins` pre-commit hook):
#   A. `uses:` refs in workflows and composite actions (.github/actions/*). A
#      third-party ref named like a branch (main, master, ...) fails; a 40-hex
#      SHA needs a trailing `# <tag>` comment. laurigates/.github reusable
#      workflows are first-party and stay on @main.
#   B. chezmoi comes from one pin. .mise.toml pins chezmoi to an exact X.Y.Z;
#      no tracked non-Markdown file installs chezmoi another way (brew
#      install/upgrade, apt, installer script, release download, `mise use`,
#      `chezmoi@<v>`, `chezmoi latest` in .tool-versions form,
#      MISE_CHEZMOI_VERSION); a mise tool entry for chezmoi outside .mise.toml
#      must read the pin through `include ".mise.toml"`; any explicit chezmoi
#      version equals the pin.
#   C. Per workflow job: a job that runs chezmoi sets up jdx/mise-action; a job
#      that sets up mise or runs chezmoi runs `--assert-installed`; a job that
#      runs `chezmoi apply` also runs `--assert-installed --rendered`.
#   D. Every jdx/mise-action step pins `version:` to one exact mise release; a
#      job with mise-action does not also restore ~/.local/share/mise with
#      actions/cache (that can put an older mise binary back); a mise.run
#      install sets MISE_VERSION to the same release.
#   E. Tools CI installs outside mise. `python-version:` and `bun-version:` are
#      an exact X.Y.Z, not `3.x` or `latest`. pre-commit and
#      @anthropic-ai/claude-code are installed at an exact version, written
#      inline (`pre-commit==4.7.0`) or read from PRE_COMMIT_VERSION /
#      CLAUDE_CODE_VERSION. Such a variable is an exact X.Y.Z, defined in the
#      file that reads it, equal in every workflow, and has the line
#      `# renovate: datasource=<ds> depName=<name>` directly above it: that is
#      what the customManagers entry in renovate.json5 matches to bump it.
#      node-version is not covered; it stays a major-only pin.
#
# Out of scope by design: the Homebrew `chezmoi` entry in
# .chezmoidata/packages.toml. It bootstraps a machine before any mise config
# exists, and `mise activate` puts the pinned chezmoi ahead of it on PATH
# (tests/test-shell-precedence.sh pins that order).
#
# Known limits of the static checks: C sees chezmoi only as a literal
# `chezmoi <subcommand>` in a step, not through a wrapper such as `just apply`;
# C and D do not parse composite actions. A job reaching chezmoi only through a
# wrapper is caught only if it already runs --assert-installed.
#
# Other modes:
#   --online     static checks, then resolve every non-SHA third-party ref with
#                `git ls-remote`: fail when it names a branch and no tag
#                (benchmark-action/github-action-benchmark@v1 is a branch), and
#                fail when a SHA pin's `# <tag>` comment does not resolve to it.
#   --assert-installed [--rendered]
#                runtime check for CI jobs and the Docker smoke: `chezmoi
#                --version` on PATH equals the pin. With --rendered, the global
#                mise config written by `chezmoi apply` must name the pin too.
#   --self-test  run the static and runtime checks against planted fixtures;
#                every bad fixture must fail and the good one must pass.
#
# Needs bash, git, grep, sed and awk only: the Linters job has no rg or yq.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
SELF="tests/test-ci-pins.sh"
SELF_PATH="$SCRIPT_DIR/$(basename "${BASH_SOURCE[0]}")"

# First-party reusable workflows track @main on purpose, so org-wide workflow
# fixes reach this repo without a PR here.
ALLOW_PREFIX='laurigates/.github/'
# Ref names that are branches in practice. --online resolves everything else.
BRANCH_NAMES='main|master|develop|dev|trunk|stable|nightly|beta|HEAD'
SEMVER_RE='^[0-9]+\.[0-9]+\.[0-9]+$'

# Install routes other than the pin. `[^#]` stops a match at a trailing comment.
PKG_INSTALL_RE='(brew|apt|apt-get|snap|dnf|yum|pacman|apk|zypper|port|nix-env)[[:space:]]+(install|reinstall|upgrade|add|-S)([[:space:]]+[^#[:space:]]+)*[[:space:]]+([^#[:space:]]*/)?chezmoi([[:space:];&|"'"'"']|$)'
# Also: a .tool-versions-style `chezmoi latest` (a file, or mise-action's
# tool_versions input) and mise's per-tool version override variable.
OTHER_INSTALL_RE='go[[:space:]]+install[^#]*chezmoi|get\.chezmoi\.io|chezmoi\.io/get|twpayne/chezmoi/releases|(^|[^[:alnum:]_/.-])chezmoi@|mise[[:space:]]+(use|u)[[:space:]][^#]*chezmoi|(^|[^[:alnum:]_/.-])chezmoi[[:space:]]+(latest|stable|lts|system|ref:|prefix:|sub-|path:)|MISE_CHEZMOI_VERSION'
# A mise [tools] entry for chezmoi, any backend.
TOOL_ENTRY_RE='^[[:space:]]*"?((aqua|ubi|github|asdf|vfox|core):)?(twpayne/)?chezmoi"?[[:space:]]*='
# An explicit chezmoi version next to the word chezmoi.
VERSION_RE='chezmoi([_-]?version)?[@ =:"'"'"'v-]+[0-9]+\.[0-9]+\.[0-9]+'

fails=0
MISE_ACTION_VERSION=""
fail() { printf 'FAIL: %s\n' "$*"; fails=$((fails + 1)); }

# read_pin <repo>: the chezmoi version in <repo>/.mise.toml, empty if none.
read_pin() {
    [ -f "$1/.mise.toml" ] || return 0
    sed -nE 's/^[[:space:]]*chezmoi[[:space:]]*=[[:space:]]*"([^"]*)".*/\1/p' "$1/.mise.toml"
}

# list_files <repo>: tracked files. Self-test fixtures are plain directories.
list_files() {
    if [ "${CI_PINS_LIST:-git}" = find ]; then
        (cd "$1" && find . -type f | sed 's|^\./||')
    else
        git -C "$1" ls-files
    fi
}

# drop_comments: keep `file:line:text` grep hits whose text is not a comment.
drop_comments() { grep -vE '^[^:]+:[0-9]+:[[:space:]]*#' || true; }

# --- B. chezmoi comes from the .mise.toml pin --------------------------------
check_chezmoi_pin() {
    local repo="$1" pin n f
    pin=$(read_pin "$repo")
    n=$(printf '%s' "$pin" | grep -c . || true)
    if [ ! -f "$repo/.mise.toml" ]; then
        fail ".mise.toml is missing; it must pin chezmoi = \"X.Y.Z\""
    elif [ "$n" -ne 1 ]; then
        fail ".mise.toml must pin chezmoi exactly once (found $n entries)"
        pin=""
    elif ! grep -Eq "$SEMVER_RE" <<<"$pin"; then
        fail ".mise.toml pins chezmoi to '$pin', not an exact X.Y.Z"
        pin=""
    fi

    local files=()
    while IFS= read -r f; do
        case "$f" in
            *.md | "$SELF" | .mise.toml) continue ;;
        esac
        [ -f "$repo/$f" ] && files+=("$f")
    done < <(list_files "$repo")
    if [ "${#files[@]}" -eq 0 ]; then
        fail "no files to scan under $repo (file listing is broken)"
        return
    fi

    local hit
    while IFS= read -r hit; do
        [ -n "$hit" ] && fail "chezmoi installed outside the .mise.toml pin: $hit"
    done < <(cd "$repo" && grep -nIHE "$PKG_INSTALL_RE|$OTHER_INSTALL_RE" -- "${files[@]}" | drop_comments)

    while IFS= read -r hit; do
        case "$hit" in
            *'include ".mise.toml"'*) ;;
            ?*) fail "mise tool entry names its own chezmoi version instead of including .mise.toml: $hit" ;;
        esac
    done < <(cd "$repo" && grep -nIHE "$TOOL_ENTRY_RE" -- "${files[@]}" | drop_comments)

    if [ -n "$pin" ]; then
        while IFS= read -r hit; do
            [ -n "$hit" ] || continue
            local v
            v=$(printf '%s' "${hit#*:*:}" | grep -ioE "$VERSION_RE" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
            [ "$v" = "$pin" ] || fail "chezmoi $v named, but .mise.toml pins $pin: $hit"
        done < <(cd "$repo" && grep -nIHiE "$VERSION_RE" -- "${files[@]}" | drop_comments)
    fi
}

# --- A/C/D. Workflow refs, per-job mise setup, mise-action version -----------
# One awk pass per workflow file. Output records (tab-separated):
#   R <file> <line> <target> <comment>   a `uses:` ref
#   J <file> <job>                       a parsed job
#   F <message>                          a per-job/step failure
#   V <version>                          a jdx/mise-action `version:` value
parse_workflow() {
    awk '
    function flush_step() {
        if (in_step && step_mise) {
            if (step_ver == "") printf "F\t%s:%d: jdx/mise-action step has no version: input\n", jfile, step_line
            else printf "V\t%s\n", step_ver
        }
        if (in_step && step_cache && step_misedir && !cache_line) cache_line = step_line
        in_step = 0; step_mise = 0; step_ver = ""; step_cache = 0; step_misedir = 0
    }
    function flush_job() {
        flush_step()
        if (job != "") {
            printf "J\t%s\t%s\n", jfile, job
            if (runs && !mise) printf "F\t%s: job %s runs chezmoi but has no jdx/mise-action step\n", jfile, job
            if ((runs || mise) && !asserted) printf "F\t%s: job %s installs or runs chezmoi but never runs %s --assert-installed\n", jfile, job, self
            if (applies && !rendered) printf "F\t%s: job %s runs chezmoi apply but never runs %s --assert-installed --rendered\n", jfile, job, self
            # mise-action caches the mise data dir under a key built from the
            # mise version. A second cache of it can restore an older mise
            # binary over the pinned one.
            if (mise && cache_line) printf "F\t%s:%d: job %s restores ~/.local/share/mise with actions/cache, which can replace the mise that jdx/mise-action pinned; mise-action caches that dir itself\n", jfile, cache_line, job
        }
        job = ""; runs = 0; mise = 0; asserted = 0; applies = 0; rendered = 0; cache_line = 0
        insteps = 0; step_indent = -1
    }
    # One awk run covers every workflow, so close the last job of the previous file.
    FNR == 1 { flush_job(); injobs = 0 }
    /^[[:space:]]*#/ { next }
    /^jobs:/ { injobs = 1; next }
    injobs && /^[^[:space:]]/ { flush_job(); injobs = 0 }
    injobs && /^  [A-Za-z0-9_-]+:[[:space:]]*(#.*)?$/ {
        flush_job(); job = $1; sub(/:$/, "", job); jfile = FILENAME; next
    }
    injobs && job != "" && /^[[:space:]]+steps:/ { insteps = 1; step_indent = -1 }
    injobs && insteps && /^[[:space:]]*- / {
        ind = match($0, /-/) - 1
        if (step_indent < 0) step_indent = ind
        if (ind == step_indent) { flush_step(); in_step = 1; step_line = FNR }
    }
    {
        line = $0
        # A step or job `uses:` key only, so `run: echo "uses: x"` is not a ref.
        if (match(line, /^[[:space:]]*(-[[:space:]]+)?uses:[[:space:]]*/)) {
            rest = substr(line, RSTART + RLENGTH)
            comment = ""
            c = index(rest, "#")
            if (c > 0) { comment = substr(rest, c + 1); rest = substr(rest, 1, c - 1) }
            gsub("[[:space:]\"" q "]", "", rest)
            sub(/^[[:space:]]+/, "", comment); sub(/[[:space:]]+$/, "", comment)
            printf "R\t%s\t%d\t%s\t%s\n", FILENAME, FNR, rest, comment
            if (rest ~ /^jdx\/mise-action@/) { mise = 1; if (in_step) step_mise = 1 }
            if (rest ~ /^actions\/cache(\/restore)?@/ && in_step) step_cache = 1
        }
        if (!injobs || job == "") next
        if (in_step && line ~ /\.local\/share\/mise|MISE_DATA_DIR/) step_misedir = 1
        if (in_step && match(line, /^[[:space:]]*version:[[:space:]]*/)) {
            v = substr(line, RSTART + RLENGTH); sub(/[[:space:]]*#.*$/, "", v); gsub("[\"" q "]", "", v)
            step_ver = v
        }
        if (line ~ /^[[:space:]]*(- )?name:/) next
        # Only steps run commands. A reusable-workflow call job has none, and
        # its `with:` inputs can carry permission strings like Bash(chezmoi diff *).
        if (in_step && line ~ runs_re) {
            runs = 1
            if (line ~ /chezmoi[[:space:]]+apply/ && line !~ /--dry-run|[[:space:]]-n([[:space:]]|$)/) applies = 1
        }
        if (index(line, self) && line ~ /--assert-installed/) {
            asserted = 1
            if (line ~ /--rendered/) rendered = 1
        }
    }
    END { flush_job() }
    ' self="$SELF" q="'" \
        runs_re='(^|[[:space:]"'"'"'(;&|])chezmoi[[:space:]]+(apply|execute-template|managed|verify|diff|init|status|add|re-add|cat|update|archive|dump|data|doctor|source-path|merge|unmanaged|--version)' \
        "$@"
}

# ls_remote <owner/repo> <ref>...: `git ls-remote` against GitHub, no prompts.
ls_remote() {
    local repo="$1"
    shift
    GIT_TERMINAL_PROMPT=0 git ls-remote "https://github.com/$repo.git" "$@" 2>&1
}

# resolve_ref <owner/repo> <ref>: prints tag|branch|missing|error:<msg>
resolve_ref() {
    local out
    if ! out=$(ls_remote "$1" "refs/heads/$2" "refs/tags/$2"); then
        printf 'error:%s' "$(printf '%s' "$out" | head -1)"
        return
    fi
    if grep -qE "[[:space:]]refs/tags/$2(\\^\\{\\})?$" <<<"$out"; then
        printf tag
    elif grep -qE "[[:space:]]refs/heads/$2$" <<<"$out"; then
        printf branch
    else
        printf missing
    fi
}

# tag_sha <owner/repo> <tag>: the commit a tag points at (peeled), empty if none.
tag_sha() {
    local out peeled
    # An annotated tag lists its peeled commit only when ^{} is asked for too.
    out=$(ls_remote "$1" "refs/tags/$2" "refs/tags/$2^{}") || { printf 'error'; return; }
    peeled=$(printf '%s\n' "$out" | awk -v t="refs/tags/$2^{}" '$2 == t { print $1 }')
    if [ -n "$peeled" ]; then
        printf '%s' "$peeled"
    else
        printf '%s\n' "$out" | awk -v t="refs/tags/$2" '$2 == t { print $1 }'
    fi
}

# workflow_files <repo>: tracked workflows and composite actions, repo-relative.
workflow_files() {
    local f
    while IFS= read -r f; do
        case "$f" in
            .github/workflows/*.yml | .github/workflows/*.yaml | \
                .github/actions/*/action.yml | .github/actions/*/action.yaml)
                [ -f "$1/$f" ] && printf '%s\n' "$f"
                ;;
        esac
    done < <(list_files "$1")
}

check_workflows() {
    local repo="$1" online="$2" wfs=() f
    # Composite actions are parsed for their `uses:` refs (check A) only.
    while IFS= read -r f; do wfs+=("$f"); done < <(workflow_files "$repo")
    if [ "${#wfs[@]}" -eq 0 ]; then
        # The Docker smoke build context excludes .github/ (see .dockerignore).
        echo "SKIP: no .github/workflows files; workflow checks A, C, D and E not run"
        return
    fi

    local records
    records=$(cd "$repo" && parse_workflow "${wfs[@]}")

    local n_uses n_jobs
    n_uses=$(grep -c '^R' <<<"$records" || true)
    n_jobs=$(grep -c '^J' <<<"$records" || true)
    [ "$n_uses" -gt 0 ] || fail "parsed 0 uses: lines from ${#wfs[@]} workflow files (parser is broken)"
    [ "$n_jobs" -gt 0 ] || fail "parsed 0 jobs from ${#wfs[@]} workflow files (parser is broken)"

    local msg
    while IFS= read -r msg; do
        [ -n "$msg" ] && fail "$msg"
    done < <(printf '%s\n' "$records" | awk -F'\t' '$1 == "F" { print $2 }')

    local versions
    versions=$(printf '%s\n' "$records" | awk -F'\t' '$1 == "V" { print $2 }' | sort -u)
    while IFS= read -r msg; do
        [ -z "$msg" ] || grep -Eq "$SEMVER_RE" <<<"$msg" ||
            fail "jdx/mise-action version: '$msg' is not an exact mise release"
    done <<<"$versions"
    if [ "$(printf '%s' "$versions" | grep -c . || true)" -gt 1 ]; then
        fail "jdx/mise-action steps pin different mise versions: $(printf '%s' "$versions" | tr '\n' ' ')"
    elif grep -Eq "$SEMVER_RE" <<<"$versions"; then
        MISE_ACTION_VERSION="$versions"
    fi

    local cache="" file lineno target comment
    while IFS="$(printf '\t')" read -r _ file lineno target comment; do
        local loc="$file:$lineno" path ref rest repo_slug verdict tag key
        case "$target" in ./* | docker://*) continue ;; esac
        case "$target" in
            *@*) ;;
            *) fail "$loc: uses: $target has no @ref"; continue ;;
        esac
        path="${target%@*}"
        ref="${target##*@}"
        case "$target" in "$ALLOW_PREFIX"*) continue ;; esac
        # owner/repo of owner/repo[/path/to/action]; no forks per ref.
        rest="${path#*/}"
        repo_slug="${path%%/*}/${rest%%/*}"

        if [[ $ref =~ ^[0-9a-f]{40}$ ]]; then
            tag="${comment%% *}"
            if [ -z "$tag" ]; then
                fail "$loc: $path@$ref is a SHA with no '# <tag>' comment"
                continue
            fi
            [ "$online" = 1 ] || continue
            key="sha $repo_slug $tag"
            verdict=$(printf '%s\n' "$cache" | awk -v k="$key" 'index($0, k "=") == 1 { print substr($0, length(k) + 2); exit }')
            if [ -z "$verdict" ]; then
                verdict=$(tag_sha "$repo_slug" "$tag")
                [ -n "$verdict" ] || verdict=missing
                cache="$cache$key=$verdict"$'\n'
            fi
            [ "$verdict" = "$ref" ] ||
                fail "$loc: comment tag $tag of $repo_slug resolves to '$verdict', not the pinned $ref"
        elif [[ $ref =~ ^($BRANCH_NAMES)$ ]]; then
            fail "$loc: $path@$ref is a branch; pin a release SHA with a '# <tag>' comment"
        elif [ "$online" = 1 ]; then
            key="ref $repo_slug $ref"
            verdict=$(printf '%s\n' "$cache" | awk -v k="$key" 'index($0, k "=") == 1 { print substr($0, length(k) + 2); exit }')
            if [ -z "$verdict" ]; then
                verdict=$(resolve_ref "$repo_slug" "$ref")
                cache="$cache$key=$verdict"$'\n'
            fi
            case "$verdict" in
                tag) ;;
                branch) fail "$loc: $path@$ref is a branch, not a tag; pin a release SHA with a '# <tag>' comment" ;;
                missing) fail "$loc: $path@$ref matches no tag or branch in $repo_slug" ;;
                *) fail "$loc: could not resolve $path@$ref ($verdict)" ;;
            esac
        fi
    done < <(printf '%s\n' "$records" | grep '^R')
}

# --- D (outside workflows). The mise.run installer pins the CI mise release ---
# https://mise.run installs whatever mise released last unless MISE_VERSION is
# set. The Docker smoke image uses it; it must match jdx/mise-action's version:.
check_mise_installers() {
    local repo="$1" files=() f hit v
    while IFS= read -r f; do
        case "$f" in
            *.md | "$SELF") continue ;;
        esac
        [ -f "$repo/$f" ] && files+=("$f")
    done < <(list_files "$repo")
    [ "${#files[@]}" -gt 0 ] || return 0
    while IFS= read -r hit; do
        [ -n "$hit" ] || continue
        v=$(printf '%s' "${hit#*:*:}" | sed -nE 's/.*MISE_VERSION=v?([0-9][0-9.]*).*/\1/p')
        if [ -z "$v" ]; then
            fail "mise.run install does not pin MISE_VERSION: $hit"
        elif [ -n "$MISE_ACTION_VERSION" ] && [ "$v" != "$MISE_ACTION_VERSION" ]; then
            fail "mise.run install pins mise $v, but jdx/mise-action pins $MISE_ACTION_VERSION: $hit"
        fi
    done < <(cd "$repo" && grep -nIHE 'mise\.run' -- "${files[@]}" | drop_comments)
}

# --- E. Tools CI installs outside mise ---------------------------------------
# drop_names: drop `file:line:text` grep hits on a step `name:` line.
drop_names() { grep -vE '^[^:]+:[0-9]+:[[:space:]]*(-[[:space:]]+)?name:' || true; }

# tool_var_defs <VAR> <file>...: one tab-separated record per `VAR: value` line:
# file, line, the value without quotes or comment, and the line above it.
tool_var_defs() {
    local var="$1"
    shift
    awk -v var="$var" -v q="'" '
        FNR == 1 { prev = "" }
        {
            if (match($0, "^[[:space:]]*" var ":[[:space:]]*")) {
                v = substr($0, RLENGTH + 1)
                sub(/[[:space:]]*#.*$/, "", v)
                gsub("[\"" q "]", "", v)
                if (v == "") v = "<empty>"
                printf "%s\t%d\t%s\t%s\n", FILENAME, FNR, v, prev
            }
            prev = $0
        }' "$@"
}

# check_version_inputs <repo> <file>...: the python-version and bun-version
# inputs of setup-python and setup-bun.
check_version_inputs() {
    local repo="$1" hit loc key v
    shift
    while IFS= read -r hit; do
        [ -n "$hit" ] || continue
        loc=$(printf '%s' "$hit" | cut -d: -f1,2)
        key=$(printf '%s' "${hit#*:*:}" | sed -E 's/^[[:space:]]*([a-z]+-version):.*/\1/')
        v=$(printf '%s' "${hit#*:*:}" | sed -E 's/^[[:space:]]*[a-z]+-version:[[:space:]]*//; s/[[:space:]]*#.*$//; s/^["'"'"']//; s/["'"'"']$//')
        grep -Eq "$SEMVER_RE" <<<"$v" ||
            fail "$loc: $key '$v' is not an exact X.Y.Z; a floating tool changes CI with no commit here (#440)"
    done < <(cd "$repo" && grep -nIHE '^[[:space:]]*(python|bun)-version:' -- "$@" | drop_comments)
}

# check_tool_install <repo> <label> <install regex> <pin prefix> <VAR> <datasource> <depName> <file>...
# Every line matching <install regex> carries <pin prefix><exact X.Y.Z or $VAR>.
# <VAR> is defined in each file that reads it, as an exact X.Y.Z under a
# `# renovate: datasource=<datasource> depName=<depName>` line, and every
# pinned version of the tool is the same.
check_tool_install() {
    local repo="$1" label="$2" install_re="$3" prefix="$4" var="$5" ds="$6" dep="$7"
    shift 7
    local hit loc file text val refs="" versions="" defs
    while IFS= read -r hit; do
        [ -n "$hit" ] || continue
        loc=$(printf '%s' "$hit" | cut -d: -f1,2)
        file="${hit%%:*}"
        text="${hit#*:*:}"
        text="${text#"${text%%[![:space:]]*}"}"
        val=$(printf '%s' "$text" | sed -nE "s~.*${prefix}([^[:space:]\"';&|)]+).*~\1~p")
        case "$val" in
            "") fail "$loc: $label is installed without ${prefix}<exact X.Y.Z or \$$var>: $text" ;;
            "\$$var" | "\${$var}") refs="$refs$file"$'\n' ;;
            *)
                if grep -Eq "$SEMVER_RE" <<<"$val"; then
                    versions="$versions$val"$'\n'
                else
                    fail "$loc: $label is pinned to '$val', not an exact X.Y.Z or \$$var"
                fi
                ;;
        esac
    done < <(cd "$repo" && grep -nIHE "$install_re" -- "$@" | drop_comments | drop_names)

    defs=$(cd "$repo" && tool_var_defs "$var" "$@")
    while IFS= read -r file; do
        [ -n "$file" ] || continue
        printf '%s\n' "$defs" | awk -F'\t' -v f="$file" '$1 == f { found = 1 } END { exit !found }' ||
            fail "$file: reads \$$var for $label but does not define $var"
    done < <(printf '%s' "$refs" | sort -u)

    local d_file d_line d_val d_prev
    while IFS="$(printf '\t')" read -r d_file d_line d_val d_prev; do
        [ -n "$d_file" ] || continue
        if grep -Eq "$SEMVER_RE" <<<"$d_val"; then
            versions="$versions$d_val"$'\n'
        else
            fail "$d_file:$d_line: $var '$d_val' is not an exact X.Y.Z"
        fi
        grep -Eq "^[[:space:]]*#[[:space:]]*renovate:[[:space:]]+datasource=${ds}[[:space:]]+depName=${dep}([[:space:]]|\$)" <<<"$d_prev" ||
            fail "$d_file:$d_line: $var needs '# renovate: datasource=$ds depName=$dep' on the line above, or Renovate cannot bump it"
    done <<<"$defs"

    if [ "$(printf '%s' "$versions" | sort -u | grep -c . || true)" -gt 1 ]; then
        fail "$label is pinned to different versions: $(printf '%s' "$versions" | sort -u | tr '\n' ' ')"
    fi
}

check_tool_pins() {
    local repo="$1" files=() f
    # check_workflows already printed the SKIP when there are no workflows.
    while IFS= read -r f; do files+=("$f"); done < <(workflow_files "$repo")
    [ "${#files[@]}" -gt 0 ] || return 0
    check_version_inputs "$repo" "${files[@]}"
    local pip_re='(^|[^[:alnum:]_-])(pip3?|pipx|uv)[[:space:]]+((tool|pip)[[:space:]]+)?install[[:space:]]+([^#]*[[:space:]])?["'"'"']?pre-commit(["'"'"'[:space:];&|=<>~!]|$)'
    check_tool_install "$repo" pre-commit "$pip_re" 'pre-commit==' \
        PRE_COMMIT_VERSION pypi pre-commit "${files[@]}"
    check_tool_install "$repo" "Claude Code CLI" '@anthropic-ai/claude-code' '@anthropic-ai/claude-code@' \
        CLAUDE_CODE_VERSION npm @anthropic-ai/claude-code "${files[@]}"
}

run_static() {
    local repo="$1" online="${2:-0}"
    MISE_ACTION_VERSION=""
    check_workflows "$repo" "$online"
    check_chezmoi_pin "$repo"
    check_mise_installers "$repo"
    check_tool_pins "$repo"
}

# --- Runtime assertion --------------------------------------------------------
assert_installed() {
    local repo="$1" rendered="$2" pin got bin cfg rpin
    pin=$(read_pin "$repo")
    if ! grep -Eq "$SEMVER_RE" <<<"$pin"; then
        fail "$repo/.mise.toml has no exact chezmoi pin (got '$pin')"
        return
    fi
    if ! bin=$(command -v chezmoi); then
        fail "chezmoi is not on PATH; .mise.toml pins $pin"
        return
    fi
    got=$(chezmoi --version 2>/dev/null | sed -nE 's/^chezmoi version v?([0-9][0-9A-Za-z.+-]*),.*/\1/p')
    if [ "$got" = "$pin" ]; then
        echo "ok: $bin is chezmoi $got, the .mise.toml pin"
    else
        fail "$bin is chezmoi '${got:-unknown}', but .mise.toml pins $pin"
    fi
    [ "$rendered" = 1 ] || return 0
    cfg="${MISE_GLOBAL_CONFIG_FILE:-${MISE_CONFIG_DIR:-${XDG_CONFIG_HOME:-$HOME/.config}/mise}/config.toml}"
    if [ ! -f "$cfg" ]; then
        fail "no rendered global mise config at $cfg (run after chezmoi apply)"
        return
    fi
    rpin=$(sed -nE 's/^[[:space:]]*chezmoi[[:space:]]*=[[:space:]]*"([^"]*)".*/\1/p' "$cfg")
    if [ "$rpin" = "$pin" ]; then
        echo "ok: $cfg pins chezmoi $rpin"
    else
        fail "$cfg pins chezmoi '${rpin:-<none>}', but .mise.toml pins $pin"
    fi
}

# --- Self-test ------------------------------------------------------------------
write_good_fixture() {
    local d="$1"
    mkdir -p "$d/.github/workflows" "$d/private_dot_config/mise" "$d/scripts"
    printf '[tools]\nchezmoi = "1.2.3"\n' >"$d/.mise.toml"
    cat >"$d/.github/workflows/ci.yml" <<'EOF'
name: CI
on: push
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Setup Homebrew
        uses: Homebrew/actions/setup-homebrew@848c272c7bfe984a197bd4d16383f4c106ec61e6 # 2026.09.21.1
      # brew install chezmoi used to live here; a comment is not an install
      - run: brew install neovim zsh
      - name: Setup mise
        uses: jdx/mise-action@v4
        with:
          version: 2026.9.12
      - run: tests/test-ci-pins.sh --assert-installed
      - name: Cache Homebrew
        uses: actions/cache@v4
        with:
          path: /home/linuxbrew/.cache/Homebrew
          key: brew
      - name: Run chezmoi apply
        run: chezmoi apply -v --source=. --exclude=scripts
      - run: tests/test-ci-pins.sh --assert-installed --rendered
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: echo "no chezmoi in this job"
  tools:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/setup-python@v6
        with:
          python-version: '3.14.8'
      - uses: oven-sh/setup-bun@v2
        with:
          bun-version: 1.4.3
      - name: Install pre-commit
        env:
          # renovate: datasource=pypi depName=pre-commit
          PRE_COMMIT_VERSION: 4.7.0
        run: pip install "pre-commit==$PRE_COMMIT_VERSION"
      - name: Install Claude CLI
        env:
          # renovate: datasource=npm depName=@anthropic-ai/claude-code
          CLAUDE_CODE_VERSION: 2.1.302
        run: npm install -g "@anthropic-ai/claude-code@${CLAUDE_CODE_VERSION}"
  reusable:
    uses: laurigates/.github/.github/workflows/reusable-renovate.yml@main
    with:
      additional_permissions: |
        Bash(chezmoi diff *)
EOF
    printf 'chezmoi = "{{ (fromToml (include ".mise.toml")).tools.chezmoi }}"\n' \
        >"$d/private_dot_config/mise/config.toml.tmpl"
    printf 'FROM ubuntu:24.04\nRUN brew install neovim\nRUN curl https://mise.run | MISE_VERSION=v2026.9.12 sh\n' >"$d/Dockerfile"
    printf '#!/bin/sh\nmise install chezmoi\n' >"$d/scripts/setup.sh"
    printf '{ "allow": ["Bash(chezmoi diff *)"] }\n' >"$d/tools.json"
}

# selftest_case <name> <expect: pass|fail> <needle> <mutation shell snippet>
st_total=0
st_bad=0
selftest_case() {
    local name="$1" expect="$2" needle="$3" mutation="$4" d out rc
    st_total=$((st_total + 1))
    d=$(mktemp -d "${TMPDIR:-/tmp}/ci-pins-selftest.XXXXXX")
    write_good_fixture "$d"
    (cd "$d" && eval "$mutation" && rm -f ./*.bak ./*/*.bak ./*/*/*.bak)
    out=$(env CI_PINS_LIST=find "$BASH" "$SELF_PATH" --check-dir "$d" 2>&1)
    rc=$?
    rm -rf "$d"
    if [ "$expect" = pass ] && [ "$rc" -eq 0 ]; then
        echo "ok - $name"
    elif [ "$expect" = fail ] && [ "$rc" -ne 0 ] && grep -qF -- "$needle" <<<"$out"; then
        echo "ok - $name"
    else
        echo "not ok - $name (expected $expect, exit $rc, wanted message: ${needle:-none})"
        printf '%s\n' "$out" | sed 's/^/    /'
        st_bad=$((st_bad + 1))
    fi
}

# selftest_assert <name> <expect> <stub version> <rendered flag> <rendered cfg content or ->
selftest_assert() {
    local name="$1" expect="$2" stubver="$3" rflag="$4" cfg="$5" d out rc
    st_total=$((st_total + 1))
    d=$(mktemp -d "${TMPDIR:-/tmp}/ci-pins-selftest.XXXXXX")
    write_good_fixture "$d"
    mkdir -p "$d/bin" "$d/home/.config/mise"
    printf '#!/bin/sh\necho "chezmoi version v%s, commit selftest-stub, built at never"\n' "$stubver" >"$d/bin/chezmoi"
    chmod +x "$d/bin/chezmoi"
    [ "$cfg" = - ] || printf '%s\n' "$cfg" >"$d/home/.config/mise/config.toml"
    out=$(PATH="$d/bin:$PATH" HOME="$d/home" XDG_CONFIG_HOME="$d/home/.config" \
        MISE_GLOBAL_CONFIG_FILE="" MISE_CONFIG_DIR="" \
        "$BASH" "$SELF_PATH" --check-dir "$d" --assert-installed ${rflag:+"$rflag"} 2>&1)
    rc=$?
    rm -rf "$d"
    # Every message names the chezmoi binary it ran; it must be the stub.
    if ! grep -qF "$d/bin/chezmoi" <<<"$out"; then
        echo "not ok - $name (stub chezmoi was not the one on PATH)"
        st_bad=$((st_bad + 1))
    elif { [ "$expect" = pass ] && [ "$rc" -eq 0 ]; } || { [ "$expect" = fail ] && [ "$rc" -ne 0 ]; }; then
        echo "ok - $name"
    else
        echo "not ok - $name (expected $expect, exit $rc)"
        printf '%s\n' "$out" | sed 's/^/    /'
        st_bad=$((st_bad + 1))
    fi
}

self_test() {
    local wf=.github/workflows/ci.yml
    selftest_case "good fixture passes" pass "" ":"
    selftest_case "commented-out brew install is not an install" pass "" \
        "printf '# RUN brew install chezmoi\n' >>Dockerfile"
    selftest_case "A: @master branch ref fails" fail "is a branch" \
        "sed -i.bak 's|setup-homebrew@848c272c7bfe984a197bd4d16383f4c106ec61e6 # 2026.09.21.1|setup-homebrew@master|' $wf"
    selftest_case "A: @main branch ref fails" fail "is a branch" \
        "sed -i.bak 's|actions/checkout@v4|actions/checkout@main|' $wf"
    selftest_case "A: SHA without a tag comment fails" fail "no '# <tag>' comment" \
        "sed -i.bak 's| # 2026.09.21.1||' $wf"
    selftest_case "A: third-party reusable workflow on @main fails" fail "is a branch" \
        "sed -i.bak 's|laurigates/.github/.github|someone/else/.github|' $wf"
    selftest_case "B: missing .mise.toml fails" fail ".mise.toml is missing" "rm .mise.toml"
    selftest_case "B: fuzzy pin 'latest' fails" fail "not an exact X.Y.Z" \
        "printf '[tools]\nchezmoi = \"latest\"\n' >.mise.toml"
    selftest_case "B: brew install chezmoi in a workflow fails" fail "installed outside" \
        "sed -i.bak 's|brew install neovim zsh|brew install chezmoi neovim zsh|' $wf"
    selftest_case "B: brew install chezmoi in a Dockerfile fails" fail "installed outside" \
        "printf 'RUN brew install neovim chezmoi\n' >>Dockerfile"
    selftest_case "B: installer script fails" fail "installed outside" \
        "printf 'sh -c \"\$(curl -fsSL https://www.chezmoi.io/get)\" -- -b ~/.local/bin\n' >>scripts/setup.sh"
    selftest_case "B: release download fails" fail "installed outside" \
        "printf 'curl -LO https://github.com/twpayne/chezmoi/releases/download/v1.2.3/x.tar.gz\n' >>scripts/setup.sh"
    selftest_case "B: a second version via mise use fails" fail "installed outside" \
        "printf '      - run: mise use -g chezmoi@2.71.1\n' >>$wf"
    selftest_case "B: global mise template with its own version fails" fail "instead of including .mise.toml" \
        "printf 'chezmoi = \"latest\"\n' >private_dot_config/mise/config.toml.tmpl"
    selftest_case "B: a different explicit chezmoi version fails" fail "but .mise.toml pins 1.2.3" \
        "printf 'CHEZMOI_VERSION=9.9.9 ./install\n' >>scripts/setup.sh"
    selftest_case "C: job running chezmoi without mise-action fails" fail "has no jdx/mise-action step" \
        "awk '!/jdx\\/mise-action|version: 2026/' $wf >x && mv x $wf"
    selftest_case "C: job with mise-action but no assertion fails" fail "never runs tests/test-ci-pins.sh --assert-installed" \
        "grep -v 'test-ci-pins.sh' $wf >x && mv x $wf"
    selftest_case "C: apply job without --rendered assertion fails" fail "--assert-installed --rendered" \
        "grep -v -- '--rendered' $wf >x && mv x $wf"
    selftest_case "D: mise-action without version: fails" fail "has no version: input" \
        "grep -v 'version: 2026.9.12' $wf >x && mv x $wf"
    selftest_case "D: two different mise versions fail" fail "different mise versions" \
        "printf '  other:\n    runs-on: ubuntu-latest\n    steps:\n      - uses: jdx/mise-action@v4\n        with:\n          version: 2026.1.1\n      - run: tests/test-ci-pins.sh --assert-installed\n' >>$wf"
    selftest_case "C: failures name the right file and job across workflows" fail "z.yml: job zjob runs chezmoi" \
        "printf 'on: push\njobs:\n  zjob:\n    runs-on: x\n    steps:\n      - run: chezmoi apply --source=.\n' >.github/workflows/z.yml"
    selftest_case "A: third-party ref on a branch in a composite action fails" fail "is a branch" \
        "mkdir -p .github/actions/setup && printf 'name: setup\nruns:\n  using: composite\n  steps:\n    - uses: someone/thing@main\n' >.github/actions/setup/action.yml"
    selftest_case "A: 'uses:' inside a run string is not a ref" pass "" \
        "sed -i.bak 's|echo \"no chezmoi in this job\"|echo \"this step uses: nothing\"|' $wf"
    selftest_case "B: brew upgrade chezmoi fails" fail "installed outside" \
        "printf 'RUN brew upgrade chezmoi\n' >>Dockerfile"
    selftest_case "B: .tool-versions with chezmoi latest fails" fail "installed outside" \
        "printf 'chezmoi latest\n' >.tool-versions"
    selftest_case "B: mise-action tool_versions input with chezmoi latest fails" fail "installed outside" \
        "awk '{ print } /version: 2026.9.12/ { print \"          tool_versions: chezmoi latest\" }' $wf >x && mv x $wf"
    selftest_case "B: MISE_CHEZMOI_VERSION override fails" fail "installed outside" \
        "printf 'ENV MISE_CHEZMOI_VERSION=latest\n' >>Dockerfile"
    selftest_case "D: actions/cache of the mise data dir in a mise-action job fails" fail "restores ~/.local/share/mise" \
        "printf '  cached:\n    runs-on: ubuntu-latest\n    steps:\n      - uses: jdx/mise-action@v4\n        with:\n          version: 2026.9.12\n      - run: tests/test-ci-pins.sh --assert-installed\n      - name: Cache mise tools\n        uses: actions/cache@v4\n        with:\n          path: |\n            ~/.local/share/mise\n          key: x\n' >>$wf"
    selftest_case "D: mise.run install without MISE_VERSION fails" fail "mise.run install does not pin MISE_VERSION" \
        "sed -i.bak 's|MISE_VERSION=v2026.9.12 ||' Dockerfile"
    selftest_case "D: mise.run install at another mise version fails" fail "but jdx/mise-action pins 2026.9.12" \
        "sed -i.bak 's|MISE_VERSION=v2026.9.12|MISE_VERSION=v2026.1.1|' Dockerfile"
    selftest_case "guard: workflows with no parseable uses: fail" fail "parsed 0 uses:" \
        "printf 'name: x\non: push\njobs:\n  a:\n    runs-on: x\n    steps:\n      - run: true\n' >$wf"

    # E. Tools CI installs outside mise (#440). The 'run: pip install' and
    # 'run: npm install' patterns each match exactly one fixture line.
    selftest_case "E: python-version 3.x fails" fail "python-version '3.x' is not an exact" \
        "sed -i.bak 's|3.14.8|3.x|' $wf"
    selftest_case "E: python-version without a patch fails" fail "python-version '3.14' is not an exact" \
        "sed -i.bak 's|3.14.8|3.14|' $wf"
    selftest_case "E: bun-version latest fails" fail "bun-version 'latest' is not an exact" \
        "sed -i.bak 's|bun-version: 1.4.3|bun-version: latest|' $wf"
    selftest_case "E: a quoted python-version with a comment passes" pass "" \
        "sed -i.bak 's|python-version: .3.14.8.|python-version: \"3.14.8\" # why|' $wf"
    selftest_case "E: unpinned pip install pre-commit fails" fail "pre-commit is installed without" \
        "sed -i.bak 's|run: pip install .*|run: pip install pre-commit|' $wf"
    selftest_case "E: pre-commit with a version range fails" fail "pre-commit is installed without" \
        "sed -i.bak 's|run: pip install .*|run: pip install pre-commit>=4|' $wf"
    selftest_case "E: pre-commit==latest fails" fail "pre-commit is pinned to 'latest'" \
        "sed -i.bak 's|run: pip install .*|run: pip install pre-commit==latest|' $wf"
    selftest_case "E: uv tool install pre-commit fails" fail "pre-commit is installed without" \
        "sed -i.bak 's|run: pip install .*|run: uv tool install pre-commit|' $wf"
    selftest_case "E: python -m pip install pre-commit among other packages fails" fail "pre-commit is installed without" \
        "sed -i.bak 's|run: pip install .*|run: python -m pip install --upgrade pip pre-commit|' $wf"
    selftest_case "E: pre-commit pinned inline to the variable's version passes" pass "" \
        "sed -i.bak 's|run: pip install .*|run: pip install pre-commit==4.7.0|' $wf"
    selftest_case "E: inline pre-commit pin differing from the variable fails" fail "pre-commit is pinned to different versions" \
        "sed -i.bak 's|run: pip install .*|run: pip install pre-commit==4.6.0|' $wf"
    selftest_case "E: pre-commit pinned differently in a second workflow fails" fail "pre-commit is pinned to different versions" \
        "printf 'on: push\njobs:\n  y:\n    runs-on: x\n    steps:\n      - uses: actions/checkout@v4\n      - run: pip install pre-commit==4.6.0\n' >.github/workflows/y.yml"
    selftest_case "E: PRE_COMMIT_VERSION that is not exact fails" fail "PRE_COMMIT_VERSION 'latest' is not an exact" \
        "sed -i.bak 's|PRE_COMMIT_VERSION: 4.7.0|PRE_COMMIT_VERSION: latest|' $wf"
    selftest_case "E: PRE_COMMIT_VERSION without a renovate comment fails" fail "needs '# renovate: datasource=pypi depName=pre-commit'" \
        "grep -v 'datasource=pypi' $wf >x && mv x $wf"
    selftest_case "E: renovate comment naming another package fails" fail "needs '# renovate: datasource=pypi depName=pre-commit'" \
        "sed -i.bak 's|depName=pre-commit|depName=precommit|' $wf"
    selftest_case "E: PRE_COMMIT_VERSION read but never defined fails" fail "reads \$PRE_COMMIT_VERSION" \
        "grep -v 'PRE_COMMIT_VERSION: 4.7.0' $wf >x && mv x $wf"
    selftest_case "E: a commented-out unpinned install is not an install" pass "" \
        "printf '      # - run: pip install pre-commit\n' >>$wf"
    selftest_case "E: a step named like an install is not an install" pass "" \
        "sed -i.bak 's|name: Install pre-commit|name: pip install pre-commit|' $wf"
    selftest_case "E: pre-commit install and pre-commit-hooks are not installs of pre-commit" pass "" \
        "printf '  hooks:\n    runs-on: x\n    steps:\n      - run: pre-commit install --install-hooks\n      - run: pip install pre-commit-hooks\n' >>$wf"
    selftest_case "E: unpinned npm install of the Claude Code CLI fails" fail "Claude Code CLI is installed without" \
        "sed -i.bak 's|run: npm install .*|run: npm install -g @anthropic-ai/claude-code|' $wf"
    selftest_case "E: Claude Code CLI @latest fails" fail "Claude Code CLI is pinned to 'latest'" \
        "sed -i.bak 's|run: npm install .*|run: npm install -g @anthropic-ai/claude-code@latest|' $wf"
    selftest_case "E: npx of the Claude Code CLI without a version fails" fail "Claude Code CLI is installed without" \
        "printf '  y:\n    runs-on: x\n    steps:\n      - run: npx @anthropic-ai/claude-code --version\n' >>$wf"
    selftest_case "E: CLAUDE_CODE_VERSION that is not exact fails" fail "CLAUDE_CODE_VERSION '^2.1.302' is not an exact" \
        "sed -i.bak 's|CLAUDE_CODE_VERSION: 2.1.302|CLAUDE_CODE_VERSION: ^2.1.302|' $wf"
    selftest_case "E: CLAUDE_CODE_VERSION without a renovate comment fails" fail "needs '# renovate: datasource=npm depName=@anthropic-ai/claude-code'" \
        "grep -v 'datasource=npm' $wf >x && mv x $wf"
    selftest_case "E: Claude Code CLI pinned inline passes" pass "" \
        "sed -i.bak 's|run: npm install .*|run: npm install -g @anthropic-ai/claude-code@2.1.302|' $wf"

    selftest_assert "runtime: chezmoi at the pin passes" pass 1.2.3 "" -
    selftest_assert "runtime: chezmoi at another version fails" fail 9.9.9 "" -
    selftest_assert "runtime: rendered config at the pin passes" pass 1.2.3 --rendered 'chezmoi = "1.2.3"'
    selftest_assert "runtime: rendered config with 'latest' fails" fail 1.2.3 --rendered 'chezmoi = "latest"'
    selftest_assert "runtime: missing rendered config fails" fail 1.2.3 --rendered -

    echo "self-test: $((st_total - st_bad))/$st_total cases behaved as expected"
    [ "$st_bad" -eq 0 ]
}

# --- Main -------------------------------------------------------------------------
repo="$REPO_DIR"
mode=static
online=0
rendered=0
while [ $# -gt 0 ]; do
    case "$1" in
        --online) online=1 ;;
        --assert-installed) mode=assert ;;
        --rendered) rendered=1 ;;
        --self-test) mode=self ;;
        --check-dir) repo="$2"; shift ;;
        -h | --help) sed -n '2,/^$/p' "$SELF_PATH" | sed 's/^# \{0,1\}//'; exit 0 ;;
        *) echo "unknown argument: $1" >&2; exit 2 ;;
    esac
    shift
done

case "$mode" in
    self)
        self_test
        exit $?
        ;;
    assert)
        assert_installed "$repo" "$rendered"
        ;;
    static)
        run_static "$repo" "$online"
        if [ "$fails" -eq 0 ]; then
            echo "PASS: CI toolchain pins hold (chezmoi $(read_pin "$repo"), online=$online)"
        fi
        ;;
esac

if [ "$fails" -ne 0 ]; then
    echo "$fails failure(s). See tests/test-ci-pins.sh for what each check guards (#416, #418, #440)."
    exit 1
fi
exit 0
