---
name: podio-ticket-updates
description: Sync in-progress Podio Kanban tickets with progress from their linked GitHub repos — propose description updates and progress comments, apply after approval. Use when the user asks to update Podio tickets, sync ticket progress, or post status updates to the Kanban board.
allowed-tools: mcp__podio-mcp__list_items, mcp__podio-mcp__get_item_by_app_item_id, mcp__podio-mcp__list_item_comments, mcp__podio-mcp__update_item_by_app_item_id, mcp__podio-mcp__create_item_comment, mcp__podio-mcp__inspect_field_structure, Bash(printenv *), Bash(gh api *), Bash(gh search *), Read, Grep, Glob
---

# Podio Ticket Progress Updates

Update my in-progress Podio tickets with progress from linked GitHub repositories.

## Configuration

The board coordinates are not stored in this skill. Read them from the
environment (set them in `~/.api_tokens`, which mise sources):

```bash
printenv PODIO_ORG_LABEL PODIO_SPACE_LABEL PODIO_APP_LABEL PODIO_RESPONSIBLE PODIO_GITHUB_ORG
```

| Variable | Meaning |
|---|---|
| `PODIO_ORG_LABEL` | Podio organization URL label |
| `PODIO_SPACE_LABEL` | Workspace URL label |
| `PODIO_APP_LABEL` | Kanban app URL label |
| `PODIO_RESPONSIBLE` | Your display name in Podio, as shown in the Responsible field |
| `PODIO_GITHUB_ORG` | GitHub org whose repos the tickets track |

The three labels are the path segments of the board URL:
`https://podio.com/<org>/<space>/apps/<app>/`. If any variable is unset, ask
the user for it before calling the MCP. Do not guess.

## Workflow

### 1. Fetch My In-Progress Tickets

Use `mcp__podio-mcp__list_items` to get tickets from the Kanban:
- org_label: `$PODIO_ORG_LABEL`
- space_label: `$PODIO_SPACE_LABEL`
- app_label: `$PODIO_APP_LABEL`
- status_filter: `In Progress`
- responsible_filter: `$PODIO_RESPONSIBLE`

`responsible_filter` has a known bug: it does not match tickets with multiple
assignees. Also fetch without the filter and cross-reference to find all my
tickets.

### 2. Get Ticket Details

For each ticket, use `mcp__podio-mcp__get_item_by_app_item_id` to fetch:
- Full description
- Project and Epic assignments
- Any GitHub links in the description

### 3. Identify Related Repositories

For each ticket, determine the related GitHub repo by:
1. Checking for explicit GitHub URLs in the description
2. Searching the `$PODIO_GITHUB_ORG` org for repos matching the ticket title keywords
3. Asking the user if no match is found

### 4. Fetch Git History

For each identified repo, get recent commits:
```bash
gh api "repos/$PODIO_GITHUB_ORG/{repo}/commits" --jq '.[:20] | .[] | "[\(.commit.author.date | split("T")[0])] \(.commit.message | split("\n")[0])"'
```

### 5. Get Last Comments

Use `mcp__podio-mcp__list_item_comments` to see when the ticket was last updated and what was reported.

### 6. Analyze and Propose Updates

Compare:
- Current ticket description vs. actual repo state
- Last comment date vs. recent commits
- Described work items vs. merged PRs

Propose:
- **Description updates** if stated work items are now complete or outdated
- **Progress comments** summarizing commits since last update

### 7. Review with User

Present proposed updates in a table format:

| Ticket | Description Changes | Proposed Comment |
|--------|---------------------|------------------|
| #xxx   | [changes or "None"] | [summary]        |

Wait for user approval before applying changes.

### 8. Apply Updates

After approval, use:
- `mcp__podio-mcp__update_item_by_app_item_id` for description changes
- `mcp__podio-mcp__create_item_comment` for progress comments

## Write descriptions as HTML — and verify them in the browser

A Kanban `description` field is typically configured `"format": "html"`.
Confirm it for any field you are unsure about with
`mcp__podio-mcp__inspect_field_structure`:

```json
{ "label": "Description", "settings": { "size": "large", "format": "html" } }
```

The MCP passes the string through **verbatim**, so plain text with `\n` line
breaks renders as one run-on blob — newlines are not line breaks in HTML, and
headings fuse into the paragraph after them (`WHATRetire the broker…`). Write
`<h3>`, `<p>`, `<strong>`, `<em>`, `<code>`, `<ul>`/`<ol>`/`<li>` and
`<a href>`; all of them render correctly. Use real hyperlinks for issue and PR
references rather than bare `#1234`, which is not clickable outside GitHub.

**A read-back cannot verify this.** `get_item_details` and
`get_item_by_app_item_id` strip tags on read, so a broken write and a correct
one come back **identically** — both as the same tag-free blob. Confirm
formatting by opening the item in the Podio web UI
(`https://podio.com/<org>/<space>/apps/<app>/items/<n>`), not by re-reading it
through the MCP.

`get_item_revision_diff` is not a substitute — it rejects `from_revision: 0`
and reports real changes as `undefined → undefined`.

## Repo ↔ Ticket Cross-Reference

When asked to reconcile repo activity against the board (e.g. after a
`/repo-activity` scan):
- Search ticket descriptions for repo names
- Identify active repos without associated tickets
- Flag tickets whose repos show no recent activity

## Output Format

For each ticket, provide:
1. Ticket number and title
2. Related repo (with link)
3. Commits since last update
4. Proposed description changes (if any)
5. Proposed comment text

## Notes

- Only update tickets where there's meaningful progress to report
- Keep comments concise and focused on what changed
- Use bullet points for readability
- Include PR numbers where relevant
- End comments with "Next steps:" when applicable
