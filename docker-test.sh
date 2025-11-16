#!/usr/bin/env bash
# Docker testing helper for chezmoi dotfiles

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

usage() {
    cat <<EOF
Usage: $0 <command>

Commands:
    build       Build the dotfiles container
    run         Build and run interactive shell
    test        Build and run chezmoi verify
    clean       Remove container and image
    shell       Run shell in existing container
    logs        Show build logs

Examples:
    $0 build              # Build the container
    $0 run                # Build and start interactive fish shell
    $0 test               # Quick verification test
    $0 clean              # Clean up everything

EOF
}

build() {
    echo "🔨 Building dotfiles container..."
    docker compose build
}

run_interactive() {
    echo "🚀 Starting interactive dotfiles container..."
    build
    docker compose run --rm dotfiles
}

test_dotfiles() {
    echo "🧪 Testing dotfiles installation..."
    build
    docker compose run --rm dotfiles fish -c "
        echo '=== Chezmoi Status ==='
        chezmoi verify
        echo ''
        echo '=== Fish Shell ==='
        fish --version
        echo ''
        echo '=== Git Config ==='
        git config --global --list | head -5 || echo 'No git config found'
    "
}

clean() {
    echo "🧹 Cleaning up containers and images..."
    docker compose down --rmi all --volumes --remove-orphans
}

shell() {
    echo "🐚 Opening shell in dotfiles container..."
    docker compose exec dotfiles fish
}

logs() {
    echo "📋 Showing container logs..."
    docker compose logs --tail=50 dotfiles
}

case "${1:-}" in
    build)
        build
        ;;
    run)
        run_interactive
        ;;
    test)
        test_dotfiles
        ;;
    clean)
        clean
        ;;
    shell)
        shell
        ;;
    logs)
        logs
        ;;
    -h|--help|help)
        usage
        ;;
    *)
        echo "Error: Unknown command '${1:-}'"
        echo ""
        usage
        exit 1
        ;;
esac
