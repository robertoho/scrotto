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

# Note about keyboard shortcuts
print_info "Manual cleanup needed:"
echo "  • Remove custom keyboard shortcuts from Settings > Keyboard"
echo "  • Custom shortcuts pointing to scrotto"

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

3. Set up keyboard shortcuts in Ubuntu Settings:
   - Settings > Keyboard > View and Customize Shortcuts
   - Add custom shortcut with command: `scrotto`

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