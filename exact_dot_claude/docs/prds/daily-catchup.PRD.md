# Daily Catch-Up Command PRD

## Executive Summary

**Problem Statement:**
Developers with ADHD face challenges starting their day due to scattered information across multiple services (GitHub, Podio, Gmail, Google Chat). Context switching between platforms leads to hyperfocusing on low-priority items, task-jumping, or missing critical issues entirely. The cognitive load of manually aggregating and prioritizing daily tasks creates decision paralysis.

**Proposed Solution:**
A Claude Code slash command `/sync:daily` that automatically aggregates action items from integrated services, categorizes them by urgency and type, and generates a structured daily note in the user's Obsidian vault. The command tracks execution time to avoid duplicate items and presents information in an ADHD-friendly format optimized for quick scanning and actionable decision-making.

**Business Impact:**
- Reduces daily startup time from 30-45 minutes (manual aggregation) to <2 minutes (automated)
- Decreases context-switching overhead by 80% (single consolidated view)
- Improves task prioritization through consistent categorization
- Reduces missed deadlines by surfacing blocked/urgent items proactively
- Increases productive work time by eliminating manual information gathering

**Target Release:** Version 1.0 - Initial MVP with GitHub and Podio integration

---

## Stakeholders & Personas

### Primary Stakeholders
- **Accountable**: User (lgates) - Product owner, end user, acceptance authority
- **Responsible**: Claude Code implementation agent - Command development and integration
- **Consulted**: Claude Code requirements-documentation agent - PRD creation and validation
- **Informed**: Dotfiles repository maintainers - Integration with chezmoi structure

### User Persona: Alex - Developer with ADHD

**Demographics:**
- Role: Full-stack developer managing infrastructure and feature work
- Tools: GitHub (code), Podio (project management), Gmail (async comms), Google Chat (team chat)
- Workflow: Daily planning session before deep work, uses Obsidian for task tracking

**Needs & Pain Points:**
- **Need**: Single consolidated view of daily action items across all services
- **Pain**: Context switching between 4+ services leads to distraction and hyperfocus on wrong tasks
- **Need**: Clear urgency/priority indicators to guide task selection
- **Pain**: Analysis paralysis when deciding what to work on first
- **Need**: Historical tracking of daily summaries for retrospective analysis
- **Pain**: Missing blocked items or urgent requests buried in notification noise
- **Need**: ADHD-friendly presentation (scannable, categorized, action-oriented)
- **Pain**: Cognitive overload from unstructured information streams

**User Goals:**
1. Start each day knowing exactly what needs attention
2. Quickly identify blocked work that requires unblocking
3. Separate actionable items from informational updates
4. Maintain focus by avoiding unnecessary service navigation
5. Build consistent daily planning habit through friction reduction

### Stakeholder Matrix (RACI)

| Activity | User | Claude Agent | Chezmoi Repo | MCP Servers |
|----------|------|--------------|--------------|-------------|
| Define requirements | A | R | I | I |
| Create PRD | C | R | I | - |
| Implement command | A | R | I | - |
| Integrate MCP servers | A | R | - | C |
| Test integration | R/A | C | - | - |
| Deploy to production | R/A | C | - | - |
| Maintain command | R/A | - | C | - |

---

## User Stories & Acceptance Criteria

### Epic: Daily Aggregation System

#### US-1: As a developer with ADHD, I want to run a single command that fetches all my action items so I can start my day organized

**Acceptance Criteria:**
- ✅ Command `/sync:daily` executes without errors
- ✅ Fetches data from GitHub (issues assigned to me, PR reviews requested)
- ✅ Fetches data from Podio (tasks assigned to me, updated tickets)
- ✅ Fetches data from Gmail (unread emails matching filters)
- ✅ Fetches data from Google Chat (unread mentions/DMs)
- ✅ Completes execution in <30 seconds for typical daily volume
- ✅ Displays progress indicators during data fetching
- ✅ Handles API failures gracefully with clear error messages

**Definition of Done:**
- Command runs successfully from Claude Code terminal
- All four service integrations return data
- Error handling tested for each service failure scenario
- Performance meets <30s target for 50 combined items

---

#### US-2: As a developer with ADHD, I want items categorized by urgency/type so I can quickly identify what needs immediate attention

**Acceptance Criteria:**
- ✅ Items organized into categories:
  - 🔴 **Action Needed - Urgent**: Blocking issues, requested PR reviews, overdue tasks
  - 🟡 **Action Needed - Normal**: Assigned issues, assigned Podio tasks, direct messages requiring response
  - 🔵 **FYI - Informational**: PR comments, ticket updates, team announcements
  - ⚫ **Blocked**: Items waiting on external dependencies, blocked PRs, stalled tickets
  - 🟢 **Follow-Up**: Items requiring monitoring but not immediate action
- ✅ Each category shows item count in header
- ✅ Categories sorted by priority (Urgent → Normal → FYI → Blocked → Follow-Up)
- ✅ Empty categories omitted from output
- ✅ Each item includes: title, source, link, brief context, timestamp

**Categorization Logic:**
- **Urgent**: GitHub PRs with "urgent" label OR reviews requested >24h ago, Podio tasks with "high" priority OR overdue
- **Normal**: GitHub issues assigned to user, Podio tasks assigned to user with normal priority, unread DMs
- **FYI**: GitHub comments on watched repos, Podio ticket updates (not assigned), email notifications
- **Blocked**: GitHub PRs with "blocked" label, Podio tasks with "waiting" status
- **Follow-Up**: GitHub issues with "waiting-on-reporter" label, Podio tasks in "pending" status

**Definition of Done:**
- Categorization logic implemented and tested
- Each category has distinct emoji marker for visual scanning
- Item metadata includes all required fields
- Categories render in correct priority order
- Empty category filtering works correctly

---

#### US-3: As a developer with ADHD, I want the summary saved to my Obsidian vault so I can reference it throughout the day

**Acceptance Criteria:**
- ✅ Creates daily note at `~/Documents/FVH Vault/Daily Notes/YYYY-MM-DD.md`
- ✅ Uses consistent Markdown formatting optimized for Obsidian
- ✅ Includes metadata frontmatter: date, command execution time, service fetch status
- ✅ Generates backlinks to relevant project notes (if vault structure supports)
- ✅ Overwrites existing daily note if run multiple times same day
- ✅ Creates directory structure if it doesn't exist
- ✅ File permissions set correctly (644)

**Obsidian Note Format:**
```markdown
---
date: 2025-11-12
generated: 2025-11-12 08:30:15
services: [github, podio, gmail, gchat]
command: /sync:daily
version: 1.0.0
---

# Daily Catch-Up - November 12, 2025

Generated at 8:30 AM | Last fetch: 8:29 AM

## Summary
- 🔴 Urgent: 3 items
- 🟡 Normal: 7 items
- 🔵 FYI: 12 items
- ⚫ Blocked: 2 items

---

## 🔴 Action Needed - Urgent (3)

### [PR Review] Fix authentication vulnerability (#456)
**Source:** GitHub - user/repo
**Link:** https://github.com/user/repo/pull/456
**Context:** Review requested 2 days ago, security fix required before merge
**Tags:** #security #critical

[Additional items...]

---

## 🟡 Action Needed - Normal (7)

[Items...]

---

## 🔵 FYI - Informational (12)

[Items...]

---

## ⚫ Blocked (2)

[Items...]

---

## Fetch Status
- ✅ GitHub: 15 items fetched
- ✅ Podio: 8 items fetched
- ⚠️ Gmail: 5 items fetched (2 errors)
- ✅ Google Chat: 3 items fetched
```

**Definition of Done:**
- Daily note creates successfully in correct location
- Markdown formatting renders correctly in Obsidian
- Frontmatter includes all required metadata
- File creation tested on both macOS and Linux
- Directory creation handles missing paths
- Multiple runs same day overwrite cleanly

---

#### US-4: As a developer with ADHD, I want the command to track when it last ran so I only see new items since my last check

