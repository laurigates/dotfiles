"""uv-cache-unused.py — list uv cache packages safe to `uv cache clean --force`.

`uv cache prune` needs an exclusive lock on the cache, and every `uvx` / `uv run`
process holds a shared lock for its whole lifetime (astral-sh/uv#19317), so a
long-lived MCP server blocks the prune forever. `uv cache clean --force <pkg>`
skips the lock, and per `Cache::remove()` in uv 0.12.21 it only drops the
package's `wheels-v6/pypi/<name>` entry plus archives left unreferenced — it
never touches `environments-v2/`, the environment archives running tools
execute from. As an extra margin this script also excludes every package
installed in an environment a lock holder is running.

READ-ONLY. Prints `KEY=VALUE` / `UV_CANDIDATE …` lines; the caller decides.

Fails closed: if a lock holder is a bare uv process with no Python child (uv is
mid-resolve or mid-install, so cleaning could race it), it prints UV_BUSY=1 and
an empty package list.
"""

import argparse
import os
import re
import subprocess
import sys
from collections import defaultdict

DIST_INFO = re.compile(r"^(?P<name>.+?)-(?P<version>[^-]+)\.dist-info$")
ARCHIVE_REF = re.compile(r"/archive-v0/([^/]+)")
ENV_REF = re.compile(r"(/environments-v2/[^/]+)")


def run(*argv: str) -> str:
    return subprocess.run(argv, capture_output=True, text=True, check=False).stdout


def normalize(name: str) -> str:
    return re.sub(r"[-_.]+", "-", name).lower()


def dist_name(entry: str) -> str:
    match = DIST_INFO.match(entry)
    assert match, entry
    return normalize(match["name"])


def process_tree(pid: str) -> list[str]:
    pids = [pid]
    for child in run("pgrep", "-P", pid).split():
        pids += process_tree(child)
    return pids


def open_paths(pid: str) -> list[str]:
    return [
        line[1:]
        for line in run("lsof", "-p", pid, "-Fn").splitlines()
        if line.startswith("n")
    ]


def dist_infos(archive: str) -> list[str]:
    found = []
    for base in [archive] + [
        os.path.join(archive, "lib", d, "site-packages")
        for d in (
            os.listdir(os.path.join(archive, "lib"))
            if os.path.isdir(os.path.join(archive, "lib"))
            else []
        )
    ]:
        if os.path.isdir(base):
            found += [e for e in os.listdir(base) if DIST_INFO.match(e)]
    return found


def tree_kb(path: str) -> int:
    blocks = 0
    for root, dirs, files in os.walk(path):
        for name in dirs + files:
            try:
                blocks += os.lstat(os.path.join(root, name)).st_blocks
            except OSError:
                pass
    return blocks // 2  # st_blocks is in 512-byte units, same as du


def holders_in_use(cache: str) -> tuple[int, bool, set[str]]:
    """Return (holder count, busy flag, archive ids running processes use)."""
    holders = run("lsof", "-t", os.path.join(cache, ".lock")).split()
    busy, in_use = False, set()
    for holder in holders:
        tree = process_tree(holder)
        if not any(
            os.path.basename(run("ps", "-o", "comm=", "-p", p).strip()).startswith(
                "python"
            )
            for p in tree
        ):
            busy = True
        for pid in tree:
            # A pure-Python tool keeps no env file open, but uvx prepends the
            # env's .../archive-v0/<id>/bin to PATH (and uv tool entry points
            # name it in argv); `ps eww` shows both.
            in_use.update(
                ARCHIVE_REF.findall(run("ps", "eww", "-o", "command=", "-p", pid))
            )
            for path in open_paths(pid):
                if not path.startswith(cache):
                    continue
                in_use.update(ARCHIVE_REF.findall(path))
                for env in ENV_REF.findall(path):
                    in_use.update(ARCHIVE_REF.findall(os.path.realpath(cache + env)))
    return len(holders), busy, in_use


def main() -> int:
    ap = argparse.ArgumentParser(
        description="List uv cache packages safe to force-clean."
    )
    ap.add_argument("--cache-dir", default=run("uv", "cache", "dir").strip())
    ap.add_argument(
        "--min-mb",
        type=int,
        default=100,
        help="skip packages smaller than this in total",
    )
    args = ap.parse_args()

    cache = os.path.realpath(args.cache_dir)
    archives = os.path.join(cache, "archive-v0")
    if not os.path.isdir(archives):
        print(f"uv-cache-unused: no archive bucket under {cache}", file=sys.stderr)
        return 1

    holders, busy, in_use = holders_in_use(cache)
    protected = {
        dist_name(d) for a in in_use for d in dist_infos(os.path.join(archives, a))
    }

    # Single-package archives (one top-level .dist-info) are unpacked wheels;
    # multi-package ones are environments, which `uv cache clean` never removes.
    sizes: dict[str, list[int]] = defaultdict(lambda: [0, 0])
    for entry in os.listdir(archives):
        path = os.path.join(archives, entry)
        top = (
            [e for e in os.listdir(path) if DIST_INFO.match(e)]
            if os.path.isdir(path)
            else []
        )
        if len(top) != 1 or os.path.isdir(os.path.join(path, "lib")):
            continue
        name = dist_name(top[0])
        if name in protected:
            continue
        sizes[name][0] += tree_kb(path)
        sizes[name][1] += 1

    chosen = sorted(
        (
            (n, kb, count)
            for n, (kb, count) in sizes.items()
            if kb >= args.min_mb * 1024
        ),
        key=lambda t: -t[1],
    )
    print(f"UV_HOLDERS={holders}")
    print(f"UV_BUSY={int(busy)}")
    print(f"UV_PROTECTED_PACKAGES={len(protected)}")
    for name, kb, count in chosen:
        print(f"UV_CANDIDATE name={name} size_kb={kb} archives={count}")
    print(f"UV_CANDIDATE_KB={sum(kb for _, kb, _ in chosen)}")
    print("UV_CLEAN_PACKAGES=" + ("" if busy else " ".join(n for n, _, _ in chosen)))
    return 0


if __name__ == "__main__":
    sys.exit(main())
