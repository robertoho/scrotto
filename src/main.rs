use std::env;
use std::fs;
use std::path::{Path, PathBuf};
use std::process::{Command, Stdio};

use anyhow::{anyhow, Result};
use clipboard::{ClipboardContext, ClipboardProvider};
use notify_rust::Notification;

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
enum Backend {
    Auto,
    Portal,
}

impl Backend {
    fn from_str(value: &str) -> Option<Self> {
        match value.to_ascii_lowercase().as_str() {
            "auto" => Some(Self::Auto),
            "portal" => Some(Self::Portal),
            _ => None,
        }
    }
}

fn default_backend(session_type: &str) -> Backend {
    if session_type.eq_ignore_ascii_case("wayland") {
        if let Ok(current_desktop) = env::var("XDG_CURRENT_DESKTOP") {
            if current_desktop
                .split(':')
                .any(|part| part.trim().eq_ignore_ascii_case("gnome"))
            {
                return Backend::Portal;
            }
        }
    }

    Backend::Auto
}

fn show_notification(title: &str, message: &str) -> bool {
    // Try notify-rust first
    match Notification::new()
        .summary(title)
        .body(message)
        .timeout(notify_rust::Timeout::Milliseconds(5000))
        .show() {
        Ok(_) => return true,
        Err(e) => {
            eprintln!("⚠️  notify-rust failed: {}", e);
        }
    }
    
    // Fallback to notify-send command
    if command_exists("notify-send") {
        let status = Command::new("notify-send")
            .arg(title)
            .arg(message)
            .status();
        
        if let Ok(status) = status {
            if status.success() {
                return true;
            }
        }
    }
    
    eprintln!("⚠️  All notification methods failed");
    false
}

fn copy_to_clipboard(text: &str) -> bool {
    // Try wl-copy (Wayland clipboard utility)
    if command_exists("wl-copy") {
        let status = Command::new("wl-copy")
            .arg(text)
            .status();
        
        if let Ok(status) = status {
            if status.success() {
                // Verify it worked by reading it back
                if let Ok(output) = Command::new("wl-paste").output() {
                    let pasted_text = String::from_utf8_lossy(&output.stdout);
                    if pasted_text.trim() == text.trim() {
                        return true;
                    }
                }
            }
        }
    }
    
    // Try Rust clipboard library (supports Wayland)
    if let Ok(ctx) = ClipboardProvider::new() {
        let mut ctx: ClipboardContext = ctx;
        if ctx.set_contents(text.to_string()).is_ok() {
            // Try to verify it worked
            if let Ok(contents) = ctx.get_contents() {
                if contents.trim() == text.trim() {
                    return true;
                }
            }
        }
    }
    
    eprintln!("❌ Failed to copy to clipboard. Make sure wl-clipboard is installed:");
    eprintln!("   sudo apt install wl-clipboard");
    false
}

