#!/bin/bash

# Scrotto - Installation Script
# Installs the binary and sets up desktop entry

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
print_error() { echo -e "${RED}❌ $1${NC}"; }

echo -e "${BLUE}📸 Installing Scrotto for Ubuntu${NC}"
echo "=================================="

# Check if binary exists
if [[ ! -f "scrotto" ]]; then
    print_error "scrotto binary not found in current directory"
    exit 1
fi

# Install binary
print_info "Installing binary to ~/.local/bin"
mkdir -p ~/.local/bin
cp scrotto ~/.local/bin/
chmod +x ~/.local/bin/scrotto

# Add to PATH if needed
if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
    print_warning "Added ~/.local/bin to PATH in ~/.bashrc"
    print_info "You may need to restart your terminal or run: source ~/.bashrc"
fi

# Create desktop entry
print_info "Creating desktop entry"
mkdir -p ~/.local/share/applications

cat > ~/.local/share/applications/scrotto.desktop << EOD
[Desktop Entry]
Name=Scrotto
Comment=Capture screen area and extract text with OCR
Exec=$HOME/.local/bin/scrotto
Icon=applications-graphics
Terminal=false
Type=Application
Categories=Graphics;Photography;Utility;
Keywords=screenshot;ocr;text;capture;extract;
StartupNotify=false
EOD

# Update desktop database if available
if command -v update-desktop-database >/dev/null 2>&1; then
    update-desktop-database ~/.local/share/applications/ 2>/dev/null || true
fi

# Set up keyboard shortcut automatically
print_info "Setting up keyboard shortcut (Shift+Super+A)"
setup_keyboard_shortcut() {
    # Check if we're in a GNOME environment
    if [[ "$XDG_CURRENT_DESKTOP" == *"GNOME"* ]] || command -v gsettings >/dev/null 2>&1; then
        # Find an available custom keybinding slot
        local slot_found=""
        for i in {0..30}; do
            local existing_name=$(gsettings get org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom$i/ name 2>/dev/null)
            if [[ "$existing_name" == "''" ]] || [[ -z "$existing_name" ]]; then
                slot_found="custom$i"
                break
            fi
        done
        
        if [[ -n "$slot_found" ]]; then
            # Get current custom keybindings list
            local current_bindings=$(gsettings get org.gnome.settings-daemon.plugins.media-keys custom-keybindings)
            local keybinding_path="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/$slot_found/"
            
            # Add our keybinding path if not already present
            if [[ "$current_bindings" != *"$keybinding_path"* ]]; then
                if [[ "$current_bindings" == "@as []" ]]; then
                    # Empty list
                    gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "['$keybinding_path']"
                else
                    # Add to existing list
                    local new_bindings="${current_bindings%]}, '$keybinding_path']"
                    gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "$new_bindings"
                fi
            fi
            
            # Set the keybinding properties
            gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$keybinding_path name "Scrotto"
            gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$keybinding_path command "$HOME/.local/bin/scrotto"
            gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$keybinding_path binding "<Shift><Super>a"
            
            print_status "Keyboard shortcut created: Shift+Super+A"
            return 0
        else
            print_warning "No available keybinding slots found"
            return 1
        fi
    else
        print_warning "GNOME environment not detected, skipping automatic keybinding setup"
        return 1
    fi
}

# Try to set up keyboard shortcut
if ! setup_keyboard_shortcut; then
    print_info "Manual keyboard shortcut setup:"
    echo "  1. Go to Settings > Keyboard > View and Customize Shortcuts"
    echo "  2. Scroll to 'Custom Shortcuts' and click '+'"
    echo "  3. Name: Scrotto"
    echo "  4. Command: $HOME/.local/bin/scrotto"
    echo "  5. Set shortcut: Shift+Super+A"
fi

print_status "Installation completed successfully!"
echo ""
print_info "Usage:"
echo "  scrotto           # Select area to capture text"
echo "  scrotto --full    # Capture entire screen"
echo "  Shift+Super+A     # Keyboard shortcut (if setup succeeded)"
echo ""
print_info "Requirements (install if needed):"
echo "  • sudo apt install gnome-screenshot tesseract-ocr"
print_status "Ready to capture and extract text! 🎯"
