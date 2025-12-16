# justfile for dotfiles repository
# Serves as documentation for integration points and common operations
# Run `just` or `just --list` to see available recipes

set shell := ["bash", "-uc"]

# Default recipe - show help
[default]
help:
    @just --list --unsorted
    @echo ""
    @echo "{{YELLOW}}Integration Points:{{NORMAL}}"
    @echo "  • Chezmoi scripts: run_* files for automatic execution"
    @echo "  • Package management via Brewfile and mise"
    @echo "  • Neovim configuration in private_dot_config/nvim/"
    @echo "  • Shell configuration for Fish in private_dot_config/fish/"
    @echo "  • CI/CD pipeline in .github/workflows/smoke.yml"

# ─────────────────────────────────────────────────────────────────────────────
# Build & Development
# ─────────────────────────────────────────────────────────────────────────────

# Apply dotfiles configuration to system
apply target="":
    @echo "{{BLUE}}Applying dotfiles configuration...{{NORMAL}}"
    chezmoi apply {{ if target != "" { target } else { "" } }} -v

# Check what changes would be made (alias for status)
check: status

# Show differences between current state and dotfiles
diff:
    @echo "{{BLUE}}Showing configuration differences...{{NORMAL}}"
    chezmoi diff

# Show status of dotfiles vs current system state
status:
    @echo "{{BLUE}}Checking dotfiles status...{{NORMAL}}"
    chezmoi status

# Verify dotfiles configuration integrity
verify:
    @echo "{{BLUE}}Verifying configuration integrity...{{NORMAL}}"
    chezmoi verify .

# ─────────────────────────────────────────────────────────────────────────────
# Testing
# ─────────────────────────────────────────────────────────────────────────────

# Run all tests (linting + smoke test in Docker)
test: lint smoke

# Run all linters as used in CI
lint: lint-shell lint-lua lint-actions lint-brew

# Lint shell scripts with shellcheck
lint-shell:
    @echo "{{BLUE}}Running shellcheck...{{NORMAL}}"
    @if command -v shellcheck >/dev/null 2>&1; then \
        find . -name "*.sh" -not -path "./node_modules/*" -exec shellcheck {} \; || echo "{{YELLOW}}Warning: shellcheck found issues{{NORMAL}}"; \
    else \
        echo "{{YELLOW}}Warning: shellcheck not installed{{NORMAL}}"; \
    fi

# Lint Neovim Lua configuration
lint-lua:
    @echo "{{BLUE}}Running luacheck...{{NORMAL}}"
    @if command -v luacheck >/dev/null 2>&1; then \
        luacheck private_dot_config/nvim/lua || echo "{{YELLOW}}Warning: luacheck found issues{{NORMAL}}"; \
    else \
        echo "{{YELLOW}}Warning: luacheck not installed{{NORMAL}}"; \
    fi

# Lint GitHub Actions workflows
lint-actions:
    @echo "{{BLUE}}Running actionlint...{{NORMAL}}"
    @if command -v actionlint >/dev/null 2>&1; then \
        actionlint || echo "{{YELLOW}}Warning: actionlint found issues{{NORMAL}}"; \
    else \
        echo "{{YELLOW}}Warning: actionlint not installed{{NORMAL}}"; \
    fi

# Check Brewfile integrity
lint-brew:
    @echo "{{BLUE}}Checking Brewfile integrity...{{NORMAL}}"
    @if [ -f Brewfile ]; then \
        brew bundle check --file=Brewfile || echo "{{YELLOW}}Warning: Brewfile check failed{{NORMAL}}"; \
    else \
        echo "{{YELLOW}}Warning: Brewfile not found{{NORMAL}}"; \
    fi

# Run pre-commit hooks on all files
pre-commit:
    @echo "{{BLUE}}Running pre-commit hooks...{{NORMAL}}"
    @if command -v pre-commit >/dev/null 2>&1; then \
        pre-commit run --all-files; \
    else \
        echo "{{YELLOW}}Warning: pre-commit not installed{{NORMAL}}"; \
    fi

