# GitHub Metadata Hygiene

Shared baseline for every repo under this portfolio (ForumViriumHelsinki/ and
laurigates/). Scope-specific deltas live in the child rules:
- FVH org project routing + Terraform-managed labels:
  `ForumViriumHelsinki/.claude/rules/github-metadata-hygiene.md`
- laurigates gitops-managed labels: `laurigates/.claude/rules/github-metadata-hygiene.md`

## Rule: Every issue and PR must have complete metadata — enforce on every GitHub interaction

### Trigger Points

Apply these checks when:
1. **Creating** issues or PRs — set all metadata at creation time
2. **Commenting or reviewing** existing issues/PRs — check for gaps and backfill
3. **Before opening a PR** — verify the target issue has proper metadata

### Issue Metadata Checklist

| Field | Required | How to Set | Default |
|-------|----------|-----------|---------|
| Assignee | Always | `-a @laurigates` | `laurigates` unless told otherwise |
| Labels | Always | `-l <name>` | At minimum a type label: `bug`, `enhancement`, `chore`, `docs` |
| Milestone | If exists | `--milestone <name>` | Set if a relevant milestone exists for the repo |
| Issue type | If supported | MCP `issue_write` with `type` param | Check `list_issue_types` first |
| Linked PR | When applicable | PR body `Closes #N` or `gh issue develop` | Link when creating PRs that address the issue |

### PR Metadata Checklist

| Field | Required | How to Set | Default |
|-------|----------|-----------|---------|
| Reviewer | If not author | `-r <user>` | **Skip if the requested reviewer is the PR author** (GitHub API rejects self-review requests with HTTP 422) |
| Assignee | Always | `-a @laurigates` | `laurigates` unless told otherwise |
| Labels | Always | `-l <name>` | Match linked issue labels; add type label if missing |
| Linked issue | When applicable | PR body with `Closes #N` / `Fixes #N` | Reference the issue being addressed |

**Self-review guard:** Before requesting a reviewer, check the PR author. If the
requested reviewer matches the PR author, skip the `--add-reviewer` / `-r` flag
entirely. Use separate `gh` commands for reviewer vs. other metadata so a single
422 doesn't fail the whole update.

### Backfill on Existing Issues/PRs

When interacting with an issue or PR that has missing metadata:

1. Add missing assignee (and reviewer for PRs — skip if author matches reviewer)
2. Add missing type labels — infer from title and content
3. Inform the user what was added (do not silently modify)

### Label Conventions

Use these standard type labels consistently:

| Label | When |
|-------|------|
| `bug` | Defect or broken behavior |
| `enhancement` | New feature or improvement to existing feature |
| `chore` | Maintenance, dependency updates, refactoring |
| `docs` | Documentation changes |
| `security` | Security-related fixes or improvements |

Check available labels with `gh label list -R <owner>/<repo>` before applying —
do not create labels that don't exist without asking. Both scopes manage their
standard label sets via IaC (see the child rules above); ad-hoc `gh label create`
is only for genuinely repo-specific labels.
