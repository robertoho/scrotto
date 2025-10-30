# Scrotto

A fast and efficient screen text grabber for **Wayland** that captures selected areas and extracts text using OCR.

## ✨ Features

- **Wayland-Only**: Designed specifically for Wayland display server
- **Area Selection**: Interactive overlay to select specific screen areas
- **Full Screen Capture**: Capture entire screen with `--full` flag
- **Fast OCR**: Uses Tesseract for accurate text recognition
- **Clipboard Integration**: Automatically copies extracted text to clipboard
- **Desktop Notifications**: Shows success/failure notifications
- **Multiple Languages**: Supports OCR in different languages

## 🚀 Quick Start

### Option 1: Full Setup with Keyboard Shortcuts
```bash
# Automatic setup (recommended)
./universal_setup.sh
```

### Option 2: Manual Installation
```bash
# Build and install manually
./install.sh

# Set up shortcuts
./manual_setup.sh  # Shows instructions for your desktop
```

### Usage
```bash
scrotto           # Select area to capture
scrotto --full    # Capture full screen

# Or use keyboard shortcuts (after setup):
# Shift+Super+T        → Area selection
# Shift+Super+Alt+T    → Full screen
```

## 🔧 Requirements

**This application requires a Wayland session.** It will not work on X11.

The application automatically detects and works with:

- **Wayland Display Server** (required)
- **GNOME Screenshot** or **grim + slurp** (for capturing)
- **wl-clipboard** (for clipboard support)
- **tesseract-ocr** (for text extraction)

### Installation
```bash
# For GNOME/Ubuntu Wayland
sudo apt install gnome-screenshot wl-clipboard tesseract-ocr

# For wlroots-based compositors (Sway, Hyprland, etc.)
sudo apt install grim slurp wl-clipboard tesseract-ocr
```

## 📖 Usage Examples

### Area Selection Mode (Default)
```bash
./target/release/scrotto
```
- Shows an overlay with crosshair cursor
- Click and drag to select area
- Press Escape to cancel
- Text automatically copied to clipboard

### Full Screen Mode
```bash
./target/release/scrotto --full
```
- Captures entire screen
- Extracts all visible text
- Useful for capturing terminal output, documents, etc.

## ⌨️ Keyboard Shortcut Setup

### 🚀 Automatic Setup (Recommended)
```bash
# Universal setup - works on most Ubuntu variants
./universal_setup.sh

# GNOME-specific setup (Ubuntu Desktop)
./setup_shortcuts_simple.sh
```

### 🔧 Manual Setup
```bash
# Show step-by-step instructions for your desktop
./manual_setup.sh
```

### 📋 Manual Steps (GNOME/Ubuntu Desktop)
1. Open **Settings** → **Keyboard** → **View and Customize Shortcuts**
2. Scroll to **Custom Shortcuts** → Click **+**
3. Add shortcuts:
   - **Name**: Scrotto - Area
   - **Command**: `~/.local/bin/scrotto`
   - **Shortcut**: `Shift+Super+T`
   
4. Add second shortcut:
   - **Name**: Scrotto - Full Screen  
   - **Command**: `~/.local/bin/scrotto --full`
   - **Shortcut**: `Shift+Super+Alt+T`

## 🛠️ Technical Details

### Wayland Compatibility
- **GNOME**: Uses `gnome-screenshot` for area selection
- **wlroots compositors** (Sway, Hyprland, etc.): Uses `grim + slurp`
- Automatic compositor detection and tool selection
- Session validation ensures Wayland-only operation

### OCR Configuration
- English language by default (`-l eng`)
- High accuracy with Tesseract 5.x
- Automatic image preprocessing for better text recognition

### Dependencies
```toml
[dependencies]
clipboard = "0.5"      # Clipboard integration
notify-rust = "4"      # Desktop notifications
screenshots = "0.3"    # Cross-platform screenshot support
```

## 🔍 Troubleshooting

### App refuses to start
- Ensure you're running Wayland: `echo $XDG_SESSION_TYPE` should return `wayland`
- If running X11, switch to a Wayland session

### No overlay appears
- **GNOME**: Install `gnome-screenshot`: `sudo apt install gnome-screenshot`
- **Other compositors**: Install `grim` and `slurp`: `sudo apt install grim slurp`

### OCR not working
- Install tesseract: `sudo apt install tesseract-ocr tesseract-ocr-eng`
- For other languages: `sudo apt install tesseract-ocr-[language]`

### Clipboard not working
- Install wl-clipboard: `sudo apt install wl-clipboard`
- Verify wl-copy is available: `which wl-copy`

## 📝 Build from Source

```bash
# Clone and build
git clone <repository>
cd scrotto
cargo build --release

# The binary will be at: target/release/scrotto
```

## 🎯 Perfect for:

- **Developers**: Capture terminal output, error messages, code snippets
- **Students**: Extract text from presentations, PDFs, images
- **Researchers**: Digitize printed text, screenshots
- **General Users**: Quick text extraction from any screen content

The application provides a seamless workflow: select area → automatic OCR → text in clipboard → paste anywhere!# scrotto