**Acceptance Criteria:**
- ✅ Stores last execution timestamp in `~/.config/claude-code/sync:daily-state.json`
- ✅ First run creates state file and fetches items from last 24 hours
- ✅ Subsequent runs fetch items since last execution timestamp
- ✅ State file includes: last_run timestamp, service-specific cursors (if supported)
- ✅ Handles state file corruption gracefully (recreate with defaults)
- ✅ Option to force full refresh with `--full-refresh` flag
- ✅ State file permissions set correctly (600 - user only)

**State File Format:**
```json
{
  "version": "1.0.0",
  "last_run": "2025-11-12T08:30:15Z",
  "services": {
    "github": {
      "last_fetch": "2025-11-12T08:30:10Z",
      "cursor": "Y3Vyc29yOnYyOpK5MjAyM..."
    },
    "podio": {
      "last_fetch": "2025-11-12T08:30:12Z",
      "last_item_id": 123456
    },
    "gmail": {
      "last_fetch": "2025-11-12T08:30:13Z",
      "history_id": "9876543"
    },
    "gchat": {
      "last_fetch": "2025-11-12T08:30:14Z",
      "last_message_time": "2025-11-12T08:25:00Z"
    }
  }
}
```

**Definition of Done:**
- State file creates on first run
- Timestamp updates after successful execution
- Service-specific cursors save correctly
- State file corruption recovery tested
- --full-refresh flag bypasses state and fetches last 24h
- File permissions restrict access to user only

---

#### US-5: As a developer with ADHD, I want clear feedback during execution so I know the command is working and not frozen

**Acceptance Criteria:**
- ✅ Displays progress indicators for each service fetch
- ✅ Shows real-time count of items fetched per service
- ✅ Indicates when categorization is processing
- ✅ Displays file write confirmation with path
- ✅ Shows total execution time at completion
- ✅ Uses color-coded status indicators (green = success, yellow = warning, red = error)
- ✅ Provides actionable error messages with recovery suggestions

**Progress Output Example:**
```
🔄 Daily Catch-Up - Starting...

Fetching from services:
  ✅ GitHub: 15 items (2.3s)
  ✅ Podio: 8 items (1.8s)
  ⚠️ Gmail: 5 items (3.1s) - 2 rate limit errors, retrying...
  ✅ Google Chat: 3 items (1.2s)

📊 Categorizing 31 items...
  🔴 Urgent: 3
  🟡 Normal: 7
  🔵 FYI: 12
  ⚫ Blocked: 2
  🟢 Follow-Up: 7

📝 Writing to: ~/Documents/FVH Vault/Daily Notes/2025-11-12.md

✅ Daily catch-up complete! (8.4s)
   View your summary: /sync:daily --open
```

**Definition of Done:**
- Progress indicators update in real-time
- Service fetch status displays clearly
- Error messages provide actionable guidance
- Total execution time calculates correctly
- Color coding works in Claude Code terminal
- Optional `--open` flag suggestion displays

---

## Functional Requirements

### Core Functionality

#### FR-1: Service Integration Layer

**GitHub Integration (via MCP):**
- Use `mcp__github` server configured in `.claude/settings.json`
- Fetch assigned issues: `GET /issues?assignee={username}&state=open&since={last_run}`
- Fetch PR review requests: `GET /search/issues?q=type:pr+review-requested:{username}`
- Fetch PR comments: `GET /notifications?participating=true&since={last_run}`
- Respect GitHub API rate limits (5000 req/hour authenticated)
- Implement exponential backoff for rate limit errors

**Podio Integration (via MCP):**
- Use `mcp__podio-mcp` server configured in `.claude/settings.json`
- Authentication via environment variables: `PODIO_CLIENT_ID`, `PODIO_CLIENT_SECRET`, `PODIO_APP_ID`, `PODIO_APP_TOKEN`
- Fetch assigned tasks: Query app items with filter `{"filters": {"assigned_to": "current_user"}}`
- Fetch updated tickets: Query items with `last_event_on > {last_run}`
- Handle OAuth2 token refresh automatically
- Cache access tokens per session

**Gmail Integration (MCP Required):**
- **Dependency**: Requires Gmail MCP server (not currently configured)
- **Configuration**: Add to `.claude/settings.json`:
  ```json
  "gmail": {
    "command": "npx",
    "args": ["-y", "gmail-mcp-server"],
    "env": {
      "GMAIL_CLIENT_ID": "${GMAIL_CLIENT_ID}",
      "GMAIL_CLIENT_SECRET": "${GMAIL_CLIENT_SECRET}",
      "GMAIL_REFRESH_TOKEN": "${GMAIL_REFRESH_TOKEN}"
    }
  }
  ```
- Fetch unread emails: `GET /users/me/messages?q=is:unread after:{last_run_date}`
- Apply filters: Focus on direct emails, exclude automated notifications
- Extract sender, subject, snippet, timestamp

**Google Chat Integration (MCP Required):**
- **Dependency**: Requires Google Chat MCP server (not currently configured)
- **Configuration**: Add to `.claude/settings.json`:
  ```json
  "google-chat": {
    "command": "npx",
    "args": ["-y", "google-chat-mcp-server"],
    "env": {
      "GCHAT_CLIENT_ID": "${GCHAT_CLIENT_ID}",
      "GCHAT_CLIENT_SECRET": "${GCHAT_CLIENT_SECRET}",
      "GCHAT_REFRESH_TOKEN": "${GCHAT_REFRESH_TOKEN}"
    }
  }
  ```
- Fetch unread mentions: `GET /spaces/{space}/messages?filter=mention:{user} AND read=false`
- Fetch unread DMs: `GET /spaces?filter=type=DM AND has_unread=true`
- Extract sender, message preview, space name, timestamp

---

#### FR-2: Categorization Engine

**Categorization Algorithm:**
```typescript
interface Item {
  id: string;
  title: string;
  source: 'github' | 'podio' | 'gmail' | 'gchat';
  link: string;
  timestamp: string;
  metadata: Record<string, any>;
}

function categorize(item: Item): Category {
  // Urgent criteria
  if (isUrgent(item)) return 'urgent';

  // Blocked criteria
  if (isBlocked(item)) return 'blocked';

  // Action needed criteria
  if (isActionNeeded(item)) return 'normal';

  // Follow-up criteria
  if (requiresFollowUp(item)) return 'follow-up';

  // Default to FYI
  return 'fyi';
}

function isUrgent(item: Item): boolean {
  // GitHub: PR reviews requested >24h ago OR "urgent" label
  if (item.source === 'github') {
    const age = Date.now() - new Date(item.timestamp).getTime();
    const hasUrgentLabel = item.metadata.labels?.includes('urgent');
    const isOldReview = item.metadata.type === 'review_request' && age > 86400000;
    return hasUrgentLabel || isOldReview;
  }

  // Podio: High priority OR overdue tasks
  if (item.source === 'podio') {
    const isHighPriority = item.metadata.priority === 'high';
    const isOverdue = item.metadata.due_date && new Date(item.metadata.due_date) < new Date();
    return isHighPriority || isOverdue;
  }

  // Gmail: Emails with "URGENT" in subject OR from specific VIPs
  if (item.source === 'gmail') {
    const hasUrgentSubject = /urgent|critical|asap/i.test(item.title);
    const isFromVIP = item.metadata.from?.includes('ceo@') || item.metadata.from?.includes('director@');
    return hasUrgentSubject || isFromVIP;
  }

  // Google Chat: Direct mentions in critical channels
  if (item.source === 'gchat') {
    const isCriticalSpace = item.metadata.space?.includes('incidents') || item.metadata.space?.includes('outage');
    return isCriticalSpace;
  }

  return false;
}

function isBlocked(item: Item): boolean {
  // GitHub: "blocked" or "waiting-for-*" labels
  if (item.source === 'github') {
    return item.metadata.labels?.some(l => l === 'blocked' || l.startsWith('waiting-for'));
  }

  // Podio: "Waiting" or "Blocked" status
  if (item.source === 'podio') {
    return ['waiting', 'blocked', 'on-hold'].includes(item.metadata.status?.toLowerCase());
  }

  return false;
}

function isActionNeeded(item: Item): boolean {
  // GitHub: Assigned issues, requested reviews
  if (item.source === 'github') {
    return item.metadata.type === 'assigned_issue' || item.metadata.type === 'review_request';
  }

  // Podio: Tasks assigned to user
  if (item.source === 'podio') {
    return item.metadata.assigned_to === 'current_user';
  }

  // Gmail: Direct emails (To: or CC: user)
  if (item.source === 'gmail') {
    return item.metadata.to?.includes(userEmail) || item.metadata.cc?.includes(userEmail);
  }

  // Google Chat: Direct messages or mentions
  if (item.source === 'gchat') {
    return item.metadata.type === 'direct_message' || item.metadata.has_mention;
  }

  return false;
}

function requiresFollowUp(item: Item): boolean {
  // GitHub: Issues with "waiting-on-reporter" label
  if (item.source === 'github') {
    return item.metadata.labels?.includes('waiting-on-reporter');
  }

  // Podio: Tasks in "pending" status
  if (item.source === 'podio') {
    return item.metadata.status?.toLowerCase() === 'pending';
  }

  return false;
}
```

