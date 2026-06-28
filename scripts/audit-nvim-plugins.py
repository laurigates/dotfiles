# /// script
# requires-python = ">=3.11"
# dependencies = []
# ///
"""Audit configured Neovim plugins for archival/staleness and successor hints.

Extracts every ``owner/repo`` plugin spec from the lazy.nvim Lua files under
``private_dot_config/nvim/lua/exact_plugins``, queries GitHub in a single
batched GraphQL call (via the ``gh`` CLI, reusing existing auth), classifies
each plugin by last-activity age and archival status, and — for stale or
archived plugins — scans the README for deprecation / successor cues.

Output is a grouped, color-coded terminal table, worst-first.

Usage:
    uv run scripts/audit-nvim-plugins.py [--nvim-dir PATH]
"""

from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path

# ANSI colors (matches the ephemeral style of the settings-audit recipe).
RED = "\033[0;31m"
YELLOW = "\033[0;33m"
GREEN = "\033[0;32m"
CYAN = "\033[0;36m"
DIM = "\033[2m"
BOLD = "\033[1m"
RESET = "\033[0m"

# First-position quoted "owner/repo" on a Lua line (the plugin spec / dependency).
SPEC_RE = re.compile(r'^\s*"([\w.-]+/[\w.-]+)"')

# Case-insensitive cues that a plugin is deprecated / has a successor.
HINT_CUES = [
    "deprecat",
    "no longer maintained",
    "unmaintained",
    "archived",
    "superseded",
    "successor",
    "moved to",
    "replaced by",
]
USE_INSTEAD_RE = re.compile(r"use\b.*\binstead", re.IGNORECASE)
# A GitHub URL or [[owner/repo]]-style reference inside a hint line.
SUCCESSOR_REF_RE = re.compile(
    r"(?:github\.com/([\w.-]+/[\w.-]+))|(?:\[\[?([\w.-]+/[\w.-]+)\]?\])"
)

# Classification thresholds in days.
ONE_YEAR = 365
TWO_YEARS = 730


def extract_repos(nvim_dir: Path) -> list[str]:
    """Return a deduped, sorted list of ``owner/repo`` specs from the Lua files."""
    repos: set[str] = set()
    for lua_file in sorted(nvim_dir.glob("*.lua")):
        for line in lua_file.read_text(encoding="utf-8").splitlines():
            if line.lstrip().startswith("--"):
                continue
            match = SPEC_RE.match(line)
            if match:
                repos.add(match.group(1))
    return sorted(repos)


def build_graphql_query(repos: list[str]) -> str:
    """Build a single GraphQL query aliasing each repo as ``r<N>``."""
    nodes = []
    for i, repo in enumerate(repos):
        owner, name = repo.split("/", 1)
        nodes.append(
            f'r{i}: repository(owner: {json.dumps(owner)}, name: {json.dumps(name)}) {{ '
            "isArchived pushedAt url description "
            'readme: object(expression: "HEAD:README.md") { ... on Blob { text } } '
            "}"
        )
    return "query {\n" + "\n".join(nodes) + "\n}"


