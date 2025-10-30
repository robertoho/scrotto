# Screen Text Grabber

A fast and efficient screen text grabber for Ubuntu Wayland that captures selected areas and extracts text using OCR.

## ✨ Features

- **Area Selection**: Interactive overlay to select specific screen areas
- **Full Screen Capture**: Capture entire screen with `--full` flag
- **Wayland Native**: Optimized for Ubuntu Wayland using gnome-screenshot
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
screen_text_grabber           # Select area to capture
screen_text_grabber --full    # Capture full screen

# Or use keyboard shortcuts (after setup):
# Shift+Super+T        → Area selection
# Shift+Super+Alt+T    → Full screen
```

## 🔧 Requirements

The application automatically detects and works with:

- **Ubuntu Wayland** (primary target)
- **gnome-screenshot** (for area selection overlay)
- **tesseract-ocr** (for text extraction)

## 📖 Usage Examples

### Area Selection Mode (Default)
```bash
./target/release/screen_text_grabber
```
- Shows an overlay with crosshair cursor
- Click and drag to select area
- Press Escape to cancel
- Text automatically copied to clipboard

### Full Screen Mode
```bash
./target/release/screen_text_grabber --full
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
   - **Name**: Screen Text Grabber - Area
   - **Command**: `~/.local/bin/screen_text_grabber`
   - **Shortcut**: `Shift+Super+T`
   
4. Add second shortcut:
   - **Name**: Screen Text Grabber - Full Screen  
   - **Command**: `~/.local/bin/screen_text_grabber --full`
   - **Shortcut**: `Shift+Super+Alt+T`

## 🛠️ Technical Details

### Wayland Compatibility
- Uses `gnome-screenshot` for GNOME Wayland (Ubuntu default)
- Fallback to `grim + slurp` for wlroots-based compositors
- Automatic session detection and tool selection

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

### No overlay appears
- Ensure `gnome-screenshot` is installed: `sudo apt install gnome-screenshot`
- Check Wayland session: `echo $XDG_SESSION_TYPE`

### OCR not working
- Install tesseract: `sudo apt install tesseract-ocr tesseract-ocr-eng`
- For other languages: `sudo apt install tesseract-ocr-[language]`

### Permission issues
- Make sure binary is executable: `chmod +x screen_text_grabber`
- Check clipboard permissions in Wayland

## 📝 Build from Source

```bash
# Clone and build
git clone <repository>
cd screen_text_grabber
cargo build --release

# The binary will be at: target/release/screen_text_grabber
```

## 🎯 Perfect for:

- **Developers**: Capture terminal output, error messages, code snippets
- **Students**: Extract text from presentations, PDFs, images
- **Researchers**: Digitize printed text, screenshots
- **General Users**: Quick text extraction from any screen content

The application provides a seamless workflow: select area → automatic OCR → text in clipboard → paste anywhere!