# Run full smoke test in Docker (reproduces CI)
smoke:
    @echo "{{BLUE}}Running smoke test in Docker...{{NORMAL}}"
    docker-compose up --build smoke

# Run lint stage only in Docker
smoke-lint:
    @echo "{{BLUE}}Running lint stage in Docker...{{NORMAL}}"
    docker-compose run --rm smoke lint

# Run build stage only in Docker
smoke-build:
    @echo "{{BLUE}}Running build stage in Docker...{{NORMAL}}"
    docker-compose run --rm smoke build

# Start interactive shell for debugging smoke test failures
smoke-shell:
    @echo "{{BLUE}}Starting interactive smoke test shell...{{NORMAL}}"
    docker-compose run --rm smoke-shell

# Clean up smoke test Docker resources
smoke-clean:
    @echo "{{BLUE}}Cleaning up smoke test containers...{{NORMAL}}"
    docker-compose down --rmi local --volumes --remove-orphans

# ─────────────────────────────────────────────────────────────────────────────
# Environment Setup
# ─────────────────────────────────────────────────────────────────────────────

# Complete initial environment setup
setup: setup-brew setup-mise setup-nvim

# Install/update Homebrew packages
setup-brew:
    @echo "{{BLUE}}Setting up Homebrew packages...{{NORMAL}}"
    @if [ -f Brewfile ]; then \
        brew bundle install --file=Brewfile; \
        brew cleanup; \
    else \
        echo "{{RED}}Error: Brewfile not found{{NORMAL}}"; \
        exit 1; \
    fi

# Install mise tool versions
setup-mise:
    @echo "{{BLUE}}Setting up mise tools...{{NORMAL}}"
    @if command -v mise >/dev/null 2>&1; then \
        mise install; \
    else \
        echo "{{YELLOW}}Warning: mise not installed{{NORMAL}}"; \
    fi

# Install/update Neovim plugins and LSP tools
setup-nvim:
    @echo "{{BLUE}}Setting up Neovim plugins...{{NORMAL}}"
    @if command -v nvim >/dev/null 2>&1; then \
        nvim --headless "+Lazy! sync" "+lua require('lazy').load({plugins={'mason.nvim'}})" "+MasonUpdate" +qa; \
    else \
        echo "{{YELLOW}}Warning: neovim not installed{{NORMAL}}"; \
    fi

# ─────────────────────────────────────────────────────────────────────────────
# Documentation
# ─────────────────────────────────────────────────────────────────────────────

# Open documentation
docs:
    @echo "{{BLUE}}Available documentation:{{NORMAL}}"
    @echo "  README.md - Repository overview"
    @echo "  CLAUDE.md - AI assistant guidance"
    @echo "  CONVENTIONS.md - Development conventions"
    @echo "  docs/ - Detailed documentation"

# ─────────────────────────────────────────────────────────────────────────────
# Utilities
# ─────────────────────────────────────────────────────────────────────────────

# Update all tools and packages
update: update-claude-completion
    @echo "{{BLUE}}Updating all tools and packages...{{NORMAL}}"
    @echo "{{GREEN}}Updating Homebrew...{{NORMAL}}"
    @if command -v brew >/dev/null 2>&1; then \
        brew update && brew upgrade && brew cleanup; \
    else \
        echo "{{YELLOW}}Warning: brew not found{{NORMAL}}"; \
    fi
    @echo "{{GREEN}}Updating mise tools...{{NORMAL}}"
    @if command -v mise >/dev/null 2>&1; then \
        mise upgrade; \
    else \
        echo "{{YELLOW}}Warning: mise not found{{NORMAL}}"; \
    fi
    @echo "{{GREEN}}Updating Neovim plugins...{{NORMAL}}"
    @if command -v nvim >/dev/null 2>&1; then \
        nvim --headless "+Lazy! sync" "+lua require('lazy').load({plugins={'mason.nvim'}})" "+MasonUpdate" +qa; \
    else \
        echo "{{YELLOW}}Warning: nvim not found{{NORMAL}}"; \
    fi
    @echo "{{GREEN}}Updating uv tool packages...{{NORMAL}}"
    @if command -v uv >/dev/null 2>&1; then \
        uv tool upgrade --all; \
    else \
        echo "{{YELLOW}}Warning: uv not found{{NORMAL}}"; \
    fi

