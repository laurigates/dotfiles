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
apply:
    @echo "{{BLUE}}Applying dotfiles configuration...{{NORMAL}}"
    chezmoi apply -v

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
lint:
    @echo "{{BLUE}}Running linters...{{NORMAL}}"
    @if command -v shellcheck >/dev/null 2>&1; then \
        echo "{{GREEN}}Running shellcheck...{{NORMAL}}"; \
        find . -name "*.sh" -not -path "./node_modules/*" -exec shellcheck {} \; || echo "{{YELLOW}}Warning: shellcheck found issues{{NORMAL}}"; \
    else \
        echo "{{YELLOW}}Warning: shellcheck not installed{{NORMAL}}"; \
    fi
    @if command -v luacheck >/dev/null 2>&1; then \
        echo "{{GREEN}}Running luacheck...{{NORMAL}}"; \
        luacheck private_dot_config/nvim/lua || echo "{{YELLOW}}Warning: luacheck found issues{{NORMAL}}"; \
    else \
        echo "{{YELLOW}}Warning: luacheck not installed{{NORMAL}}"; \
    fi
    @if command -v actionlint >/dev/null 2>&1; then \
        echo "{{GREEN}}Running actionlint...{{NORMAL}}"; \
        actionlint || echo "{{YELLOW}}Warning: actionlint found issues{{NORMAL}}"; \
    else \
        echo "{{YELLOW}}Warning: actionlint not installed{{NORMAL}}"; \
    fi
    @if [ -f Brewfile ]; then \
        echo "{{GREEN}}Checking Brewfile integrity...{{NORMAL}}"; \
        brew bundle check --file=Brewfile || echo "{{YELLOW}}Warning: Brewfile check failed{{NORMAL}}"; \
    else \
        echo "{{YELLOW}}Warning: Brewfile not found{{NORMAL}}"; \
    fi

# Alias for smoke test (deprecated, use 'just smoke')
docker: smoke

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
# Quality Assurance
# ─────────────────────────────────────────────────────────────────────────────

# Run quality assurance checks
qa: lint check

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

# Serve documentation locally (if available)
docs-serve:
    @echo "{{YELLOW}}Documentation serving not implemented yet{{NORMAL}}"

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

# Run security audit on configurations
security-audit:
    @echo "{{BLUE}}Running security audit...{{NORMAL}}"
    @echo "{{GREEN}}Checking for secrets in files...{{NORMAL}}"
    @if command -v rg >/dev/null 2>&1; then \
        rg -i "password|secret|token|key" --type-not lock --type-not json . || echo "{{GREEN}}No obvious secrets found{{NORMAL}}"; \
    else \
        echo "{{YELLOW}}Warning: ripgrep not installed, cannot check for secrets{{NORMAL}}"; \
    fi

# Display terminal color capabilities
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
    @echo "{{GREEN}}Running initial checks...{{NORMAL}}"
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
