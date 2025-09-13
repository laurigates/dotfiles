#!/bin/bash
set -euo pipefail

# Migration script from pipx to uv tool
echo "🔄 Starting migration from pipx to uv tool..."

# Check if uv is installed
if ! command -v uv &> /dev/null; then
    echo "❌ uv is not installed. Please install it first:"
    echo "   brew install uv"
    exit 1
fi

# Check if pipx is installed
if ! command -v pipx &> /dev/null; then
    echo "⚠️  pipx is not installed, nothing to migrate"
    exit 0
fi

# Get list of installed pipx packages
echo "📦 Getting list of installed pipx packages..."
PIPX_PACKAGES=$(pipx list --short 2>/dev/null | awk '{print $1}' || true)

if [ -z "$PIPX_PACKAGES" ]; then
    echo "ℹ️  No pipx packages found to migrate"
    exit 0
fi

echo "📋 Found the following pipx packages to migrate:"
echo "$PIPX_PACKAGES" | while read -r package; do
    echo "   - $package"
done

# Ask for confirmation
echo ""
read -p "Do you want to proceed with migration? (y/n) " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Migration cancelled"
    exit 0
fi

# Create backup list of packages
BACKUP_FILE="$HOME/.pipx_packages_backup_$(date +%Y%m%d_%H%M%S).txt"
echo "$PIPX_PACKAGES" > "$BACKUP_FILE"
echo "📝 Backed up package list to: $BACKUP_FILE"

# Special handling for certain packages
echo ""
echo "🔄 Migrating packages to uv tool..."
echo ""

# Counter for successful migrations
SUCCESS_COUNT=0
FAIL_COUNT=0
FAILED_PACKAGES=""

# Migrate each package
echo "$PIPX_PACKAGES" | while IFS= read -r package; do
    echo "📦 Migrating $package..."

    # Special handling for specific packages
    case "$package" in
        "sequential-thinking")
            # This package needs portalocker as an additional dependency
            if uv tool install "git+https://github.com/arben-adm/mcp-sequential-thinking" --with portalocker 2>/dev/null; then
                echo "   ✅ Successfully migrated $package with portalocker"
                ((SUCCESS_COUNT++))
                pipx uninstall "$package" --verbose 2>/dev/null || true
            else
                echo "   ❌ Failed to migrate $package"
                ((FAIL_COUNT++))
                FAILED_PACKAGES="$FAILED_PACKAGES\n   - $package"
            fi
            ;;
        "zen-mcp-server")
            if uv tool install "git+https://github.com/BeehiveInnovations/zen-mcp-server" 2>/dev/null; then
                echo "   ✅ Successfully migrated $package"
                ((SUCCESS_COUNT++))
                pipx uninstall "$package" --verbose 2>/dev/null || true
            else
                echo "   ❌ Failed to migrate $package"
                ((FAIL_COUNT++))
                FAILED_PACKAGES="$FAILED_PACKAGES\n   - $package"
            fi
            ;;
        "vectorcode")
            # This package has extras [mcp,cli]
            if uv tool install 'vectorcode[mcp,cli]' 2>/dev/null; then
                echo "   ✅ Successfully migrated $package with extras"
                ((SUCCESS_COUNT++))
                pipx uninstall "$package" --verbose 2>/dev/null || true
            else
                echo "   ❌ Failed to migrate $package"
                ((FAIL_COUNT++))
                FAILED_PACKAGES="$FAILED_PACKAGES\n   - $package"
            fi
            ;;
        "uv")
            echo "   ⏭️  Skipping uv (already managed by brew)"
            ;;
        *)
            # Standard migration for other packages
            if uv tool install "$package" 2>/dev/null; then
                echo "   ✅ Successfully migrated $package"
                ((SUCCESS_COUNT++))
                pipx uninstall "$package" --verbose 2>/dev/null || true
            else
                echo "   ❌ Failed to migrate $package"
                ((FAIL_COUNT++))
                FAILED_PACKAGES="$FAILED_PACKAGES\n   - $package"
            fi
            ;;
    esac
done

echo ""
echo "🎉 Migration Summary:"
echo "   ✅ Successfully migrated: $SUCCESS_COUNT packages"
if [ $FAIL_COUNT -gt 0 ]; then
    echo "   ❌ Failed to migrate: $FAIL_COUNT packages"
    echo -e "$FAILED_PACKAGES"
    echo ""
    echo "⚠️  For failed packages, you may need to:"
    echo "   1. Check if the package name is correct"
    echo "   2. Install manually with: uv tool install <package>"
    echo "   3. Check the backup file: $BACKUP_FILE"
fi

echo ""
echo "📋 Final Steps:"
echo "   1. Run 'uv tool list' to verify all tools are installed"
echo "   2. Test that your tools work correctly"
echo "   3. Once verified, you can uninstall pipx: brew uninstall pipx"
echo "   4. Update your shell completions if needed"
echo ""
echo "✅ Migration script completed!"
