#!/bin/zsh
# macOS setup script

# Check for required font
echo "Checking for required font..."
fc-list | grep "Hack Nerd Font"

# Disable "last login" prompt
echo "Disabling 'last login' prompt..."
touch ~/.hushlogin

# Install and update packages
echo "Installing and updating packages..."
brew bundle

# Cleanup brew files
echo "Cleaning up brew files..."
brew cleanup

# Brew health check
echo "Running brew health check..."
brew doctor

# Disable keyboard shortcuts
echo "Configuring macOS keyboard shortcuts..."
# Disable Keyboard -> Shortcuts -> Mission Control -> Move left/right a space.
defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 79 "{enabled = 0; value = { parameters = (65535, 123, 8650752); type = standard;};}"
defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 80 "{enabled = 0; value = { parameters = (65535, 123, 8781824); type = standard;};}"
defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 81 "{enabled = 0; value = { parameters = (65535, 124, 8650752); type = standard;};}"
defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 82 "{enabled = 0; value = { parameters = (65535, 124, 8781824); type = standard;};}"
# Update in-memory cache
defaults read com.apple.symbolichotkeys.plist > /dev/null
# Apply updated settings
/System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u

# Build fzf-tab module
echo "Building fzf-tab module for colorization..."
brew install groff autoconf
source ./zsh/fzf-tab/fzf-tab.zsh
build-fzf-tab-module

echo "Setup complete!"
