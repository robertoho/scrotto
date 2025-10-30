#!/bin/bash

# Screen Text Grabber - Installation Script
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

echo -e "${BLUE}📸 Installing Screen Text Grabber for Ubuntu${NC}"
echo "=============================================="

# Check if binary exists
if [[ ! -f "screen_text_grabber" ]]; then
    print_error "screen_text_grabber binary not found in current directory"
    exit 1
fi

# Install binary
print_info "Installing binary to ~/.local/bin"
mkdir -p ~/.local/bin
cp screen_text_grabber ~/.local/bin/
chmod +x ~/.local/bin/screen_text_grabber

# Add to PATH if needed
if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
    print_warning "Added ~/.local/bin to PATH in ~/.bashrc"
    print_info "You may need to restart your terminal or run: source ~/.bashrc"
fi

# Create desktop entry
print_info "Creating desktop entry"
mkdir -p ~/.local/share/applications

cat > ~/.local/share/applications/screen-text-grabber.desktop << EOD
[Desktop Entry]
Name=Screen Text Grabber
Comment=Capture screen area and extract text with OCR
Exec=$HOME/.local/bin/screen_text_grabber
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

print_status "Installation completed successfully!"
echo ""
print_info "Usage:"
echo "  screen_text_grabber           # Select area to capture text"
echo "  screen_text_grabber --full    # Capture entire screen"
echo ""
print_info "Set up keyboard shortcuts:"
echo "  1. Go to Settings > Keyboard > View and Customize Shortcuts"
echo "  2. Scroll to 'Custom Shortcuts' and click '+'"
echo "  3. Name: Screen Text Grabber"
echo "  4. Command: $HOME/.local/bin/screen_text_grabber"
echo "  5. Set your preferred shortcut (e.g., Shift+Super+T)"
echo ""
print_info "Requirements (install if needed):"
echo "  • sudo apt install gnome-screenshot tesseract-ocr"
print_status "Ready to capture and extract text! 🎯"