# Bump all tools to latest versions across all package managers
bump:
    @echo "{{BLUE}}🚀 Bumping all tools to latest versions...{{NORMAL}}"
    BUMP=1 chezmoi apply
    @echo "{{GREEN}}✅ Bump complete!{{NORMAL}}"

# Update Claude CLI zsh completion
update-claude-completion:
    @echo "{{BLUE}}Updating Claude CLI completion...{{NORMAL}}"
    @if [ -x "./scripts/generate-claude-completion-simple.sh" ]; then \
        ./scripts/generate-claude-completion-simple.sh; \
    else \
        echo "{{YELLOW}}Warning: Claude completion generator not found{{NORMAL}}"; \
    fi

# Clean up temporary files and caches
clean:
    @echo "{{BLUE}}Cleaning up...{{NORMAL}}"
    @if command -v brew >/dev/null 2>&1; then \
        echo "{{GREEN}}Cleaning Homebrew cache...{{NORMAL}}"; \
        brew cleanup; \
    fi
    @echo "{{GREEN}}Removing temporary files...{{NORMAL}}"
    @find . -name "*.tmp" -delete 2>/dev/null || true
    @find . -name ".DS_Store" -delete 2>/dev/null || true

# Scan for secrets in repository
secrets:
    @echo "{{BLUE}}Scanning for secrets...{{NORMAL}}"
    @if command -v detect-secrets >/dev/null 2>&1; then \
        if [ -f .secrets.baseline ]; then \
            detect-secrets scan --baseline .secrets.baseline; \
            echo "{{GREEN}}Secret scan complete (baseline: .secrets.baseline){{NORMAL}}"; \
        else \
            detect-secrets scan; \
        fi \
    elif command -v rg >/dev/null 2>&1; then \
        echo "{{YELLOW}}detect-secrets not installed, using ripgrep fallback{{NORMAL}}"; \
        rg -i "password|secret|token|api.?key" --type-not lock --type-not json . || echo "{{GREEN}}No obvious secrets found{{NORMAL}}"; \
    else \
        echo "{{YELLOW}}Warning: neither detect-secrets nor ripgrep installed{{NORMAL}}"; \
    fi

# Display terminal color capabilities
[private]
colors:
    @echo "{{BLUE}}Displaying terminal colors...{{NORMAL}}"
    @awk -v term_cols="${width:-$(tput cols)}" 'BEGIN{ \
        s="  "; \
        for (colnum = 0; colnum<term_cols; colnum++) { \
            r = 255-(colnum*255/term_cols); \
            g = (colnum*510/term_cols); \
            b = (colnum*255/term_cols); \
            if (g>255) g = 510-g; \
            printf "\033[48;2;%d;%d;%dm", r,g,b; \
            printf "\033[38;2;%d;%d;%dm", 255-r,255-g,255-b; \
            printf "%s\033[0m", substr(s,colnum%2+1,1); \
        } \
        printf "\033[1mbold\033[0m\n"; \
        printf "\033[3mitalic\033[0m\n"; \
        printf "\033[3m\033[1mbold italic\033[0m\n"; \
        printf "\033[4munderline\033[0m\n"; \
        printf "\033[9mstrikethrough\033[0m\n"; \
        printf "\033[31mred text\033[0m\n"; \
    }'

# ─────────────────────────────────────────────────────────────────────────────
# CI/CD Integration
# ─────────────────────────────────────────────────────────────────────────────

# Run CI checks locally
ci: lint
    @echo "{{BLUE}}Running CI checks locally...{{NORMAL}}"
    @echo "{{GREEN}}All CI checks completed{{NORMAL}}"

# ─────────────────────────────────────────────────────────────────────────────
# Development
# ─────────────────────────────────────────────────────────────────────────────

