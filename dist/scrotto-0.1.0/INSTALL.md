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
   - The installer will automatically create Shift+Super+A shortcut
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
