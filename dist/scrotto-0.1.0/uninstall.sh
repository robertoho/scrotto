#!/bin/bash

# Scrotto - Uninstall Script

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

print_status() { echo -e "${GREEN}✅ $1${NC}"; }
print_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }

echo -e "${BLUE}🗑️  Uninstalling Scrotto${NC}"
echo "========================"

# Remove binary
if [[ -f "$HOME/.local/bin/scrotto" ]]; then
    rm "$HOME/.local/bin/scrotto"
    print_status "Removed binary from ~/.local/bin"
else
    print_warning "Binary not found in ~/.local/bin"
fi

# Remove desktop entry
if [[ -f "$HOME/.local/share/applications/scrotto.desktop" ]]; then
    rm "$HOME/.local/share/applications/scrotto.desktop"
    print_status "Removed desktop entry"
    
    # Update desktop database if available
    if command -v update-desktop-database >/dev/null 2>&1; then
        update-desktop-database ~/.local/share/applications/ 2>/dev/null || true
    fi
else
    print_warning "Desktop entry not found"
fi

# Note about keyboard shortcuts
print_info "Manual cleanup needed:"
echo "  • Remove custom keyboard shortcuts from Settings > Keyboard"
echo "  • Custom shortcuts pointing to scrotto"

print_status "Uninstallation completed!"
