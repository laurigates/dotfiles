#!/usr/bin/env bash
# Regression test: CI must not take its toolchain from upstream at run time
# (issues #416 and #418).
#
# Both issues are the same failure class: a version or ref that no string in
# this repo chooses, so an upstream release or branch deletion turns main red
# with no commit here. An unversioned `brew install chezmoi` picked up
# chezmoi 2.72.0, a minor release that rejected this repo's .chezmoiignore;
# the deletion of the Homebrew/actions `master` branch broke every job that
# referenced `setup-homebrew@master`.
#
# Static checks (default mode, offline; run by the `ci-pins` pre-commit hook):
#   A. Workflow `uses:` refs. A third-party ref named like a branch (main,
#      master, ...) fails; a 40-hex SHA needs a trailing `# <tag>` comment.
#      laurigates/.github reusable workflows are first-party and stay on @main.
#   B. chezmoi comes from one pin. .mise.toml pins chezmoi to an exact X.Y.Z;
#      no tracked non-Markdown file installs chezmoi another way (brew, apt,
#      installer script, release download, `mise use`, `chezmoi@<v>`); a mise
#      tool entry for chezmoi outside .mise.toml must read the pin through
#      `include ".mise.toml"`; any explicit chezmoi version equals the pin.
#   C. Per workflow job: a job that runs chezmoi sets up jdx/mise-action; a job
#      that sets up mise or runs chezmoi runs `--assert-installed`; a job that
#      runs `chezmoi apply` also runs `--assert-installed --rendered`.
#   D. Every jdx/mise-action step pins `version:` to one exact mise release.
#
# Out of scope by design: the Homebrew `chezmoi` entry in
# .chezmoidata/packages.toml. It bootstraps a machine before any mise config
# exists, and `mise activate` puts the pinned chezmoi ahead of it on PATH
# (tests/test-shell-precedence.sh pins that order).
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
PKG_INSTALL_RE='(brew|apt|apt-get|snap|dnf|yum|pacman|apk|zypper|port|nix-env)[[:space:]]+(install|add|-S)([[:space:]]+[^#[:space:]]+)*[[:space:]]+([^#[:space:]]*/)?chezmoi([[:space:];&|"'"'"']|$)'
OTHER_INSTALL_RE='go[[:space:]]+install[^#]*chezmoi|get\.chezmoi\.io|chezmoi\.io/get|twpayne/chezmoi/releases|(^|[^[:alnum:]_/.-])chezmoi@|mise[[:space:]]+(use|u)[[:space:]][^#]*chezmoi'
# A mise [tools] entry for chezmoi, any backend.
TOOL_ENTRY_RE='^[[:space:]]*"?((aqua|ubi|github|asdf|vfox|core):)?(twpayne/)?chezmoi"?[[:space:]]*='
# An explicit chezmoi version next to the word chezmoi.
VERSION_RE='chezmoi([_-]?version)?[@ =:"'"'"'v-]+[0-9]+\.[0-9]+\.[0-9]+'

fails=0
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
        in_step = 0; step_mise = 0; step_ver = ""
    }
    function flush_job() {
        flush_step()
        if (job != "") {
            printf "J\t%s\t%s\n", jfile, job
            if (runs && !mise) printf "F\t%s: job %s runs chezmoi but has no jdx/mise-action step\n", jfile, job
            if ((runs || mise) && !asserted) printf "F\t%s: job %s installs or runs chezmoi but never runs %s --assert-installed\n", jfile, job, self
            if (applies && !rendered) printf "F\t%s: job %s runs chezmoi apply but never runs %s --assert-installed --rendered\n", jfile, job, self
        }
        job = ""; runs = 0; mise = 0; asserted = 0; applies = 0; rendered = 0
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
        if (match(line, /(^|[[:space:]])uses:[[:space:]]*/)) {
            rest = substr(line, RSTART + RLENGTH)
            comment = ""
            c = index(rest, "#")
            if (c > 0) { comment = substr(rest, c + 1); rest = substr(rest, 1, c - 1) }
            gsub("[[:space:]\"" q "]", "", rest)
            sub(/^[[:space:]]+/, "", comment); sub(/[[:space:]]+$/, "", comment)
            printf "R\t%s\t%d\t%s\t%s\n", FILENAME, FNR, rest, comment
            if (rest ~ /^jdx\/mise-action@/) { mise = 1; if (in_step) step_mise = 1 }
        }
        if (!injobs || job == "") next
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

check_workflows() {
    local repo="$1" online="$2" wfs=() f
    while IFS= read -r f; do
        case "$f" in
            .github/workflows/*.yml | .github/workflows/*.yaml) [ -f "$repo/$f" ] && wfs+=("$f") ;;
        esac
    done < <(list_files "$repo")
    if [ "${#wfs[@]}" -eq 0 ]; then
        # The Docker smoke build context excludes .github/ (see .dockerignore).
        echo "SKIP: no .github/workflows files; workflow checks A, C and D not run"
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

run_static() {
    local repo="$1" online="${2:-0}"
    check_workflows "$repo" "$online"
    check_chezmoi_pin "$repo"
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
      - name: Run chezmoi apply
        run: chezmoi apply -v --source=. --exclude=scripts
      - run: tests/test-ci-pins.sh --assert-installed --rendered
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: echo "no chezmoi in this job"
  reusable:
    uses: laurigates/.github/.github/workflows/reusable-renovate.yml@main
    with:
      additional_permissions: |
        Bash(chezmoi diff *)
EOF
    printf 'chezmoi = "{{ (fromToml (include ".mise.toml")).tools.chezmoi }}"\n' \
        >"$d/private_dot_config/mise/config.toml.tmpl"
    printf 'FROM ubuntu:24.04\nRUN brew install neovim\n' >"$d/Dockerfile"
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
    selftest_case "guard: workflows with no parseable uses: fail" fail "parsed 0 uses:" \
        "printf 'name: x\non: push\njobs:\n  a:\n    runs-on: x\n    steps:\n      - run: true\n' >$wf"

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
    echo "$fails failure(s). See tests/test-ci-pins.sh for what each check guards (#416, #418)."
    exit 1
fi
exit 0
