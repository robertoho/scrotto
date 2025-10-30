# Screen Text Grabber - Installation

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
   cp screen_text_grabber ~/.local/bin/
   chmod +x ~/.local/bin/screen_text_grabber
   ```

2. Add `~/.local/bin` to your PATH if needed:
   ```bash
   echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
   source ~/.bashrc
   ```

3. Set up keyboard shortcuts in Ubuntu Settings:
   - Settings > Keyboard > View and Customize Shortcuts
   - Add custom shortcut with command: `screen_text_grabber`

## Requirements

Install these packages if not already present:
```bash
sudo apt install gnome-screenshot tesseract-ocr tesseract-ocr-eng
```

## Usage

- `screen_text_grabber` - Select area and extract text
- `screen_text_grabber --full` - Capture full screen

## Uninstall

Run the included uninstall script:
```bash
./uninstall.sh
```