def run_graphql(query: str) -> dict:
    """Run the GraphQL query via ``gh api graphql`` and return the data map."""
    result = subprocess.run(
        ["gh", "api", "graphql", "-f", f"query={query}"],
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        sys.stderr.write(f"{RED}gh api graphql failed:{RESET}\n{result.stderr}\n")
        sys.exit(1)
    payload = json.loads(result.stdout)
    # Partial errors (e.g. a renamed repo) are expected; nodes are still returned.
    return payload.get("data") or {}


def find_hint(readme_text: str) -> str:
    """Return the first deprecation/successor snippet found in the README, or ''."""
    for raw_line in readme_text.splitlines():
        line = raw_line.strip()
        if not line:
            continue
        lower = line.lower()
        matched = any(cue in lower for cue in HINT_CUES) or USE_INSTEAD_RE.search(line)
        if not matched:
            continue
        snippet = line[:120]
        ref = SUCCESSOR_REF_RE.search(line)
        if ref:
            successor = ref.group(1) or ref.group(2)
            return f"→ {successor}: {snippet}"
        return snippet
    return ""


def classify(node: dict | None) -> tuple[str, int | None, str]:
    """Return (status, age_days, hint) for a repository node."""
    if node is None:
        return "UNRESOLVED", None, "repo not found (renamed/deleted?)"

    if node.get("isArchived"):
        status = "ARCHIVED"
    else:
        pushed_at = node.get("pushedAt")
        if not pushed_at:
            return "UNRESOLVED", None, ""
        pushed = datetime.fromisoformat(pushed_at.replace("Z", "+00:00"))
        age_days = (datetime.now(timezone.utc) - pushed).days
        if age_days > TWO_YEARS:
            status = "DORMANT"
        elif age_days > ONE_YEAR:
            status = "STALE"
        else:
            status = "ACTIVE"

    pushed_at = node.get("pushedAt")
    age_days = None
    if pushed_at:
        pushed = datetime.fromisoformat(pushed_at.replace("Z", "+00:00"))
        age_days = (datetime.now(timezone.utc) - pushed).days

    hint = ""
    if status in ("ARCHIVED", "DORMANT", "STALE"):
        readme = node.get("readme") or {}
        hint = find_hint(readme.get("text") or "")
    return status, age_days, hint


def fmt_age(age_days: int | None) -> str:
    """Human-friendly age string."""
    if age_days is None:
        return "?"
    if age_days < 60:
        return f"{age_days}d"
    if age_days < ONE_YEAR:
        return f"{age_days // 30}mo"
    years = age_days / ONE_YEAR
    return f"{years:.1f}y"


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    default_dir = (
        Path(__file__).resolve().parent.parent
        / "private_dot_config/nvim/lua/exact_plugins"
    )
    parser.add_argument(
        "--nvim-dir",
        type=Path,
        default=default_dir,
        help="Directory of lazy.nvim plugin spec Lua files.",
    )
    args = parser.parse_args()

    if not args.nvim_dir.is_dir():
        sys.stderr.write(f"{RED}nvim dir not found: {args.nvim_dir}{RESET}\n")
        sys.exit(1)

    repos = extract_repos(args.nvim_dir)
    print(f"{BOLD}🔍 Auditing {len(repos)} Neovim plugins…{RESET}\n")

    query = build_graphql_query(repos)
    data = run_graphql(query)

    # Collect results per status group.
    groups: dict[str, list[tuple[str, int | None, str, str]]] = {
        "ARCHIVED": [],
        "DORMANT": [],
        "STALE": [],
        "ACTIVE": [],
        "UNRESOLVED": [],
    }
    for i, repo in enumerate(repos):
        node = data.get(f"r{i}")
        status, age_days, hint = classify(node)
        url = (node or {}).get("url", "")
        groups[status].append((repo, age_days, hint, url))

    color = {
        "ARCHIVED": RED,
        "DORMANT": RED,
        "STALE": YELLOW,
        "ACTIVE": GREEN,
        "UNRESOLVED": DIM,
    }
    icon = {
        "ARCHIVED": "📦",
        "DORMANT": "💤",
        "STALE": "⚠️ ",
        "ACTIVE": "✓",
        "UNRESOLVED": "❓",
    }

    # Detailed groups worst-first.
    for status in ("ARCHIVED", "DORMANT", "STALE", "UNRESOLVED"):
        rows = sorted(groups[status], key=lambda r: r[0].lower())
        if not rows:
            continue
        c = color[status]
        print(f"{c}{BOLD}{icon[status]} {status} ({len(rows)}){RESET}")
        for repo, age_days, hint, _url in rows:
            line = f"  {c}{repo:<40}{RESET} {DIM}{fmt_age(age_days):>6}{RESET}"
            if hint:
                line += f"  {CYAN}{hint}{RESET}"
            print(line)
        print()

    # Active summary count only.
    active = groups["ACTIVE"]
    print(f"{GREEN}{BOLD}✓ ACTIVE ({len(active)}){RESET} {DIM}— pushed within 1 year{RESET}\n")

    flagged = sum(len(groups[s]) for s in ("ARCHIVED", "DORMANT", "STALE", "UNRESOLVED"))
    if flagged:
        print(
            f"{DIM}For replacement research on flagged plugins, see "
            f"https://dotfyle.com (browse by category / popularity).{RESET}"
        )


if __name__ == "__main__":
    main()
