# macOS Settings Automation

This document describes the automated macOS settings configuration system in your dotfiles.

## Overview

The dotfiles include comprehensive macOS settings automation that:
- ✅ **Version controls** all macOS preferences
- 🔄 **Automatically applies** settings across workstations
- 🎯 **Targets developer workflows** (keyboard shortcuts, terminal optimization)
- 🔧 **Easy to extend** with new settings

## Files Involved

| File | Purpose |
|------|---------|
| `run_onchange_macos-settings.sh.tmpl` | Main automation script (runs on changes) |
| `macos-settings.toml` | Configuration file that triggers updates |
| `.chezmoitasks.toml` | Legacy setup tasks (includes initial keyboard shortcuts) |

## Current Automated Settings

### 🎯 **Keyboard Shortcuts** (Primary Goal)
- **Disables Mission Control space navigation** to free up Ctrl+Left/Right for terminal use
  - `Ctrl+Left Arrow` → Disabled (ID 79)
  - `Ctrl+Right Arrow` → Disabled (ID 81)
  - `Ctrl+Shift+Left Arrow` → Disabled (ID 80)
  - `Ctrl+Shift+Right Arrow` → Disabled (ID 82)

### 📁 **Finder Optimization**
- Show hidden files and file extensions
- Enable path bar and status bar
- Set column view as default

### 🚢 **Dock Configuration**
- Auto-hide dock for more screen space
- Minimize to application icons
- Hide recent applications

### 💻 **Development Environment**
- Fast key repeat (disable press-and-hold)
- Optimized key repeat rates
- Password security settings

### 🖱️ **Trackpad Enhancement**
- Tap to click enabled
- Three-finger drag enabled

## How It Works

### Automatic Execution
1. **Initial Setup**: Settings applied during first `chezmoi apply`
2. **Change Detection**: Script runs when `macos-settings.toml` is modified
3. **Cross-Machine Sync**: Settings automatically applied on new workstations

### Template System
The script uses chezmoi templating:
```bash
{{- if eq .chezmoi.os "darwin" }}
# macOS-specific settings here
{{- end }}
```

### Hash-Based Updates
```bash
# Template hash: {{ include "macos-settings.toml" | sha256sum }}
```
This ensures the script runs whenever the configuration changes.

## Adding New Settings

### 1. Update Configuration
Edit `macos-settings.toml`:
```toml
[new_category]
setting_name = true
```

### 2. Implement in Script
Add to `run_onchange_macos-settings.sh.tmpl`:
```bash
echo "🔧 Configuring new category..."
defaults write com.apple.example SettingKey -bool true
```

### 3. Apply Changes
```bash
chezmoi diff    # Review changes
chezmoi apply   # Apply settings
```

## Common Commands Reference

### View Current Settings
```bash
# List all keyboard shortcuts
defaults read com.apple.symbolichotkeys AppleSymbolicHotKeys

# View specific domain
defaults read com.apple.finder

# Search for settings
defaults find ShowPathbar
```

### Manual Testing
```bash
# Test the script directly
./run_onchange_macos-settings.sh.tmpl

# Apply keyboard shortcut changes immediately
/System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u
```

### Troubleshooting
```bash
# Check if chezmoi detects changes
chezmoi diff

# Force re-run the script
touch macos-settings.toml
chezmoi apply
```

## Security Considerations

- ✅ **No sensitive data** stored in configuration
- ✅ **Read-only operations** where possible
- ✅ **Error handling** for failed operations
- ✅ **Version controlled** changes

## Extending the System

### Adding Screenshot Settings
```toml
[screenshots]
location = "~/Desktop/Screenshots"
format = "png"
```

```bash
# In the script
echo "📸 Configuring screenshots..."
mkdir -p "~/Desktop/Screenshots"
defaults write com.apple.screencapture location "~/Desktop/Screenshots"
defaults write com.apple.screencapture type png
```

### Adding Menu Bar Settings
```toml
[menu_bar]
show_battery_percentage = true
hide_siri = true
```

```bash
# In the script
echo "📊 Configuring menu bar..."
defaults write com.apple.menuextra.battery ShowPercent YES
defaults write com.apple.Siri StatusMenuVisible -bool false
```

## Best Practices

1. **Test First**: Always run `chezmoi diff` before applying
2. **Document Changes**: Update this file when adding new settings
3. **Use Comments**: Explain complex `defaults` commands
4. **Error Handling**: Include fallbacks for failed operations
5. **Restart Services**: Kill/restart affected applications when needed

## Resources

- [macOS defaults Reference](https://macos-defaults.com/)
- [Apple Configuration Profile Reference](https://developer.apple.com/documentation/devicemanagement/configurationprofile)
- [macOS Keyboard Shortcuts Research](../research_macos_shortcuts.md)
