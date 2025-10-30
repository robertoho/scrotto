#!/bin/bash

# Distribution Package Builder for Scrotto
# Creates a ready-to-install package for publishing

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

# Package info
PACKAGE_NAME="scrotto"
VERSION=$(grep '^version' Cargo.toml | cut -d'"' -f2)
DIST_DIR="dist"
PACKAGE_DIR="$DIST_DIR/$PACKAGE_NAME-$VERSION"

echo -e "${CYAN}📦 Scrotto Distribution Builder${NC}"
echo "=========================================="
echo -e "${BLUE}Version: $VERSION${NC}"
echo ""

# Clean and create distribution directory
echo -e "${BLUE}🧹 Preparing distribution directory...${NC}"
rm -rf "$DIST_DIR"
mkdir -p "$PACKAGE_DIR"

# Build the project
echo -e "${BLUE}🔨 Building release binary...${NC}"
cargo build --release

# Check if binary exists
if [[ ! -f "target/release/scrotto" ]]; then
    echo -e "${RED}❌ Build failed - binary not found${NC}"
    exit 1
fi

# Copy binary
echo -e "${BLUE}📁 Copying files...${NC}"
cp target/release/scrotto "$PACKAGE_DIR/"

# Copy documentation
cp README.md "$PACKAGE_DIR/"
cp Cargo.toml "$PACKAGE_DIR/"

# Create installation script
echo -e "${BLUE}📝 Creating installation script...${NC}"
cat > "$PACKAGE_DIR/install.sh" << 'EOF'
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
print_info "Setting up keyboard shortcut (Shift+Super+T)"
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
            gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$keybinding_path binding "<Shift><Super>t"
            
            print_status "Keyboard shortcut created: Shift+Super+T"
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
    echo "  5. Set shortcut: Shift+Super+T"
fi

print_status "Installation completed successfully!"
echo ""
print_info "Usage:"
echo "  scrotto           # Select area to capture text"
echo "  scrotto --full    # Capture entire screen"
echo "  Shift+Super+T     # Keyboard shortcut (if setup succeeded)"
echo ""
print_info "Requirements (install if needed):"
echo "  • sudo apt install gnome-screenshot tesseract-ocr"
print_status "Ready to capture and extract text! 🎯"
EOF

chmod +x "$PACKAGE_DIR/install.sh"

# Create uninstall script
echo -e "${BLUE}🗑️  Creating uninstall script...${NC}"
cat > "$PACKAGE_DIR/uninstall.sh" << 'EOF'
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
EOF

chmod +x "$PACKAGE_DIR/uninstall.sh"

# Create a simple README for the package
echo -e "${BLUE}📄 Creating package README...${NC}"
cat > "$PACKAGE_DIR/INSTALL.md" << 'EOF'
# Scrotto - Installation

## Quick Install

```bash
# Make the install script executable and run it
chmod +x install.sh
./install.sh
```

## Manual Installation

1. Copy the binary to your local bin directory:
   ```bash
   mkdir -p ~/.local/bin
   cp scrotto ~/.local/bin/
   chmod +x ~/.local/bin/scrotto
   ```

2. Add `~/.local/bin` to your PATH if needed:
   ```bash
   echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
   source ~/.bashrc
   ```

3. Keyboard shortcut (automatic setup):
   - The installer will automatically create Shift+Super+T shortcut
   - If automatic setup fails, manually add in Settings > Keyboard

## Requirements

Install these packages if not already present:
```bash
sudo apt install gnome-screenshot tesseract-ocr tesseract-ocr-eng
```

## Usage

- `scrotto` - Select area and extract text
- `scrotto --full` - Capture full screen

## Uninstall

Run the included uninstall script:
```bash
./uninstall.sh
```
EOF

# Create package archive
echo -e "${BLUE}📦 Creating package archive...${NC}"
cd "$DIST_DIR"
tar -czf "$PACKAGE_NAME-$VERSION.tar.gz" "$PACKAGE_NAME-$VERSION"
cd ..

# Create checksum
echo -e "${BLUE}🔐 Generating checksum...${NC}"
cd "$DIST_DIR"
sha256sum "$PACKAGE_NAME-$VERSION.tar.gz" > "$PACKAGE_NAME-$VERSION.tar.gz.sha256"
cd ..

# Show package contents
echo ""
echo -e "${GREEN}✅ Distribution package created successfully!${NC}"
echo ""
echo -e "${CYAN}📋 Package Contents:${NC}"
echo "===================="
find "$PACKAGE_DIR" -type f -exec basename {} \; | sort | sed 's/^/  • /'

echo ""
echo -e "${CYAN}📦 Distribution Files:${NC}"
echo "======================"
ls -lh "$DIST_DIR"/*.tar.gz* | awk '{print "  • " $9 " (" $5 ")"}'

echo ""
echo -e "${CYAN}🚀 Ready for Publishing:${NC}"
echo "========================"
echo "  📁 Package directory: $PACKAGE_DIR"
echo "  📦 Archive: $DIST_DIR/$PACKAGE_NAME-$VERSION.tar.gz"
echo "  🔐 Checksum: $DIST_DIR/$PACKAGE_NAME-$VERSION.tar.gz.sha256"
echo ""
echo -e "${YELLOW}💡 Publishing Instructions:${NC}"
echo "  1. Test the package: cd $PACKAGE_DIR && ./install.sh"
echo "  2. Upload the .tar.gz file and .sha256 checksum"
echo "  3. Include installation instructions from INSTALL.md"
echo ""
echo -e "${GREEN}🎯 Installation for users:${NC}"
echo "  wget [your-download-url]/$PACKAGE_NAME-$VERSION.tar.gz"
echo "  tar -xzf $PACKAGE_NAME-$VERSION.tar.gz"
echo "  cd $PACKAGE_NAME-$VERSION"
echo "  ./install.sh"