#!/usr/bin/env bash
# macOS system defaults. Safe to re-run.
# Requires macOS Sonoma (14) or later.
set -euo pipefail

info()    { printf '\033[0;34m[macos]\033[0m %s\n' "$*"; }
success() { printf '\033[0;32m[macos]\033[0m %s\n' "$*"; }
warn()    { printf '\033[0;33m[macos]\033[0m %s\n' "$*"; }

# Verify macOS version (Sonoma = 14)
os_major=$(sw_vers -productVersion | cut -d. -f1)
if [ "$os_major" -lt 14 ]; then
  warn "This script targets macOS 14 (Sonoma)+. Some settings may not apply on $(sw_vers -productVersion)."
fi

info "Applying macOS defaults..."

# ── Keyboard ──────────────────────────────────────────────────────────────────
# Faster key repeat (lower = faster; default is 6)
defaults write NSGlobalDomain KeyRepeat -int 2
# Shorter delay before repeat starts (default is 25)
defaults write NSGlobalDomain InitialKeyRepeat -int 15
# Disable autocorrect
defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false
# Disable smart quotes and dashes (annoying in terminals/editors)
defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false

# ── Trackpad ──────────────────────────────────────────────────────────────────
# Tap to click (covers both built-in and Bluetooth trackpads)
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
defaults write com.apple.AppleMultitouchTrackpad Clicking -bool true
defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 1
# Tracking speed (0=slow … 3=fast; 1 is medium-high)
defaults write NSGlobalDomain com.apple.trackpad.scaling -float 2
defaults write NSGlobalDomain com.apple.mouse.scaling -float 2

# ── Finder ────────────────────────────────────────────────────────────────────
# Show hidden files
defaults write com.apple.finder AppleShowAllFiles -bool true
# Show all filename extensions
defaults write NSGlobalDomain AppleShowAllExtensions -bool true
# Show path bar and status bar
defaults write com.apple.finder ShowPathbar -bool true
defaults write com.apple.finder ShowStatusBar -bool true
# Default to list view
defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"
# Keep folders on top when sorting
defaults write com.apple.finder _FXSortFoldersFirst -bool true
# Disable the warning when changing a file extension
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false
# Don't create .DS_Store on network or USB volumes
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true

# ── Screenshots ───────────────────────────────────────────────────────────────
# Save to iCloud Drive/Screenshots
_SCREENSHOTS="$HOME/Library/Mobile Documents/com~apple~CloudDocs/Screenshots"
mkdir -p "$_SCREENSHOTS"
defaults write com.apple.screencapture location -string "$_SCREENSHOTS"
# Save as PNG, no sound, no shadow
defaults write com.apple.screencapture type -string "png"
defaults write com.apple.screencapture sound -bool false
defaults write com.apple.screencapture disable-shadow -bool true

# ── Dock ──────────────────────────────────────────────────────────────────────
# Auto-hide
defaults write com.apple.dock autohide -bool true
# Remove auto-hide delay
defaults write com.apple.dock autohide-delay -float 0
defaults write com.apple.dock autohide-time-modifier -float 0.3
# Don't show recent apps in Dock
defaults write com.apple.dock show-recents -bool false

# ── Spotlight ─────────────────────────────────────────────────────────────────
# Enable only apps, calculator, and dictionary (Raycast handles everything else)
defaults write com.apple.spotlight EnabledPreferenceRules -array \
  "System.applications" \
  "System.calculator" \
  "System.definition"

# ── Misc ──────────────────────────────────────────────────────────────────────
# Expand save and print panels by default
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true
defaults write NSGlobalDomain PMPrintingExpandedStateForPrint -bool true
# Disable "Are you sure you want to open this application?" dialog
defaults write com.apple.LaunchServices LSQuarantine -bool false

# ── Flush preferences cache and restart affected apps ─────────────────────────
killall cfprefsd 2>/dev/null || true
for app in Finder Dock SystemUIServer; do
  killall "$app" &>/dev/null || true
done

success "Done. Keyboard shortcuts and input methods take effect immediately."
success "Trackpad, screenshot location, and some Finder changes require a logout."