fn main() {
    // Ensure we're running on Wayland
    let session_type = env::var("XDG_SESSION_TYPE").unwrap_or_else(|_| String::from("unknown"));
    if !session_type.eq_ignore_ascii_case("wayland") {
        eprintln!("❌ Scrotto requires a Wayland session");
        eprintln!("   Current session type: {}", session_type);
        eprintln!("   Please run this application in a Wayland environment");
        std::process::exit(1);
    }

    let args: Vec<String> = env::args().collect();
    let mut fullscreen = false;
    let mut backend = default_backend(&session_type);

    let mut i = 1;
    while i < args.len() {
        match args[i].as_str() {
            "--full" | "-f" => {
                fullscreen = true;
            }
            "--backend" => {
                if i + 1 >= args.len() {
                    eprintln!("❌ Missing value for --backend (expected 'portal' or 'auto')");
                    return;
                }
                let value = &args[i + 1];
                match Backend::from_str(value) {
                    Some(parsed) => backend = parsed,
                    None => {
                        eprintln!("❌ Unknown backend '{}'. Use 'portal' or 'auto'.", value);
                        return;
                    }
                }
                i += 1;
            }
            "--help" | "-h" => {
                println!("Usage: scrotto [--full|-f] [--backend auto|portal]");
                println!("When running on GNOME Wayland the portal backend is chosen automatically.");
                return;
            }
            other => {
                eprintln!("⚠️  Ignoring unknown argument: {}", other);
            }
        }
        i += 1;
    }

    match backend {
        Backend::Portal => println!("🔌 Using GNOME portal backend"),
        Backend::Auto => {}
    }

    if fullscreen {
        println!("📸 Scrotto - Capturing full screen");
    } else {
        println!("📸 Scrotto - Select an area to capture text");
        println!("💡 Use --full or -f flag to capture entire screen");
    }

    let tmpfile = PathBuf::from("/tmp/screen_grab.png");
    let screenshot_path = match backend {
        Backend::Portal => match capture_portal(fullscreen) {
            Some(path) => path,
            None => {
                eprintln!("❌ Screenshot failed or cancelled");
                return;
            }
        },
        Backend::Auto => {
            let target = tmpfile.clone();
            let success = if fullscreen {
                capture_wayland_fullscreen(&target)
            } else {
                capture_wayland(&target)
            };

            if success {
                target
            } else {
                eprintln!("❌ Screenshot failed or cancelled");
                return;
            }
        }
    };

    // Run OCR via tesseract
    let ocr_output = Command::new("tesseract")
        .arg(&screenshot_path)
        .arg("stdout")
        .arg("-l")
        .arg("eng")
        .output()
        .expect("Failed to run tesseract. Make sure tesseract-ocr is installed: sudo apt install tesseract-ocr");

    let text = String::from_utf8_lossy(&ocr_output.stdout).trim().to_string();

    if text.is_empty() {
        println!("❌ No text detected in the selected area.");

        show_notification("Scrotto", "❌ No text found in selected area\n\nTip: Make sure the area contains clear, readable text");

        let _ = fs::remove_file(&screenshot_path);
        return;
    }

    // Copy to clipboard with robust fallbacks
    let clipboard_success = copy_to_clipboard(&text);

    // Prepare notification text (limit length for better display)
    let preview_text = if text.chars().count() > 100 {
        let truncated: String = text.chars().take(100).collect();
        format!("{}...", truncated)
    } else {
        text.clone()
    };

    if clipboard_success {
        // Show desktop notification with extracted text
        show_notification("Scrotto", &format!("✅ Text copied to clipboard:\n\n{}", preview_text));
        println!("✅ Text copied to clipboard:\n{}", text);
    } else {
        // Show notification even if clipboard failed
        show_notification("Scrotto", &format!("❌ Clipboard failed, but text extracted:\n\n{}", preview_text));
        println!("❌ Failed to copy to clipboard, but text extracted:\n{}", text);
        println!("💡 You can manually copy this text from the terminal");
    }

    let _ = fs::remove_file(&screenshot_path);
}

fn capture_wayland_fullscreen(tmpfile: &Path) -> bool {
    let _ = fs::remove_file(tmpfile);

    // Try GNOME screenshot first (most common on Ubuntu Wayland)
    if command_exists("gnome-screenshot") {
        println!("📷 Capturing full screen with gnome-screenshot...");
        let status = Command::new("gnome-screenshot")
            .arg("-f")
            .arg(tmpfile)
            .stderr(Stdio::piped())
            .status();  
        
        if let Ok(status) = status {
            if status.success() && tmpfile.exists() {
                println!("✅ Full screen captured successfully");
                return true;
            }
        }
    }   

    // Try grim for wlroots-based compositors
    if command_exists("grim") {
        println!("📷 Capturing full screen with grim...");
        let status = Command::new("grim")
            .arg(tmpfile)
            .stderr(Stdio::piped())
            .status();

        if let Ok(status) = status {
            if status.success() && tmpfile.exists() {
                println!("✅ Full screen captured successfully");
                return true;
            }
        }
    }

    eprintln!("❌ Failed to capture screenshot. No compatible Wayland screenshot tool found.");
    eprintln!("💡 For GNOME Wayland: sudo apt install gnome-screenshot");
    eprintln!("💡 For other compositors: sudo apt install grim");
    false
}

