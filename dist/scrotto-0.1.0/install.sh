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

print_status "Installation completed successfully!"
echo ""
print_info "Usage:"
echo "  scrotto           # Select area to capture text"
echo "  scrotto --full    # Capture entire screen"
echo ""
print_info "Set up keyboard shortcuts:"
echo "  1. Go to Settings > Keyboard > View and Customize Shortcuts"
echo "  2. Scroll to 'Custom Shortcuts' and click '+'"
echo "  3. Name: Scrotto"
echo "  4. Command: $HOME/.local/bin/scrotto"
echo "  5. Set your preferred shortcut (e.g., Shift+Super+T)"
echo ""
print_info "Requirements (install if needed):"
echo "  • sudo apt install gnome-screenshot tesseract-ocr"
print_status "Ready to capture and extract text! 🎯"