# Start development environment
dev: status
    @echo "{{BLUE}}Starting development environment...{{NORMAL}}"
    @echo "{{GREEN}}Development environment ready{{NORMAL}}"
    @echo "{{YELLOW}}Run 'just apply' to apply changes{{NORMAL}}"

# Edit dotfiles configuration
edit:
    @echo "{{BLUE}}Opening dotfiles for editing...{{NORMAL}}"
    @if command -v nvim >/dev/null 2>&1; then \
        nvim .; \
    elif command -v code >/dev/null 2>&1; then \
        code .; \
    else \
        echo "{{YELLOW}}No preferred editor found, please edit manually{{NORMAL}}"; \
    fi

# ─────────────────────────────────────────────────────────────────────────────
# Information
# ─────────────────────────────────────────────────────────────────────────────

# Show system and tool information
info:
    @echo "{{BLUE}}System Information:{{NORMAL}}"
    @echo "OS: $(uname -s) $(uname -r)"
    @echo "Architecture: $(uname -m)"
    @echo "Shell: $SHELL"
    @echo ""
    @echo "{{BLUE}}Tool Versions:{{NORMAL}}"
    @echo -n "chezmoi: "; chezmoi --version 2>/dev/null || echo "not installed"
    @echo -n "brew: "; brew --version 2>/dev/null | head -1 || echo "not installed"
    @echo -n "mise: "; mise --version 2>/dev/null || echo "not installed"
    @echo -n "nvim: "; nvim --version 2>/dev/null | head -1 || echo "not installed"
    @echo -n "git: "; git --version 2>/dev/null || echo "not installed"
    @echo -n "just: "; just --version 2>/dev/null || echo "not installed"

# Diagnose common issues
doctor:
    @echo "{{BLUE}}Running diagnostics...{{NORMAL}}"
    @echo ""
    @echo "{{BLUE}}Required Tools:{{NORMAL}}"
    @for tool in chezmoi git fish mise just; do \
        if command -v $tool >/dev/null 2>&1; then \
            echo "  {{GREEN}}✓{{NORMAL}} $tool"; \
        else \
            echo "  {{RED}}✗{{NORMAL}} $tool (not installed)"; \
        fi \
    done
    @echo ""
    @echo "{{BLUE}}Optional Tools:{{NORMAL}}"
    @for tool in nvim brew shellcheck luacheck actionlint pre-commit detect-secrets rg fd; do \
        if command -v $tool >/dev/null 2>&1; then \
            echo "  {{GREEN}}✓{{NORMAL}} $tool"; \
        else \
            echo "  {{YELLOW}}○{{NORMAL}} $tool (not installed)"; \
        fi \
    done
    @echo ""
    @echo "{{BLUE}}Chezmoi Status:{{NORMAL}}"
    @if chezmoi verify . 2>/dev/null; then \
        echo "  {{GREEN}}✓{{NORMAL}} Configuration verified"; \
    else \
        echo "  {{YELLOW}}!{{NORMAL}} Configuration has uncommitted changes"; \
    fi
    @if [ -d ~/.local/share/chezmoi/.git ]; then \
        echo "  {{GREEN}}✓{{NORMAL}} Source directory is a git repo"; \
    else \
        echo "  {{YELLOW}}!{{NORMAL}} Source directory is not a git repo"; \
    fi
    @echo ""
    @echo "{{BLUE}}Environment:{{NORMAL}}"
    @if [ -n "$MISE_SHELL" ]; then \
        echo "  {{GREEN}}✓{{NORMAL}} mise is activated"; \
    else \
        echo "  {{YELLOW}}!{{NORMAL}} mise is not activated (run: eval \"\$(mise activate bash)\")"; \
    fi
    @if [ -f ~/.api_tokens ]; then \
        echo "  {{GREEN}}✓{{NORMAL}} API tokens file exists"; \
    else \
        echo "  {{YELLOW}}○{{NORMAL}} No ~/.api_tokens file"; \
    fi
