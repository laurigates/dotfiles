# Makefile for dotfiles repository
# Serves as documentation for integration points and common operations

.PHONY: help status apply check diff verify clean update lint test setup dev ci docker
.DEFAULT_GOAL := help

# Colors for output
BLUE := \033[34m
GREEN := \033[32m
YELLOW := \033[33m
RED := \033[31m
RESET := \033[0m

##@ Build & Development

apply: ## Apply dotfiles configuration to system
	@echo "$(BLUE)Applying dotfiles configuration...$(RESET)"
	chezmoi apply -v

check: status ## Check what changes would be made (alias for status)

diff: ## Show differences between current state and dotfiles
	@echo "$(BLUE)Showing configuration differences...$(RESET)"
	chezmoi diff

status: ## Show status of dotfiles vs current system state
	@echo "$(BLUE)Checking dotfiles status...$(RESET)"
	chezmoi status

verify: ## Verify dotfiles configuration integrity
	@echo "$(BLUE)Verifying configuration integrity...$(RESET)"
	chezmoi verify .

##@ Testing

test: lint docker ## Run all tests (linting + container testing)

lint: ## Run all linters as used in CI
	@echo "$(BLUE)Running linters...$(RESET)"
	@if command -v shellcheck >/dev/null 2>&1; then \
		echo "$(GREEN)Running shellcheck...$(RESET)"; \
		find . -name "*.sh" -not -path "./node_modules/*" -exec shellcheck {} \; || echo "$(YELLOW)Warning: shellcheck found issues$(RESET)"; \
	else \
		echo "$(YELLOW)Warning: shellcheck not installed$(RESET)"; \
	fi
	@if command -v luacheck >/dev/null 2>&1; then \
		echo "$(GREEN)Running luacheck...$(RESET)"; \
		luacheck private_dot_config/nvim/lua || echo "$(YELLOW)Warning: luacheck found issues$(RESET)"; \
	else \
		echo "$(YELLOW)Warning: luacheck not installed$(RESET)"; \
	fi
	@if command -v actionlint >/dev/null 2>&1; then \
		echo "$(GREEN)Running actionlint...$(RESET)"; \
		actionlint || echo "$(YELLOW)Warning: actionlint found issues$(RESET)"; \
	else \
		echo "$(YELLOW)Warning: actionlint not installed$(RESET)"; \
	fi
	@if [ -f Brewfile ]; then \
		echo "$(GREEN)Checking Brewfile integrity...$(RESET)"; \
		brew bundle check --file=Brewfile || echo "$(YELLOW)Warning: Brewfile check failed$(RESET)"; \
	else \
		echo "$(YELLOW)Warning: Brewfile not found$(RESET)"; \
	fi

docker: ## Test full environment using Docker Compose
	@echo "$(BLUE)Testing environment with Docker...$(RESET)"
	@if [ -f docker-compose.yml ]; then \
		docker-compose up --build; \
	else \
		echo "$(RED)Error: docker-compose.yml not found$(RESET)"; \
		exit 1; \
	fi

##@ Environment Setup

setup: setup-brew setup-mise setup-nvim ## Complete initial environment setup

setup-brew: ## Install/update Homebrew packages
	@echo "$(BLUE)Setting up Homebrew packages...$(RESET)"
	@if [ -f Brewfile ]; then \
		brew bundle install --file=Brewfile; \
		brew cleanup; \
	else \
		echo "$(RED)Error: Brewfile not found$(RESET)"; \
		exit 1; \
	fi

setup-mise: ## Install mise tool versions
	@echo "$(BLUE)Setting up mise tools...$(RESET)"
	@if command -v mise >/dev/null 2>&1; then \
		mise install; \
	else \
		echo "$(YELLOW)Warning: mise not installed$(RESET)"; \
	fi

setup-nvim: ## Install/update Neovim plugins and LSP tools
	@echo "$(BLUE)Setting up Neovim plugins...$(RESET)"
	@if command -v nvim >/dev/null 2>&1; then \
		nvim --headless "+Lazy! sync" "+lua require('lazy').load({plugins={'mason.nvim'}})" "+MasonUpdate" +qa; \
	else \
		echo "$(YELLOW)Warning: neovim not installed$(RESET)"; \
	fi

##@ Quality Assurance

qa: lint check ## Run quality assurance checks

##@ Documentation

docs: ## Open documentation
	@echo "$(BLUE)Available documentation:$(RESET)"
	@echo "  README.md - Repository overview"
	@echo "  CLAUDE.md - AI assistant guidance"
	@echo "  CONVENTIONS.md - Development conventions"
	@echo "  docs/ - Detailed documentation"

docs-serve: ## Serve documentation locally (if available)
	@echo "$(YELLOW)Documentation serving not implemented yet$(RESET)"

##@ Utilities

update: ## Update all tools and packages
	@echo "$(BLUE)Updating all tools and packages...$(RESET)"
	@echo "$(GREEN)Updating Homebrew...$(RESET)"
	@if command -v brew >/dev/null 2>&1; then \
		brew update && brew upgrade && brew cleanup; \
	else \
		echo "$(YELLOW)Warning: brew not found$(RESET)"; \
	fi
	@echo "$(GREEN)Updating mise tools...$(RESET)"
	@if command -v mise >/dev/null 2>&1; then \
		mise upgrade; \
	else \
		echo "$(YELLOW)Warning: mise not found$(RESET)"; \
	fi
	@echo "$(GREEN)Updating Neovim plugins...$(RESET)"
	@if command -v nvim >/dev/null 2>&1; then \
		nvim --headless "+Lazy! sync" "+lua require('lazy').load({plugins={'mason.nvim'}})" "+MasonUpdate" +qa; \
	else \
		echo "$(YELLOW)Warning: nvim not found$(RESET)"; \
	fi
	@echo "$(GREEN)Updating pipx packages...$(RESET)"
	@if command -v pipx >/dev/null 2>&1; then \
		pipx upgrade-all; \
	else \
		echo "$(YELLOW)Warning: pipx not found$(RESET)"; \
	fi
	@echo "$(GREEN)Updating Claude CLI completion...$(RESET)"
	@$(MAKE) update-claude-completion

update-claude-completion: ## Update Claude CLI zsh completion
	@echo "$(BLUE)Updating Claude CLI completion...$(RESET)"
	@if [ -x "./scripts/generate-claude-completion-simple.sh" ]; then \
		./scripts/generate-claude-completion-simple.sh; \
	else \
		echo "$(YELLOW)Warning: Claude completion generator not found$(RESET)"; \
	fi

clean: ## Clean up temporary files and caches
	@echo "$(BLUE)Cleaning up...$(RESET)"
	@if command -v brew >/dev/null 2>&1; then \
		echo "$(GREEN)Cleaning Homebrew cache...$(RESET)"; \
		brew cleanup; \
	fi
	@echo "$(GREEN)Removing temporary files...$(RESET)"
	@find . -name "*.tmp" -delete 2>/dev/null || true
	@find . -name ".DS_Store" -delete 2>/dev/null || true

security-audit: ## Run security audit on configurations
	@echo "$(BLUE)Running security audit...$(RESET)"
	@echo "$(GREEN)Checking for secrets in files...$(RESET)"
	@if command -v rg >/dev/null 2>&1; then \
		rg -i "password|secret|token|key" --type-not lock --type-not json . || echo "$(GREEN)No obvious secrets found$(RESET)"; \
	else \
		echo "$(YELLOW)Warning: ripgrep not installed, cannot check for secrets$(RESET)"; \
	fi

colors: ## Display terminal color capabilities
	@echo "$(BLUE)Displaying terminal colors...$(RESET)"
	@awk -v term_cols="$${width:-$$(tput cols)}" 'BEGIN{ \
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

##@ CI/CD Integration

ci: lint ## Run CI checks locally
	@echo "$(BLUE)Running CI checks locally...$(RESET)"
	@echo "$(GREEN)All CI checks completed$(RESET)"

##@ Development

dev: ## Start development environment
	@echo "$(BLUE)Starting development environment...$(RESET)"
	@echo "$(GREEN)Running initial checks...$(RESET)"
	@$(MAKE) status
	@echo "$(GREEN)Development environment ready$(RESET)"
	@echo "$(YELLOW)Run 'make apply' to apply changes$(RESET)"

edit: ## Edit dotfiles configuration
	@echo "$(BLUE)Opening dotfiles for editing...$(RESET)"
	@if command -v nvim >/dev/null 2>&1; then \
		nvim .; \
	elif command -v code >/dev/null 2>&1; then \
		code .; \
	else \
		echo "$(YELLOW)No preferred editor found, please edit manually$(RESET)"; \
	fi

##@ Information

info: ## Show system and tool information
	@echo "$(BLUE)System Information:$(RESET)"
	@echo "OS: $$(uname -s) $$(uname -r)"
	@echo "Architecture: $$(uname -m)"
	@echo "Shell: $$SHELL"
	@echo ""
	@echo "$(BLUE)Tool Versions:$(RESET)"
	@echo -n "chezmoi: "; chezmoi --version 2>/dev/null || echo "not installed"
	@echo -n "brew: "; brew --version 2>/dev/null | head -1 || echo "not installed"
	@echo -n "mise: "; mise --version 2>/dev/null || echo "not installed"
	@echo -n "nvim: "; nvim --version 2>/dev/null | head -1 || echo "not installed"
	@echo -n "git: "; git --version 2>/dev/null || echo "not installed"

help: ## Display this help message
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make $(GREEN)<target>$(RESET)\n"} \
		/^[a-zA-Z_0-9-]+:.*?##/ { printf "  $(BLUE)%-15s$(RESET) %s\n", $$1, $$2 } \
		/^##@/ { printf "\n$(YELLOW)%s$(RESET)\n", substr($$0, 5) } ' $(MAKEFILE_LIST)
	@echo ""
	@echo "$(YELLOW)Integration Points:$(RESET)"
	@echo "  • Chezmoi tasks defined in .chezmoitasks.toml"
	@echo "  • Package management via Brewfile and mise"
	@echo "  • Neovim configuration in private_dot_config/nvim/"
	@echo "  • Shell configuration for Fish in private_dot_config/fish/"
	@echo "  • CI/CD pipeline in .github/workflows/smoke.yml"