fn capture_wayland(tmpfile: &Path) -> bool {
    let _ = fs::remove_file(tmpfile);

    // Try GNOME screenshot with area selection first
    if command_exists("gnome-screenshot") {
        println!("🖱️  Click and drag to select area (GNOME Wayland mode)");
        println!("💡 Press Escape to cancel selection");
        
        let status = Command::new("gnome-screenshot")
            .arg("-a")
            .arg("-f")
            .arg(tmpfile)
            .stderr(Stdio::piped())
            .status();
        
        if let Ok(status) = status {
            if status.success() && tmpfile.exists() {
                println!("✅ Screenshot captured successfully");
                return true;
            } else {
                println!("❌ Selection cancelled or failed");
            }
        }
    }

    // Try grim + slurp for wlroots-based compositors
    if command_exists("slurp") && command_exists("grim") {
        println!("🖱️  Click and drag to select area (wlroots Wayland mode)");
        println!("💡 Press Escape to cancel selection");
        
        // Select area with slurp
        let area_output = Command::new("slurp")
            .stdout(Stdio::piped())
            .stderr(Stdio::piped())
            .output();
        
        let area_output = match area_output {
            Ok(output) => {
                if !output.status.success() {
                    let stderr = String::from_utf8_lossy(&output.stderr);
                    if stderr.contains("cancelled") {
                        println!("❌ Selection cancelled by user");
                    } else {
                        eprintln!("❌ Failed to run slurp: {}", stderr.trim());
                    }
                    return false;
                }
                output
            },
            Err(e) => {
                eprintln!("❌ Failed to run slurp: {}", e);
                return false;
            }
        };
        
        let area = String::from_utf8_lossy(&area_output.stdout).trim().to_string();

        if area.is_empty() {
            println!("❌ No area selected");
            return false;
        }

        println!("📷 Capturing selected area: {}", area);

        // Capture the selected area with grim
        let status = Command::new("grim")
            .arg("-g")
            .arg(&area)
            .arg(tmpfile)
            .stderr(Stdio::piped())
            .status();

        if let Ok(status) = status {
            if status.success() && tmpfile.exists() {
                println!("✅ Screenshot captured successfully");
                return true;
            } else {
                eprintln!("❌ Failed to capture screenshot with grim");
            }
        }
    }

    eprintln!("❌ No compatible Wayland screenshot tools found!");
    eprintln!("💡 For GNOME Wayland: sudo apt install gnome-screenshot");
    eprintln!("💡 For wlroots compositors: sudo apt install slurp grim");
    false
}

fn capture_portal(fullscreen: bool) -> Option<PathBuf> {
    use tokio::runtime::Runtime;

    let interactive = !fullscreen;

    if interactive {
        println!("🖱️  Click and drag to select area (desktop portal mode)");
        println!("💡 Press Escape to cancel selection");
    } else {
        println!("📷 Capturing full screen via desktop portal...");
    }

    let runtime = match Runtime::new() {
        Ok(rt) => rt,
        Err(err) => {
            eprintln!("❌ Failed to initialise async runtime: {}", err);
            return None;
        }
    };

    match runtime.block_on(capture_via_portal(interactive)) {
        Ok(Some(path)) => {
            println!("✅ Screenshot captured successfully");
            Some(path)
        }
        Ok(None) => {
            println!("❌ Selection cancelled by user");
            None
        }
        Err(err) => {
            eprintln!("❌ Portal screenshot failed: {}", err);
            None
        }
    }
}

async fn capture_via_portal(interactive: bool) -> Result<Option<PathBuf>> {
    use ashpd::desktop::screenshot::Screenshot;
    use ashpd::desktop::ResponseError;
    use ashpd::{PortalError, WindowIdentifier};

    fn is_cancelled(err: &ashpd::Error) -> bool {
        matches!(
            err,
            ashpd::Error::Response(ResponseError::Cancelled)
                | ashpd::Error::Portal(PortalError::Cancelled(_))
        )
    }

    let request = Screenshot::request()
        .identifier(WindowIdentifier::None)
        .interactive(interactive)
        .send()
        .await;

    let request = match request {
        Ok(request) => request,
        Err(err) if is_cancelled(&err) => return Ok(None),
        Err(err) => return Err(err.into()),
    };

    let response = match request.response() {
        Ok(response) => response,
        Err(err) if is_cancelled(&err) => return Ok(None),
        Err(err) => return Err(err.into()),
    };

    let path = response
        .uri()
        .to_file_path()
        .map_err(|_| anyhow!("bad file URI"))?;

    Ok(Some(path))
}

fn command_exists(command: &str) -> bool {
    Command::new("which")
        .arg(command)
        .stdout(Stdio::null())
        .stderr(Stdio::null())
        .status()
        .map(|status| status.success())
        .unwrap_or(false)
}
