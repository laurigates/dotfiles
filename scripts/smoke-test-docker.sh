#!/usr/bin/env bash
# Smoke test script for Docker container
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

    log_info "Running chezmoi verify..."
    if chezmoi verify .; then
        log_success "chezmoi verify passed"
    else
        log_error "chezmoi verify failed"
        return 1
    fi

    log_success "Lint stage completed"
}

# Stage: Build
run_build() {
    log_section "Stage: BUILD"

    # Health checks
    log_info "Running environment health checks..."

    log_info "Homebrew doctor..."
    if brew doctor 2>&1; then
        log_success "Homebrew is healthy"
    else
        log_warning "Homebrew has warnings (non-fatal)"
    fi

    log_info "mise doctor..."
    if mise doctor 2>&1; then
        log_success "mise is healthy"
    else
        log_warning "mise has warnings"
    fi

    # Apply dotfiles
    log_info "Running chezmoi apply..."
    if chezmoi apply -v; then
        log_success "chezmoi apply succeeded"
    else
        log_error "chezmoi apply failed"
        return 1
    fi

    # Test zsh initialization
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

    log_success "Build stage completed"
}

# Main execution
main() {
    log_section "Smoke Test Runner"
    log_info "Stage: ${STAGE}"
    log_info "Working directory: $(pwd)"

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
