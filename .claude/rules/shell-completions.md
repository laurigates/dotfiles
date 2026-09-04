---
created: 2026-07-19
modified: 2026-08-31
reviewed: 2026-08-31
paths:
  - ".chezmoidata/completions.toml"
  - "run_onchange_02-generate-completions.sh.tmpl"
  - "run_onchange_update-claude-completion.sh.tmpl"
  - "dot_zshrc.tmpl"
  - "dot_zfunc/**"
---
# Shell Completions Management

## Overview

Shell completions are managed via chezmoi's data-driven approach:
- **Registry**: `.chezmoidata/completions.toml` under `[packages.completion_tools.zsh_completions]`
- **Generator**: `run_onchange_02-generate-completions.sh.tmpl`
- **Output**: `~/.zfunc/_<tool>` (Zsh completion files)

## Adding New Completions

1. **Find the completion command** for your tool:
   ```bash
   <tool> --help | grep -i completion
   # or check tool documentation
   ```

2. **Add to registry** in `.chezmoidata/completions.toml`:
   ```toml
   [packages.completion_tools.zsh_completions]
     # ... existing entries ...
     mytool = "mytool completion zsh"
   ```

3. **Apply changes**:
   ```bash
   chezmoi apply
   ```

## Common Completion Command Patterns

| Pattern | Example Tools |
|---------|---------------|
| `<tool> completion zsh` | gh, kubectl, helm, argocd, docker |
| `<tool> --completions zsh` | just, rustup |
| `<tool> completions` | bun |
| `<tool> gen-completions --shell zsh` | atuin |
| `<tool> generate-shell-completion zsh` | uv |

## How It Works

The `run_onchange` script:
1. Detects changes via `.chezmoidata/completions.toml` hash in template header
2. Iterates over all entries in `zsh_completions`
3. Skips tools not installed (`command -v` check)
4. Generates `~/.zfunc/_<tool>` for each available tool

## Zsh Configuration

Ensure `~/.zfunc` is in your `fpath` before `compinit`:
```zsh
fpath=(~/.zfunc $fpath)
autoload -Uz compinit && compinit
```

## Troubleshooting

**Completions not working after apply:**
```bash
# Rebuild completion cache
rm -f ~/.zcompdump && compinit
```

**Tool not generating completions:**
```bash
# Test the command manually
<tool> completion zsh > /dev/null && echo "Works" || echo "Failed"
```

**Force regeneration:**
```bash
# Touch the data file to trigger run_onchange
touch ~/.local/share/chezmoi/.chezmoidata/completions.toml
chezmoi apply
```