**Categorization Rules:**
- Each item evaluated against criteria in priority order: Urgent → Blocked → Normal → Follow-Up → FYI
- First matching category wins (no multi-category assignment)
- Category assignments logged for debugging
- User can override categorization via configuration file (future enhancement)

---

#### FR-3: Obsidian Note Generation

**Template Structure:**
- YAML frontmatter with metadata
- Summary section with counts
- Category sections with items
- Fetch status footer
- Markdown optimized for Obsidian rendering

**Formatting Rules:**
- Use Obsidian-flavored Markdown (wikilinks, tags, callouts)
- Emoji prefixes for visual scanning
- Links use full URLs (not relative)
- Tags use Obsidian format: `#tag`
- Timestamps in human-readable format: "2 days ago", "3 hours ago"

**File Management:**
- Check for existing file before writing
- Create directory structure recursively if missing
- Set file permissions to 644 (owner read/write, group/others read)
- Handle write errors gracefully (disk full, permission denied)

**Obsidian Integration Features:**
- Generate backlinks to project notes (e.g., `[[Project X]]` for related items)
- Add tags for filtering: `#github`, `#podio`, `#urgent`, `#blocked`
- Use callouts for critical items: `> [!warning] Urgent item`
- Include dataview-compatible frontmatter for queries

---

#### FR-4: State Management

**State File Location:**
- Path: `~/.config/claude-code/sync:daily-state.json`
- Create directory if missing
- Restrict permissions to 600 (owner read/write only)

**State File Schema:**
```typescript
interface StateFile {
  version: string;              // Schema version for migration support
  last_run: string;             // ISO 8601 timestamp of last successful run
  services: {
    github?: {
      last_fetch: string;       // ISO 8601 timestamp
      cursor?: string;          // GitHub API cursor for pagination
      rate_limit_remaining: number;
      rate_limit_reset: string; // ISO 8601 timestamp
    };
    podio?: {
      last_fetch: string;
      last_item_id?: number;
      token_expires: string;    // OAuth token expiration
    };
    gmail?: {
      last_fetch: string;
      history_id?: string;      // Gmail history ID for incremental sync
    };
    gchat?: {
      last_fetch: string;
      last_message_time?: string;
    };
  };
  config?: {
    vault_path: string;         // User-configurable vault location
    fetch_interval: number;     // Minimum seconds between fetches
  };
}
```

**State Update Logic:**
- Update state only after successful completion
- Partial updates if some services fail (preserve successful fetch timestamps)
- Atomic writes (write to temp file, then rename)
- Validate JSON schema on read
- Migrate old schema versions automatically

**State Recovery:**
- Detect corrupted JSON and log error
- Recreate state file with defaults on corruption
- Default last_run to 24 hours ago on first run
- Preserve partial state if only some fields invalid

---

#### FR-5: Command-Line Interface

**Command Syntax:**
```bash
/sync:daily [OPTIONS]

OPTIONS:
  --full-refresh    Ignore last run time, fetch last 24 hours
  --open            Open generated note in default editor after creation
  --dry-run         Fetch and categorize but don't write note or update state
  --verbose         Display detailed fetch progress and debug info
  --services        Comma-separated list of services to fetch (default: all)
                    Example: --services=github,podio
  --help            Display usage information
  --version         Display command version
```

**Command Behavior:**
- Default: Incremental fetch, write note, update state, show summary
- `--full-refresh`: Bypass state, fetch last 24h, useful for testing or after long absence
- `--open`: Execute `open "~/Documents/FVH Vault/Daily Notes/YYYY-MM-DD.md"` after writing
- `--dry-run`: Preview mode for testing categorization without side effects
- `--verbose`: Show API calls, response sizes, categorization decisions
- `--services`: Selective fetching when some services are slow/broken

**Error Handling:**
- Invalid options: Display help message and exit with code 1
- Missing MCP server: Clear error message with setup instructions
- API authentication failure: Guide user to check credentials
- Network errors: Suggest retry with `--verbose` for debugging
- Partial failures: Complete successfully but warn about failed services

---

#### FR-6: Configuration File (Optional)

**Purpose:** Allow user customization without modifying command code

**Location:** `~/.config/claude-code/sync:daily-config.json`

**Configuration Schema:**
```json
{
  "vault_path": "~/Documents/FVH Vault",
  "note_template": "custom-template.md",
  "categories": {
    "urgent": {
      "emoji": "🔴",
      "label": "Action Needed - Urgent",
      "rules": {
        "github": {
          "labels": ["urgent", "critical", "security"],
          "review_age_hours": 24
        },
        "podio": {
          "priority": ["high", "critical"],
          "overdue": true
        }
      }
    }
  },
  "services": {
    "github": {
      "enabled": true,
      "rate_limit_buffer": 100,
      "timeout_seconds": 10
    },
    "podio": {
      "enabled": true,
      "timeout_seconds": 10
    },
    "gmail": {
      "enabled": false,
      "filters": {
        "exclude_labels": ["spam", "promotions"],
        "include_from": ["@company.com"]
      }
    },
    "gchat": {
      "enabled": false,
      "spaces": ["incidents", "team-chat"]
    }
  },
  "output": {
    "show_timestamps": true,
    "timestamp_format": "relative",
    "include_backlinks": true,
    "include_tags": true,
    "group_by": "category"
  }
}
```

**Configuration Priority:**
1. Command-line flags (highest)
2. Config file settings
3. Default values (lowest)

**Configuration Validation:**
- Validate JSON schema on load
- Warn about unknown keys
- Use defaults for invalid values
- Log configuration errors to stderr

---

## Non-Functional Requirements

### NFR-1: Performance

**Response Time:**
- Target: <30 seconds for typical daily volume (50 items across 4 services)
- Acceptable: <60 seconds for high volume (200+ items)
- Unacceptable: >90 seconds for any volume

**Optimization Strategies:**
- Parallel service fetching (all 4 services simultaneously)
- Connection pooling for HTTP requests
- Incremental fetching using service cursors
- Rate limit awareness to avoid retries
- Caching of authentication tokens

**Performance Metrics to Track:**
- Per-service fetch time
- Categorization processing time
- File write time
- Total execution time
- Memory usage (should stay <100MB)

---

### NFR-2: Reliability

**Availability:**
- Command must handle individual service failures gracefully
- Partial results acceptable if at least one service succeeds
- State file corruption must not prevent command execution

