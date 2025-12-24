#!/usr/bin/env bash
# Smoke test script for Docker container or host environment
# Reproduces .github/workflows/smoke.yml locally
#
# Usage:
#   ./scripts/smoke-test-docker.sh         # Run all stages
#   ./scripts/smoke-test-docker.sh lint    # Run lint stage only
#   ./scripts/smoke-test-docker.sh build   # Run build stage only
#
set -euo pipefail

# Colors for output
BLUE='\033[34m'
GREEN='\033[32m'
YELLOW='\033[33m'
RED='\033[31m'
RESET='\033[0m'

# Parse command line arguments
STAGE="${1:-all}"

log_info() { echo -e "${BLUE}ℹ️  $1${RESET}"; }
log_success() { echo -e "${GREEN}✅ $1${RESET}"; }
log_warning() { echo -e "${YELLOW}⚠️  $1${RESET}"; }
log_error() { echo -e "${RED}❌ $1${RESET}"; }
log_section() { echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"; echo -e "${BLUE}📋 $1${RESET}"; echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}\n"; }

# Check and install dependencies
ensure_dependencies() {
    log_section "Dependency Check"

    # Check for pre-commit
    if ! command -v pre-commit &> /dev/null; then
        log_warning "pre-commit not found, attempting to install..."
        # Check for uv first (uvx is just an alias for 'uv tool run')
        if command -v uv &> /dev/null; then
            log_info "Installing pre-commit via uv..."
            uv tool install pre-commit
            # Add uv tools to PATH for this session
            export PATH="$HOME/.local/bin:$PATH"
        elif command -v pip3 &> /dev/null; then
            log_info "Installing pre-commit via pip3..."
            pip3 install --user pre-commit
            export PATH="$HOME/.local/bin:$PATH"
        elif command -v pip &> /dev/null; then
            log_info "Installing pre-commit via pip..."
            pip install --user pre-commit
            export PATH="$HOME/.local/bin:$PATH"
        else
            log_error "Cannot install pre-commit: no suitable package manager found"
            log_info "Please install pre-commit manually: pip install pre-commit"
            return 1
        fi
        # Verify installation
        if command -v pre-commit &> /dev/null; then
            log_success "pre-commit installed successfully"
        else
            log_error "pre-commit installation failed"
            return 1
        fi
    else
        log_success "pre-commit found: $(pre-commit --version)"
    fi

    # Check for chezmoi
    if ! command -v chezmoi &> /dev/null; then
        log_warning "chezmoi not found, attempting to install..."
        if command -v brew &> /dev/null; then
            log_info "Installing chezmoi via brew..."
            brew install chezmoi
        else
            log_info "Installing chezmoi via official installer..."
            sh -c "$(curl -fsSL https://www.chezmoi.io/get)" -- -b "$HOME/.local/bin"
            export PATH="$HOME/.local/bin:$PATH"
        fi
        # Verify installation
        if command -v chezmoi &> /dev/null; then
            log_success "chezmoi installed successfully"
        else
            log_error "chezmoi installation failed"
            return 1
        fi
    else
        log_success "chezmoi found: $(chezmoi --version)"
    fi

    log_success "All dependencies satisfied"
}

# Stage: Lint
run_lint() {
    log_section "Stage: LINT"

    log_info "Running pre-commit hooks..."
    if pre-commit run --all-files; then
        log_success "pre-commit passed"
    else
        log_error "pre-commit failed"
        return 1
    fi

    # Validate source directory and templates
    # Note: chezmoi verify checks destination=target, which fails before apply.
    # Instead, use chezmoi diff to validate templates parse correctly.
    # diff returns exit 1 when there are differences (expected), so check stderr for errors.
    log_info "Running chezmoi diff (validates templates)..."
    local diff_errors
    diff_errors=$(chezmoi diff --source=. 2>&1 >/dev/null) || true
    if [[ -z "$diff_errors" ]]; then
        log_success "chezmoi templates validated"
    else
        log_error "chezmoi template validation failed"
        echo "$diff_errors"
        return 1
    fi

    log_success "Lint stage completed"
}

# Stage: Build
run_build() {
    log_section "Stage: BUILD"

    # Health checks
    log_info "Running environment health checks..."

    if command -v brew &> /dev/null; then
        log_info "Homebrew doctor..."
        if brew doctor 2>&1; then
            log_success "Homebrew is healthy"
        else
            log_warning "Homebrew has warnings (non-fatal)"
        fi
    else
        log_warning "Homebrew not installed, skipping brew doctor"
    fi

    if command -v mise &> /dev/null; then
        log_info "mise doctor..."
        if mise doctor 2>&1; then
            log_success "mise is healthy"
        else
            log_warning "mise has warnings"
        fi
    else
        log_warning "mise not installed, skipping mise doctor"
    fi

    # Apply dotfiles
    log_info "Running chezmoi apply..."
    # Use --source to specify current directory as source (works without chezmoi init)
    if chezmoi apply --source=. -v; then
        log_success "chezmoi apply succeeded"
    else
        log_error "chezmoi apply failed"
        return 1
    fi

    # Test zsh initialization (if zsh is available)
    if command -v zsh &> /dev/null; then
        log_info "Testing zsh shell initialization..."
        if timeout 10s zsh -c "
            source ~/.zshrc
            if [[ -n \"\$ZSH_VERSION\" ]]; then
                echo '✅ zsh configuration loaded successfully'
            else
                echo '❌ zsh configuration failed to load'
                exit 1
            fi
            if [[ -n \"\$PROMPT\" ]] || [[ -n \"\$PS1\" ]]; then
                echo '✅ zsh prompt configured'
            else
                echo '❌ zsh prompt not configured'
                exit 1
            fi
        "; then
            log_success "zsh initialization test passed"
        else
            log_error "zsh initialization test failed"
            return 1
        fi
    else
        log_warning "zsh not installed, skipping shell initialization test"
    fi

    log_success "Build stage completed"
}

# Main execution
main() {
    log_section "Smoke Test Runner"
    log_info "Stage: ${STAGE}"
    log_info "Working directory: $(pwd)"

    # Ensure all required tools are available
    ensure_dependencies

    case "$STAGE" in
        lint)
            run_lint
            ;;
        build)
            run_build
            ;;
        all)
            run_lint
            run_build
            ;;
        *)
            log_error "Unknown stage: $STAGE"
            log_info "Usage: $0 [lint|build|all]"
            exit 1
            ;;
    esac

    log_section "Smoke Test Complete"
    log_success "All stages passed!"
}

main "$@"
