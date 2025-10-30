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

# Remove keyboard shortcut
print_info "Removing keyboard shortcut"
remove_keyboard_shortcut() {
    if [[ "$XDG_CURRENT_DESKTOP" == *"GNOME"* ]] || command -v gsettings >/dev/null 2>&1; then
        # Find and remove the Scrotto keybinding
        local current_bindings=$(gsettings get org.gnome.settings-daemon.plugins.media-keys custom-keybindings)
        local removed_any=""
        
        for i in {0..30}; do
            local keybinding_path="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom$i/"
            local existing_name=$(gsettings get org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$keybinding_path name 2>/dev/null)
            local existing_command=$(gsettings get org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$keybinding_path command 2>/dev/null)
            
            if [[ "$existing_name" == "'Scrotto'" ]] || [[ "$existing_command" == *"scrotto"* ]]; then
                # Remove this keybinding
                gsettings reset org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$keybinding_path name 2>/dev/null || true
                gsettings reset org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$keybinding_path command 2>/dev/null || true
                gsettings reset org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$keybinding_path binding 2>/dev/null || true
                
                # Remove from the custom-keybindings list
                local new_bindings=$(echo "$current_bindings" | sed "s|'$keybinding_path'||g" | sed 's/,,/,/g' | sed 's/\[,/[/g' | sed 's/,\]/]/g')
                if [[ "$new_bindings" != "$current_bindings" ]]; then
                    gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "$new_bindings"
                    current_bindings="$new_bindings"
                fi
                
                removed_any="yes"
                print_status "Removed Scrotto keyboard shortcut"
            fi
        done
        
        if [[ -z "$removed_any" ]]; then
            print_warning "No Scrotto keyboard shortcuts found to remove"
        fi
    else
        print_warning "GNOME environment not detected, skipping automatic keybinding removal"
        print_info "Manual cleanup may be needed:"
        echo "  • Check Settings > Keyboard for any remaining Scrotto shortcuts"
    fi
}

remove_keyboard_shortcut

print_status "Uninstallation completed!"
