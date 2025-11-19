# ArgoCD Monitor Agent

Automated monitoring agent that watches ArgoCD application events and logs, investigates issues using Claude Agent SDK, and creates GitHub issues for problems that need attention.

## Features

- Monitors ArgoCD application health and sync status
- Analyzes events using Claude Agent SDK for intelligent root cause analysis
- Automatically creates GitHub issues for persistent problems
- Sends notifications via telegram-send (optional)
- Runs as systemd service for continuous monitoring

## Prerequisites

1. **Claude Agent SDK**: Install with `uv tool install claude-agent-sdk`
2. **ArgoCD CLI**: Must be installed and configured
3. **GitHub Token**: With `repo` and `issues` scope
4. **ArgoCD Token**: Generate with `argocd account generate-token`

## Setup

### 1. Configuration

Copy the example files and fill in your values:

```bash
cd ~/.config/argocd-monitor/
cp config.json.example config.json
cp env.example env

# Edit with your values
$EDITOR config.json
$EDITOR env
```

### 2. Test Run

```bash
# Run once to test
argocd-monitor --once --dry-run

# Run once and create issues
argocd-monitor --once
```

### 3. Enable Service

Choose one of these approaches:

**Option A: Continuous Service** (always running)
```bash
systemctl --user enable --now argocd-monitor.service
```

**Option B: Timer-based** (runs every 5 minutes)
```bash
systemctl --user enable --now argocd-monitor.timer
```

### 4. Monitor Logs

```bash
# View service logs
journalctl --user -u argocd-monitor -f

# View monitor log file
tail -f ~/.config/argocd-monitor/monitor.log
```

## Configuration Options

### config.json

| Option | Default | Description |
|--------|---------|-------------|
| `poll_interval` | 300 | Seconds between checks |
| `event_lookback_minutes` | 30 | How far back to check events |
| `github_repo` | null | GitHub repo for issues (org/repo) |
| `severity_threshold` | "warning" | Minimum severity to report |
| `telegram_notify` | false | Send notifications via telegram-send |
| `issue_labels` | [...] | Labels to add to GitHub issues |
| `argocd_server` | null | ArgoCD server URL |

### Environment Variables

| Variable | Required | Description |
|----------|----------|-------------|
| `ARGOCD_SERVER` | Yes | ArgoCD server URL |
| `ARGOCD_AUTH_TOKEN` | Yes | ArgoCD authentication token |
| `GITHUB_TOKEN` | Yes | GitHub personal access token |
| `ARGOCD_MONITOR_GITHUB_REPO` | Yes | Target repo for issues |
| `ARGOCD_MONITOR_INTERVAL` | No | Override poll interval |

## How It Works

1. **Fetch Events**: Gets application status and Kubernetes events from ArgoCD
2. **Analyze**: Uses Claude Agent SDK to analyze events for issues
3. **Prioritize**: Assigns priority based on impact (critical/high/medium/low)
4. **Create Issues**: Creates GitHub issues for persistent, actionable problems
5. **Notify**: Sends telegram notification for critical/high priority issues

## Issue Detection

The agent detects:

- **Health Issues**: Degraded, Missing, Unknown health states
- **Sync Failures**: OutOfSync, sync errors, stuck syncs
- **Resource Problems**: CrashLoopBackOff, OOMKilled, ImagePullBackOff
- **Configuration Drift**: Differences between desired and live state

## Customization

### Custom Analysis Prompts

Edit the analysis prompt in the script to focus on specific patterns:

```python
analysis_prompt = f"""
Analyze these ArgoCD events with focus on:
- Database connection failures
- Certificate expiration
- Memory pressure
...
"""
```

### Integration with Graphiti Memory

Enable knowledge persistence by adding Graphiti MCP:

```python
mcp_servers["graphiti-memory"] = {
    "transport": "sse",
    "command": "http://localhost:8000/sse"
}
```

### Custom Issue Labels

Configure in `config.json`:

```json
{
  "issue_labels": ["argocd", "team:platform", "auto-detected"]
}
```

## Troubleshooting

### No Issues Created

1. Check ArgoCD connectivity: `argocd app list`
2. Verify GitHub token has correct scopes
3. Run with `--dry-run` to see what would be created
4. Check logs: `~/.config/argocd-monitor/monitor.log`

### Service Won't Start

```bash
# Check service status
systemctl --user status argocd-monitor

# Check for missing dependencies
which argocd
python -c "from claude_agent_sdk import query"
```

### High Memory Usage

Adjust resource limits in the systemd service file or reduce poll frequency.

## Security Notes

- Never commit the `env` file with secrets
- Use read-only ArgoCD tokens when possible
- Limit GitHub token to specific repos
- The service runs with security hardening (NoNewPrivileges, PrivateTmp)

## Related Skills

- `argocd-investigation` - Manual ArgoCD debugging patterns
- `kubernetes-operations` - K8s troubleshooting
- `github-actions-inspection` - CI/CD debugging