**Fault Tolerance:**
- Retry failed API requests up to 3 times with exponential backoff
- Continue processing even if one service times out
- Preserve existing daily note on write errors (don't overwrite with partial data)
- Validate state file before updating

**Data Integrity:**
- Atomic state file updates (write to temp file, then rename)
- Validate JSON before parsing
- Detect and recover from corrupted state
- Log all errors for debugging

**Error Recovery:**
- Network failures: Retry with exponential backoff (1s, 2s, 4s)
- API rate limits: Wait for reset time, then retry
- Authentication failures: Clear error message, don't retry
- Timeouts: Log warning, continue with other services

---

### NFR-3: Security

**Credential Management:**
- Store API credentials in environment variables (never in config files)
- Use MCP server authentication mechanisms (configured in `.claude/settings.json`)
- State file permissions: 600 (owner read/write only)
- Config file permissions: 644 (owner read/write, others read)
- Never log credentials or tokens

**Data Privacy:**
- Don't store sensitive email/message content in state file
- Limit data retention (state file only stores timestamps/cursors)
- Daily notes stored locally only (not synced to cloud by command)
- Respect service-level permissions (only fetch data user has access to)

**Authentication Security:**
- OAuth2 token refresh handled by MCP servers
- Detect expired tokens and re-authenticate automatically
- Use secure token storage provided by MCP infrastructure
- Follow principle of least privilege (only request required scopes)

**Secret Scanning:**
- Run `detect-secrets` before committing command code
- Ensure no hardcoded credentials in command file
- Add state file to `.git/info/exclude` if in dotfiles repo

---

### NFR-4: Usability (ADHD-Specific)

**Cognitive Load Reduction:**
- Single command execution (no multi-step workflow)
- Clear visual hierarchy in output (emojis, headings, counts)
- Scannable format (bullet points, short lines)
- Color-coded status indicators
- Progress feedback to prevent anxiety during execution

**Decision Support:**
- Items sorted by priority within categories
- Counts visible in category headers
- Actionable item titles (no ambiguity)
- Context provided for each item (no need to click link to understand)

**Consistency:**
- Predictable output format every run
- Stable category definitions
- Reliable execution (no random failures)
- Same Obsidian note location every day

**Accessibility:**
- Terminal output readable with screen readers
- Emoji fallbacks for text-only terminals
- High-contrast color coding
- Keyboard-only operation (no mouse required)

---

### NFR-5: Maintainability

**Code Quality:**
- Follow functional programming principles (pure functions, immutability)
- Single Responsibility Principle for functions
- Maximum function length: 50 lines
- Maximum file length: 500 lines (refactor into modules if larger)
- TypeScript for type safety (if using Node.js/Bun)

**Documentation:**
- Inline comments for complex logic
- JSDoc/TSDoc for all exported functions
- README section explaining command usage
- Example configuration files in documentation
- Changelog for version tracking

**Testing:**
- Unit tests for categorization logic
- Integration tests for MCP server interactions
- Mock API responses for deterministic tests
- Test state file corruption recovery
- Test partial service failures

**Modularity:**
- Separate modules for: service fetching, categorization, note generation, state management
- Pluggable service architecture (easy to add new services)
- Configurable categorization rules
- Template-based note generation

**Version Control:**
- Store command in `.claude/commands/sync:daily.md`
- Track changes in git commit history
- Use conventional commits for version bumps
- Include version number in command output

---

### NFR-6: Compatibility

**Platform Support:**
- macOS (primary target)
- Linux (secondary target)
- Windows (tertiary, via WSL)

**Claude Code Version:**
- Minimum version: 0.8.0 (slash command support)
- Test with latest stable release

**MCP Server Compatibility:**
- GitHub MCP server: latest stable
- Podio MCP server: latest stable
- Gmail MCP server: latest stable (when available)
- Google Chat MCP server: latest stable (when available)

**Obsidian Version:**
- No specific version requirement (uses standard Markdown)
- Tested with Obsidian 1.4.0+
- Dataview plugin optional (for advanced queries)

**Node.js/Bun Runtime:**
- Node.js 18+ or Bun 1.0+
- TypeScript 5.0+ (if using TypeScript)
- Required packages: date-fns (date handling), zod (schema validation)

---

## Technical Considerations

### Architecture

**High-Level Design:**
```
┌─────────────────────────────────────────────────────────────────┐
│                     /sync:daily Command                      │
│                  (.claude/commands/sync:daily.md)            │
└────────────┬────────────────────────────────────────────────────┘
             │
             ├─> 1. Parse CLI Arguments
             │
             ├─> 2. Load State & Config
             │        ├─> ~/.config/claude-code/sync:daily-state.json
             │        └─> ~/.config/claude-code/sync:daily-config.json
             │
             ├─> 3. Fetch Data (Parallel)
             │        ├─> GitHub MCP Server
             │        ├─> Podio MCP Server
             │        ├─> Gmail MCP Server (future)
             │        └─> Google Chat MCP Server (future)
             │
             ├─> 4. Categorize Items
             │        └─> Apply rules based on metadata
             │
             ├─> 5. Generate Obsidian Note
             │        └─> ~/Documents/FVH Vault/Daily Notes/YYYY-MM-DD.md
             │
             └─> 6. Update State & Report
                      ├─> Save new timestamps
                      └─> Display summary
```

**Component Breakdown:**

1. **CLI Parser**
   - Parse command-line arguments
   - Validate options
   - Display help/version
   - Set execution flags (dry-run, verbose, etc.)

2. **Configuration Manager**
   - Load state file (last run timestamps)
   - Load config file (user preferences)
   - Merge with defaults
   - Validate schema

3. **Service Fetcher (Parallel)**
   - GitHub Fetcher: Issues, PRs, comments
   - Podio Fetcher: Tasks, tickets
   - Gmail Fetcher: Unread emails (future)
   - Google Chat Fetcher: Mentions, DMs (future)
   - Error handling per service
   - Progress reporting

4. **Categorization Engine**
   - Apply urgency rules
   - Apply blocking rules
   - Apply action-needed rules
   - Apply follow-up rules
   - Default to FYI
   - Return categorized item lists

5. **Note Generator**
   - Render Markdown template
   - Format timestamps
   - Generate backlinks
   - Add tags
   - Write to file atomically

6. **State Manager**
   - Update timestamps
   - Save service cursors
   - Atomic file write
   - Validate before save

---

### Dependencies

**MCP Servers:**
- **github**: Already configured in `.claude/settings.json`
- **podio-mcp**: Already configured in `.claude/settings.json`
- **gmail**: NOT configured - requires setup
- **google-chat**: NOT configured - requires setup

**Node.js/Bun Packages:**
- **date-fns**: Date manipulation and formatting (`bun add date-fns`)
- **zod**: Schema validation (`bun add zod`)
- **chalk**: Terminal color output (`bun add chalk`)
- **ora**: Terminal spinners (`bun add ora`)

**System Dependencies:**
- Bash 4.0+ (for command script)
- jq (for JSON parsing in Bash, if using Bash)
- coreutils (mkdir, touch, chmod)

---

### Integration Points

**Claude Code Integration:**
- Command defined as Markdown file in `.claude/commands/`
- Uses `allowed-tools` frontmatter to specify MCP access
- Invoked via `/sync:daily` in Claude Code terminal
- Leverages existing MCP server configurations

**MCP Server Communication:**
- Use MCP protocol to call server tools
- Handle MCP error responses
- Respect server rate limits
- Log MCP requests for debugging (verbose mode)

**Chezmoi Integration:**
- Command stored in `~/.local/share/chezmoi/.claude/commands/`
- Symlinked to `~/.claude/commands/` via chezmoi template
- Changes immediately available (no `chezmoi apply` needed)
- Version controlled in dotfiles repo

**Obsidian Integration:**
- Write standard Markdown files
- Use Obsidian-compatible frontmatter
- Generate wikilinks for navigation
- Support Dataview queries (future)
- No Obsidian API calls required (file-based integration)

---

### Data Models

**Item Interface:**
```typescript
interface Item {
  id: string;                    // Unique identifier (service-specific)
  title: string;                 // Human-readable title
  source: 'github' | 'podio' | 'gmail' | 'gchat';
  link: string;                  // Full URL to item
  timestamp: string;             // ISO 8601 timestamp
  category: Category;            // Assigned category
  metadata: {
    // GitHub-specific
    type?: 'issue' | 'pr' | 'review_request' | 'comment';
    labels?: string[];
    assignees?: string[];
    author?: string;
    repo?: string;

    // Podio-specific
    app_id?: number;
    status?: string;
    priority?: 'high' | 'medium' | 'low';
    assigned_to?: string;
    due_date?: string;

    // Gmail-specific
    from?: string;
    to?: string;
    cc?: string;
    subject?: string;
    snippet?: string;

    // Google Chat-specific
    space?: string;
    sender?: string;
    message_preview?: string;
    has_mention?: boolean;
  };
}

type Category = 'urgent' | 'normal' | 'fyi' | 'blocked' | 'follow-up';

interface CategorizedItems {
  urgent: Item[];
  normal: Item[];
  fyi: Item[];
  blocked: Item[];
  followUp: Item[];
}
```

---

### Error Handling Strategy

**Error Hierarchy:**
```
CommandError (base)
  ├─> ConfigError (invalid config, missing config)
  ├─> StateError (corrupt state, invalid state)
  ├─> ServiceError (base for service errors)
  │     ├─> GitHubError
  │     ├─> PodioError
  │     ├─> GmailError
  │     └─> GoogleChatError
  ├─> FileSystemError (write failures, permission denied)
  └─> NetworkError (timeouts, connection failures)
```

**Error Handling Patterns:**

1. **Fatal Errors (exit immediately):**
   - Invalid CLI arguments
   - Missing required MCP servers (GitHub, Podio)
   - State file permanently corrupt and unrecoverable
   - Obsidian vault path invalid/inaccessible

2. **Recoverable Errors (retry then continue):**
   - Network timeouts (retry 3x)
   - API rate limits (wait then retry)
   - Transient service errors (retry with backoff)

3. **Partial Failures (warn and continue):**
   - Single service fetch failure (other services continue)
   - Optional services unavailable (Gmail, Google Chat)
   - Individual item parsing errors (skip item, continue)

4. **Silent Failures (log only):**
   - Missing optional config file
   - Empty result sets from services
   - Backlink generation failures (continue without backlinks)

**Error Messages:**
- Clear description of what failed
- Actionable recovery steps
- Reference to documentation (if applicable)
- Error codes for debugging

**Example Error Messages:**
```
❌ Error: GitHub MCP server not configured

The GitHub MCP server is required but not found in Claude Code settings.

To fix:
1. Ensure GitHub MCP server is configured in ~/.claude/settings.json
2. Restart Claude Code
3. Run command again

For setup instructions: https://github.com/github/github-mcp-server

---

⚠️ Warning: Gmail service unavailable

Gmail MCP server is not configured. Email items will be skipped.

To enable Gmail integration:
1. Add gmail MCP server to ~/.claude/settings.json
2. Configure OAuth2 credentials
3. See: /sync:daily --help

Continuing with GitHub and Podio only...
```

---

### Logging & Debugging

**Log Levels:**
- **ERROR**: Fatal errors, service failures
- **WARN**: Partial failures, missing optional services
- **INFO**: Normal execution progress (default)
- **DEBUG**: Detailed API calls, categorization decisions (verbose mode)

**Log Output:**
- stderr: Errors and warnings
- stdout: Normal output and progress
- Log file: `~/.local/state/claude-code/sync:daily.log` (optional)

**Debug Mode (`--verbose`):**
- Show full API requests/responses
- Display categorization logic for each item
- Show state file before/after updates
- Timing information for each operation
- Memory usage stats

**Audit Trail:**
- Log each command execution with timestamp
- Record which services were fetched
- Track categorization statistics
- Store execution time and item counts

---

## Success Metrics

### Key Performance Indicators (KPIs)

#### User Adoption & Engagement
- **Daily Active Usage**: Target 5+ runs per week (daily habit formation)
- **Command Completion Rate**: >95% executions complete without errors
- **Full-Refresh Usage**: <10% of runs use `--full-refresh` (incremental fetching working)
- **Service Selection**: <5% of runs use `--services` flag (all services reliable)

**Measurement:**
- Log command executions to `~/.local/state/claude-code/sync:daily.log`
- Track completion vs. error exit codes
- Count flag usage in logs

**Success Threshold:**
- 30+ successful runs in first month
- <5% error rate after initial setup period

---

#### Time Savings & Efficiency
- **Time to Daily Plan**: Reduce from 30-45 minutes (manual) to <2 minutes (automated)
- **Execution Time**: <30 seconds average, <60 seconds 95th percentile
- **Context Switch Reduction**: Eliminate 4 service navigations per morning

**Measurement:**
- Log execution time for each run
- User survey: "How much time did this save today?"
- Calculate percentiles: p50, p95, p99

**Success Threshold:**
- 90% of runs complete in <30 seconds
- User reports >20 minute daily time savings

---

#### ADHD-Specific Effectiveness
- **Decision Confidence**: User rates confidence in task prioritization (1-5 scale)
- **Hyperfocus Prevention**: Reduced instances of working on wrong priority
- **Task Completion**: Improved completion rate of urgent items
- **Anxiety Reduction**: Lower reported morning anxiety about "what to work on"

**Measurement:**
- Weekly survey (optional): Rate today's prioritization confidence
- Track urgent item completion vs. identification (via GitHub/Podio APIs)
- User feedback: "Did this help you start your day?"

**Success Threshold:**
- >4.0 average confidence rating
- >80% of identified urgent items completed within 1 week
- User reports reduced decision anxiety

---

#### Data Quality & Accuracy
- **Categorization Accuracy**: >90% of items correctly categorized
- **False Positive Rate**: <5% of "urgent" items are actually non-urgent
- **False Negative Rate**: <2% of truly urgent items missed or miscategorized
- **Data Freshness**: >95% of runs fetch complete data since last run

**Measurement:**
- User feedback: Flag miscategorized items
- Manual audit: Review 20 random items for correctness
- Compare fetched items vs. actual service data

**Success Threshold:**
- <10% miscategorization rate
- <2% of urgent items miscategorized as lower priority
- User reports high trust in categorization

---

#### Technical Quality Metrics

**Performance:**
- **Average Execution Time**: <30 seconds (target: 25 seconds)
- **Service Fetch Time**: <10 seconds per service
- **Memory Usage**: <100MB peak
- **API Rate Limit Errors**: <1% of executions

**Reliability:**
- **Uptime**: >99% command success rate
- **Partial Failure Rate**: <5% (at least one service fails)
- **State Corruption Rate**: <0.1% (state file becomes invalid)
- **Retry Success Rate**: >80% (failed requests succeed on retry)

**Data Collection:**
- Log execution metrics to state file
- Track per-service success/failure rates
- Monitor memory usage via runtime profiling
- Record API rate limit errors

**Success Threshold:**
- 99% uptime after initial 2-week stabilization period
- <3% partial failure rate
- Zero state corruption incidents after release

---

#### Business Value Metrics

**Productivity Impact:**
- **Daily Planning Time Saved**: 30 minutes/day → 10 hours/month
- **Missed Deadline Reduction**: Decrease by 50% (fewer urgent items missed)
- **Response Time Improvement**: 30% faster response to PR reviews/tickets
- **Context Switch Reduction**: 80% fewer morning service navigations

**User Satisfaction:**
- **Net Promoter Score (NPS)**: Target >8 (would recommend to colleague)
- **Feature Satisfaction**: >4.5/5 rating
- **Continued Usage**: >90% retention after 1 month

**Measurement:**
- User survey after 2 weeks of usage
- Track GitHub PR review response times before/after
- Monitor Podio ticket completion rates
- Exit survey if user stops using command

**Success Threshold:**
- NPS >8
- >80% of users still active after 1 month
- Measurable improvement in response times

---

### Measurement Methodology

**Data Collection:**
- **Automatic Logging**: Execution times, service status, item counts (stored in state file)
- **Optional Telemetry**: User opts in to share usage stats (privacy-preserving)
- **User Surveys**: Weekly optional feedback via Obsidian note prompt
- **Manual Audits**: Periodic review of categorization accuracy

**Analysis Frequency:**
- **Real-time**: Execution time, error rates
- **Daily**: Command usage patterns, service reliability
- **Weekly**: Categorization accuracy, user feedback
- **Monthly**: Trend analysis, feature effectiveness, user satisfaction

**Success Evaluation Timeline:**
- **Week 1**: Baseline data collection, initial feedback
- **Week 2**: First metrics review, identify critical issues
- **Week 4**: Full metrics evaluation, success criteria assessment
- **Month 3**: Long-term effectiveness and habit formation analysis

**Reporting:**
- Dashboard in Obsidian vault: `Daily Notes/Metrics/sync:daily-stats.md`
- Weekly summary note with charts (using Dataview plugin)
- Monthly retrospective: What's working, what needs improvement

---

### Quality Metrics

**Code Quality:**
- **Test Coverage**: >80% for core logic (categorization, state management)
- **Linter Warnings**: 0 (strict mode)
- **Type Safety**: 100% (if using TypeScript)
- **Cyclomatic Complexity**: <10 per function

**Documentation Quality:**
- **README Completeness**: All features documented
- **Inline Comments**: Complex logic explained
- **Examples**: Setup guide includes working examples
- **Changelog**: All changes tracked with version numbers

**User Experience Quality:**
- **Error Message Clarity**: >90% of users understand error messages without documentation
- **Setup Time**: <15 minutes for first-time configuration
- **Recovery Time**: <5 minutes to resolve common errors
- **Help Availability**: `--help` answers >80% of user questions

---

## Out of Scope

### Explicitly Excluded Features

#### Version 1.0 Exclusions

**Advanced Integrations:**
- ❌ Slack integration (similar to Google Chat, defer to v2.0)
- ❌ Microsoft Teams integration
- ❌ Jira integration (Podio covers project management needs)
- ❌ Asana integration
- ❌ Linear integration
- ❌ Calendar integrations (Google Calendar, Outlook)

**Natural Language Processing:**
- ❌ AI-powered categorization (rule-based only in v1.0)
- ❌ Sentiment analysis of messages
- ❌ Automatic task priority inference beyond explicit metadata
- ❌ Smart summaries of long email threads

**Interactive Features:**
- ❌ Interactive CLI prompts for recategorization
- ❌ Command-line task completion (marking items done)
- ❌ In-terminal item filtering/sorting
- ❌ TUI (Text User Interface) for browsing items

**Notification Systems:**
- ❌ Desktop notifications on urgent item detection
- ❌ Email digest of daily summary
- ❌ Slack/Teams notification posting
- ❌ SMS alerts for critical items

**Obsidian Advanced Features:**
- ❌ Automatic task creation in Obsidian (Tasks plugin integration)
- ❌ Calendar view population (Calendar plugin integration)
- ❌ Graph view node creation for items
- ❌ Obsidian API calls (file-based only)

**Customization:**
- ❌ Custom categorization rule DSL (use config file with predefined rules)
- ❌ User-defined categories (5 categories hardcoded)
- ❌ Template variables for note generation (single template)
- ❌ Per-service note generation (single daily note only)

**Analytics:**
- ❌ Trend analysis over time (manually review notes)
- ❌ Burndown charts
- ❌ Time-to-completion tracking
- ❌ Service usage heatmaps

**Collaboration:**
- ❌ Multi-user support (single user only)
- ❌ Shared team catch-up notes
- ❌ Delegation features (assigning items to others)

---

### Future Considerations (Not Committed)

**Version 2.0 Potential Features:**
- Gmail and Google Chat MCP server integrations (pending server availability)
- Custom categorization rules via UI/CLI
- AI-assisted categorization using Claude API
- Historical trend analysis and visualizations
- Calendar integration (show today's meetings in catch-up)

**Version 3.0 Potential Features:**
- Multi-user support for team catch-up
- Slack and Microsoft Teams integration
- Interactive TUI for item management
- Automatic task creation in Obsidian
- Smart notification system

**Community Requests (Evaluate Based on Demand):**
- Linear/Jira integration
- Notion integration
- Todoist integration
- Custom webhook support
- Export to other formats (PDF, HTML)

---

### Architectural Boundaries

**Not Responsible For:**
- ❌ MCP server installation (user must configure)
- ❌ Obsidian installation (user must have vault)
- ❌ API credential management (use environment variables)
- ❌ Service authentication flows (handled by MCP servers)
- ❌ Data synchronization across devices (Obsidian handles)
- ❌ Backup and recovery of daily notes (user's responsibility)

**Will Not Modify:**
- ❌ Existing Obsidian notes (only create new daily notes)
- ❌ Service data (read-only access)
- ❌ Claude Code configuration (except reading settings.json)
- ❌ MCP server configurations

**Technical Limitations Accepted:**
- Single-user only (no multi-tenancy)
- Local execution only (no cloud sync)
- File-based integration (no database)
- English language only (no i18n in v1.0)
- Terminal-based output only (no GUI)

---

## Timeline & Resources

### Development Phases

#### Phase 1: Foundation (Week 1-2)

**Milestone 1.1: Project Setup & Core Infrastructure**
- Set up command file structure in `.claude/commands/`
- Create state file schema and management functions
- Implement CLI argument parser
- Set up logging infrastructure
- Create test fixtures and mock MCP responses

**Deliverables:**
- Command file skeleton
- State management module (read/write/validate)
- CLI parser with --help, --version, --verbose
- Test suite foundation

**Estimated Effort:** 8-10 hours
**Dependencies:** None

---

**Milestone 1.2: GitHub & Podio Integration**
- Implement GitHub MCP fetcher (issues, PRs, reviews)
- Implement Podio MCP fetcher (tasks, tickets)
- Add error handling and retry logic
- Implement parallel service fetching
- Test with real MCP servers

**Deliverables:**
- GitHub fetcher module with full API coverage
- Podio fetcher module with full API coverage
- Service abstraction layer for future services
- Integration tests with mock responses

**Estimated Effort:** 12-16 hours
**Dependencies:** Milestone 1.1 complete

---

#### Phase 2: Categorization & Output (Week 3)

**Milestone 2.1: Categorization Engine**
- Implement categorization rules (urgent, blocked, normal, follow-up, FYI)
- Add configurable rule engine
- Test edge cases (empty results, ambiguous items)
- Validate categorization accuracy with sample data

**Deliverables:**
- Categorization module with full rule set
- Unit tests for each category rule
- Sample data set for validation
- Accuracy report (>90% target)

**Estimated Effort:** 10-12 hours
**Dependencies:** Milestone 1.2 complete (need real data)

---

**Milestone 2.2: Obsidian Note Generation**
- Implement Markdown template rendering
- Add frontmatter generation
- Create file write logic with atomic updates
- Implement backlink generation
- Test with various item volumes

**Deliverables:**
- Note generator module
- Markdown template
- File write tests (permissions, atomic updates)
- Sample generated notes

**Estimated Effort:** 8-10 hours
**Dependencies:** Milestone 2.1 complete (need categorized data)

---

#### Phase 3: Polish & Testing (Week 4)

**Milestone 3.1: Error Handling & Recovery**
- Add comprehensive error handling
- Implement retry logic with exponential backoff
- Add partial failure handling
- Create error message templates
- Test all error scenarios

**Deliverables:**
- Error handling layer
- Retry mechanism
- Error message documentation
- Failure scenario tests

**Estimated Effort:** 8-10 hours
**Dependencies:** All core functionality complete

---

**Milestone 3.2: Configuration & Usability**
- Implement optional config file support
- Add progress indicators and spinners
- Improve terminal output formatting
- Add `--dry-run` and `--open` flags
- Create user documentation

**Deliverables:**
- Config file loader and validator
- Pretty terminal output with color/emojis
- User-facing documentation (README section)
- Usage examples

**Estimated Effort:** 6-8 hours
**Dependencies:** Milestone 3.1 complete

---

**Milestone 3.3: Integration Testing & Launch**
- End-to-end testing with real services
- Performance testing (execution time, memory usage)
- User acceptance testing (dogfooding)
- Fix critical bugs
- Release v1.0.0

**Deliverables:**
- Full test suite passing
- Performance benchmarks
- Release notes
- Known issues list

**Estimated Effort:** 8-10 hours
**Dependencies:** All milestones complete

---

### Phase 4: Future Enhancements (Post-v1.0)

**Gmail & Google Chat Integration (v1.1):**
- Add Gmail MCP server configuration
- Add Google Chat MCP server configuration
- Implement fetchers for both services
- Update categorization rules
- Test with real data

**Estimated Effort:** 12-16 hours
**Timeline:** When MCP servers become available

**Custom Categorization Rules (v1.2):**
- Extend config file schema for custom rules
- Implement rule evaluation engine
- Add rule validation
- Create rule documentation

**Estimated Effort:** 10-12 hours
**Timeline:** Based on user demand

**AI-Powered Categorization (v2.0):**
- Integrate Claude API for smart categorization
- Train on user feedback data
- Implement confidence scoring
- Add fallback to rule-based for low confidence

**Estimated Effort:** 20-24 hours
**Timeline:** After 3 months of v1.0 usage data

---

### Resource Requirements

#### Human Resources

**Primary Developer:**
- Role: Full-stack developer with Claude Code expertise
- Time Commitment: 10-15 hours/week for 4 weeks
- Skills Required:
  - TypeScript/JavaScript (or Bash scripting)
  - MCP protocol understanding
  - Claude Code command structure
  - Markdown/Obsidian knowledge
  - Testing frameworks

**User/Stakeholder:**
- Role: Product owner, tester, end user
- Time Commitment: 2-3 hours/week for feedback and testing
- Responsibilities:
  - Requirements validation
  - User acceptance testing
  - Feedback on categorization accuracy
  - Documentation review

---

#### Technical Resources

**Development Tools:**
- Node.js/Bun runtime (already installed)
- TypeScript compiler (if using TypeScript)
- Testing framework: Vitest or Jest
- Linter: ESLint with strict config
- Formatter: Prettier

**MCP Servers:**
- GitHub MCP server (already configured)
- Podio MCP server (already configured)
- Gmail MCP server (future, not currently available)
- Google Chat MCP server (future, not currently available)

**External Services:**
- GitHub API access (via MCP)
- Podio API access (via MCP)
- OAuth2 credentials (user-provided)

**Infrastructure:**
- Local development environment (macOS)
- Chezmoi dotfiles repository (for version control)
- Obsidian vault (for testing output)

---

#### Budget Considerations

**Development Costs:**
- Developer time: 50-60 hours × $hourly_rate
- Testing time: 8-10 hours × $hourly_rate
- Documentation: 4-6 hours × $hourly_rate

**Service Costs:**
- GitHub API: Free (included with GitHub account)
- Podio API: Free (included with Podio account)
- Gmail API: Free (no quota limits for personal use)
- Google Chat API: Free (no quota limits for workspace use)
- Claude API: Free (using Claude Code, no additional API calls)

**Total Estimated Cost:**
- Development: 60-80 hours of developer time
- External Services: $0/month (all services included in existing subscriptions)
- Infrastructure: $0 (local development)

---

### Risk Assessment

#### High-Priority Risks

**Risk 1: MCP Server Unavailability**
- **Impact:** HIGH - Command cannot function without GitHub/Podio MCP servers
- **Likelihood:** MEDIUM - MCP servers can fail, go offline, or have bugs
- **Mitigation:**
  - Implement graceful degradation (work with available services only)
  - Add clear error messages when servers unavailable
  - Cache last successful results for fallback
  - Monitor MCP server health via ping
- **Contingency:** Manual fallback documentation for checking services

---

**Risk 2: API Rate Limiting**
- **Impact:** MEDIUM - Service fetching fails or slows down significantly
- **Likelihood:** HIGH - GitHub has aggressive rate limits (60 req/hour unauthenticated, 5000/hour authenticated)
- **Mitigation:**
  - Always use authenticated requests (higher limits)
  - Implement rate limit detection and backoff
  - Cache results when possible
  - Use conditional requests (ETag, If-Modified-Since)
- **Contingency:** Manual review of services when rate limited

---

**Risk 3: Categorization Accuracy**
- **Impact:** MEDIUM - Miscategorized items lead to missed urgent tasks
- **Likelihood:** MEDIUM - Rule-based categorization has inherent limitations
- **Mitigation:**
  - Extensive testing with real-world data
  - User feedback mechanism for miscategorizations
  - Config file for custom rule adjustments
  - Conservative urgency rules (prefer false positive over false negative)
- **Contingency:** Users manually review daily note and adjust priorities

---

**Risk 4: State File Corruption**
- **Impact:** MEDIUM - Lost last run timestamps lead to duplicate items
- **Likelihood:** LOW - File corruption rare, but possible (disk failure, power loss)
- **Mitigation:**
  - Atomic file writes (write to temp file, then rename)
  - JSON schema validation on read
  - Auto-recovery from corruption (recreate with defaults)
  - Backup previous state file before overwrite
- **Contingency:** User runs with `--full-refresh` to re-sync

---

#### Medium-Priority Risks

**Risk 5: Obsidian Vault Path Changes**
- **Impact:** MEDIUM - Daily notes write to wrong location or fail
- **Likelihood:** LOW - Vault path typically stable
- **Mitigation:**
  - Validate vault path exists before writing
  - Support config file for custom vault path
  - Clear error message if path invalid
- **Contingency:** User updates config file with new path

---

**Risk 6: Long Execution Time**
- **Impact:** MEDIUM - User waits >60 seconds, violates ADHD-friendly goal
- **Likelihood:** MEDIUM - Large volumes or slow APIs can delay execution
- **Mitigation:**
  - Parallel service fetching (all services simultaneously)
  - Timeout limits per service (10 seconds)
  - Progress indicators to reduce perceived wait time
  - Optimize categorization algorithm
- **Contingency:** User runs selectively with `--services` flag

---

**Risk 7: Gmail/Google Chat MCP Servers Not Available**
- **Impact:** LOW - Limited functionality, but GitHub/Podio still work
- **Likelihood:** HIGH - These servers not currently available
- **Mitigation:**
  - Design modular service architecture (easy to add later)
  - Document as "future enhancement" in PRD
  - Gracefully skip unavailable services
  - Notify user when new services become available
- **Contingency:** Users check Gmail/Google Chat manually (status quo)

---

#### Low-Priority Risks

**Risk 8: Chezmoi Integration Issues**
- **Impact:** LOW - Command not synced across machines
- **Likelihood:** LOW - Chezmoi symlink strategy proven
- **Mitigation:**
  - Follow existing chezmoi patterns for `.claude` directory
  - Test symlink on fresh system
  - Document chezmoi apply requirement (if any)
- **Contingency:** Manual copy of command file

---

**Risk 9: Cross-Platform Compatibility**
- **Impact:** LOW - Command doesn't work on Linux/Windows
- **Likelihood:** MEDIUM - File paths, permissions differ across platforms
- **Mitigation:**
  - Use Node.js/Bun for cross-platform file operations
  - Abstract file paths with path.join()
  - Test on macOS and Linux
- **Contingency:** Document macOS-only support initially

---

**Risk 10: User Overwhelm from Too Many Items**
- **Impact:** LOW - Defeats purpose if daily note has 100+ items
- **Likelihood:** MEDIUM - High-volume users may get flooded
- **Mitigation:**
  - Add item count limits per category (e.g., max 20 urgent)
  - Implement priority scoring within categories (show top 10)
  - Add summary section with counts before full list
  - Support filtering via config file
- **Contingency:** User manually skims large daily notes

---

### Risk Monitoring

**Weekly Risk Review:**
- Assess likelihood and impact of active risks
- Update mitigation strategies based on findings
- Add new risks as discovered during development

**Risk Triggers:**
- MCP server failures → Activate fallback plan
- Execution time >60s → Optimize or add selective fetching
- Categorization accuracy <90% → Refine rules
- User reports of missed urgent items → Investigate rule gaps

---

## Integration Considerations

### CI/CD Pipeline Requirements

**Pre-Commit Validation:**
- Run `detect-secrets scan` on command file
- Lint TypeScript/JavaScript with ESLint
- Format with Prettier
- Validate JSON schemas (state file, config file)

**Pre-Push Validation:**
- Run unit test suite (must pass 100%)
- Run integration tests with mock MCP servers
- Check test coverage >80%

**No GitHub Actions Required:**
- Command distributed via chezmoi (not npm/marketplace)
- Version controlled in dotfiles repo
- No CI pipeline needed initially

---

### Deployment Strategy

**Initial Deployment (v1.0):**
1. Commit command file to `~/.local/share/chezmoi/.claude/commands/`
2. Run `chezmoi apply` (or rely on symlink auto-sync)
3. Restart Claude Code (if needed)
4. Test with `/sync:daily --dry-run`
5. Run full command: `/sync:daily`

**Updates (v1.1+):**
1. Edit command file in chezmoi source directory
2. Commit changes to git with conventional commit
3. Changes immediately available via symlink (no apply needed)
4. Run command to test

**Rollback Procedure:**
```bash
# Revert to previous version
cd ~/.local/share/chezmoi
git log .claude/commands/sync:daily.md  # Find previous commit
git checkout <commit-hash> .claude/commands/sync:daily.md
chezmoi apply  # If not using symlink
```

---

### Monitoring & Alerting Needs

**Execution Monitoring:**
- Log each run to `~/.local/state/claude-code/sync:daily.log`
- Track success/failure rates
- Monitor execution time trends
- Alert if error rate >5% over 7 days

**Service Health Monitoring:**
- Track per-service success rates
- Alert if service fails 3+ times consecutively
- Monitor API rate limit consumption
- Detect MCP server unavailability

**Metrics Dashboard (Optional):**
- Create Obsidian note: `Daily Notes/Metrics/sync:daily-stats.md`
- Auto-update with execution stats
- Charts for execution time, item counts, category distribution
- Weekly summary report

**Alerting Strategy:**
- Critical: MCP server permanently unavailable → Email user
- Warning: Execution time >60s for 3+ runs → Log warning
- Info: New service available → Notify in command output

---

### Documentation Requirements

**User-Facing Documentation:**
- **Setup Guide**: MCP server configuration, credential setup, first run
- **Usage Guide**: Command syntax, options, examples
- **Troubleshooting**: Common errors and solutions
- **FAQ**: Answers to anticipated questions
- **Changelog**: Version history and feature additions

**Developer Documentation:**
- **Architecture Overview**: Component diagram, data flow
- **API Reference**: Function signatures, parameters, return values
- **Testing Guide**: How to run tests, add new tests
- **Contributing Guide**: Code style, commit conventions, PR process
- **MCP Integration Guide**: How to add new services

**Documentation Location:**
- User docs: `.claude/commands/sync:daily.md` (inline in command file)
- Developer docs: `~/.local/share/chezmoi/.claude/docs/sync:daily/`
- Changelog: `~/.local/share/chezmoi/.claude/commands/sync:daily.CHANGELOG.md`

**Documentation Standards:**
- Use Markdown format
- Include code examples
- Provide screenshots (where applicable)
- Keep examples up-to-date with code
- Link to external documentation (MCP servers, APIs)

---

## Appendix

### Glossary

**ADHD:** Attention-Deficit/Hyperactivity Disorder - neurodevelopmental condition affecting executive function, focus, and task prioritization

**MCP (Model Context Protocol):** Protocol for Claude Code to communicate with external services via server plugins

**MCP Server:** Service that implements MCP protocol to provide access to external APIs (GitHub, Podio, etc.)

**Obsidian:** Note-taking application using Markdown files, popular for personal knowledge management

**Daily Note:** Single Markdown file in Obsidian containing the day's aggregated action items

**Categorization:** Process of assigning urgency/type labels to fetched items based on metadata rules

**State File:** JSON file tracking last run timestamp and service cursors for incremental fetching

**Incremental Fetching:** Retrieving only new items since last run (vs. full refresh of last 24 hours)

**Frontmatter:** YAML metadata block at top of Markdown file (used by Obsidian for properties)

**Wikilink:** Obsidian-style link format `[[Page Name]]` for internal note references

**Backlink:** Automatically generated link to related project notes based on item metadata

**Chezmoi:** Dotfiles management tool that syncs configuration files across machines

**Conventional Commit:** Git commit message format (e.g., `feat:`, `fix:`) for automated changelog generation

---

### References

**Claude Code Documentation:**
- Slash Commands: https://docs.anthropic.com/claude-code/commands
- MCP Protocol: https://modelcontextprotocol.io/

**MCP Servers:**
- GitHub MCP Server: https://github.com/github/github-mcp-server
- Podio MCP Server: (custom MCP server, see `.chezmoidata.toml` for configuration)

**External APIs:**
- GitHub REST API: https://docs.github.com/en/rest
- Podio API: https://developers.podio.com/doc
- Gmail API: https://developers.google.com/gmail/api
- Google Chat API: https://developers.google.com/chat/api

**Tools & Libraries:**
- Obsidian: https://obsidian.md/
- Chezmoi: https://www.chezmoi.io/
- Bun: https://bun.sh/
- date-fns: https://date-fns.org/
- zod: https://zod.dev/

**ADHD Resources:**
- Executive Function & Task Management: https://chadd.org/
- ADHD-Friendly Productivity: https://www.additudemag.com/

---

### Revision History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0.0 | 2025-11-12 | Claude (requirements-documentation agent) | Initial PRD creation |

---

### Approval Signatures

**Product Owner:** _[User lgates to approve after review]_

**Technical Lead:** _[Claude implementation agent to review before development]_

**Stakeholders Consulted:**
- User (lgates) - Requirements gathering, user persona
- Claude Code team - MCP protocol and command structure guidance

---

## Next Steps

### Immediate Actions (Before Implementation)

1. **PRD Review & Approval**
   - User reviews PRD for completeness and accuracy
   - User approves requirements and success criteria
   - User validates timeline and resource estimates

2. **Technical Validation**
   - Verify GitHub MCP server functionality (`/github --help`)
   - Verify Podio MCP server functionality
   - Confirm Obsidian vault path: `~/Documents/FVH Vault`
   - Check Node.js/Bun version: `bun --version`

3. **Environment Setup**
   - Create directories: `~/.config/claude-code/`, `~/.local/state/claude-code/`
   - Add environment variables for Podio credentials (if not already set)
   - Test write permissions to Obsidian vault

4. **Development Kickoff**
   - Create feature branch: `git checkout -b feat/sync:daily-command`
   - Set up test fixtures directory: `~/.local/share/chezmoi/.claude/commands/sync:daily.test/`
   - Initialize test suite with mock MCP responses

### Post-Approval Workflow

1. **Implementation** (per TDD workflow):
   - Write failing test (RED)
   - Implement feature (GREEN)
   - Refactor code (REFACTOR)
   - Commit with conventional commit message

2. **Testing & Validation**:
   - User acceptance testing with real services
   - Performance benchmarking
   - Error scenario testing
   - Cross-platform testing (macOS → Linux)

3. **Documentation**:
   - Write user-facing setup guide
   - Create inline command documentation
   - Add troubleshooting section
   - Write changelog entry

4. **Deployment**:
   - Merge feature branch to main
   - Tag release: `v1.0.0`
   - Run `chezmoi apply` (if needed)
   - Announce availability to user

5. **Monitoring**:
   - Track execution metrics for first week
   - Collect user feedback
   - Identify high-priority bugs/improvements
   - Plan v1.1 features based on usage data

---

**Ready for approval and implementation.**
