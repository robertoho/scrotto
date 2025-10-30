use std::env;
use std::process::{Command, Stdio};
use std::fs;
use clipboard::{ClipboardContext, ClipboardProvider};
use notify_rust::Notification;

fn copy_to_clipboard(text: &str) -> bool {
    // Try Rust clipboard library first
    if let Ok(mut ctx) = ClipboardProvider::new() {
        let mut ctx: ClipboardContext = ctx;
        if ctx.set_contents(text.to_string()).is_ok() {
            return true;
        }
    }
    
    // Fallback to native Wayland clipboard (wl-copy)
    if command_exists("wl-copy") {
        let status = Command::new("wl-copy")
            .arg(text)
            .status();
        
        if let Ok(status) = status {
            if status.success() {
                return true;
            }
        }
    }
    
    // Fallback to X11 clipboard (xclip)
    if command_exists("xclip") {
        let mut cmd = Command::new("xclip")
            .args(["-selection", "clipboard"])
            .stdin(Stdio::piped())
            .spawn();
        
        if let Ok(mut child) = cmd {
            if let Some(stdin) = child.stdin.as_mut() {
                use std::io::Write;
                if stdin.write_all(text.as_bytes()).is_ok() {
                    drop(stdin);
                    if let Ok(status) = child.wait() {
                        if status.success() {
                            return true;
                        }
                    }
                }
            }
        }
    }
    
    // Fallback to xsel
    if command_exists("xsel") {
        let mut cmd = Command::new("xsel")
            .args(["--clipboard", "--input"])
            .stdin(Stdio::piped())
            .spawn();
        
        if let Ok(mut child) = cmd {
            if let Some(stdin) = child.stdin.as_mut() {
                use std::io::Write;
                if stdin.write_all(text.as_bytes()).is_ok() {
                    drop(stdin);
                    if let Ok(status) = child.wait() {
                        if status.success() {
                            return true;
                        }
                    }
                }
            }
        }
    }
    
    false
}

fn main() {
    let args: Vec<String> = env::args().collect();
    let session_type = env::var("XDG_SESSION_TYPE").unwrap_or_else(|_| "x11".into());
    let tmpfile = "/tmp/screen_grab.png";

    // Check for fullscreen flag
    let fullscreen = args.len() > 1 && (args[1] == "--full" || args[1] == "-f");

    if fullscreen {
        println!("📸 Screen Text Grabber - Capturing full screen");
    } else {
        println!("📸 Screen Text Grabber - Select an area to capture text");
        println!("💡 Use --full or -f flag to capture entire screen");
    }

    let success = if session_type == "wayland" {
        if fullscreen {
            capture_wayland_fullscreen(tmpfile)
        } else {
            capture_wayland(tmpfile)
        }
    } else {
        capture_x11(tmpfile)
    };

    if !success {
        eprintln!("❌ Screenshot failed or cancelled");
        return;
    }

    // Run OCR via tesseract
    let ocr_output = Command::new("tesseract")
        .args([tmpfile, "stdout", "-l", "eng"])
        .output()
        .expect("Failed to run tesseract. Make sure tesseract-ocr is installed: sudo apt install tesseract-ocr");

    let text = String::from_utf8_lossy(&ocr_output.stdout).trim().to_string();

    if text.is_empty() {
        println!("❌ No text detected in the selected area.");
        
        Notification::new()
            .summary("Screen Text Grabber")
            .body("❌ No text found in selected area\n\nTip: Make sure the area contains clear, readable text")
            .timeout(notify_rust::Timeout::Milliseconds(4000))
            .show()
            .unwrap();
        
        let _ = fs::remove_file(tmpfile);
        return;
    }

    // Copy to clipboard with robust fallbacks
    let clipboard_success = copy_to_clipboard(&text);
    
    // Prepare notification text (limit length for better display)
    let preview_text = if text.len() > 100 {
        format!("{}...", &text[..100])
    } else {
        text.clone()
    };

    if clipboard_success {
        // Show desktop notification with extracted text
        Notification::new()
            .summary("Screen Text Grabber")
            .body(&format!("✅ Text copied to clipboard:\n\n{}", preview_text))
            .timeout(notify_rust::Timeout::Milliseconds(5000))
            .show()
            .unwrap();

        println!("✅ Text copied to clipboard:\n{}", text);
    } else {
        // Show notification even if clipboard failed
        Notification::new()
            .summary("Screen Text Grabber")  
            .body(&format!("❌ Clipboard failed, but text extracted:\n\n{}", preview_text))
            .timeout(notify_rust::Timeout::Milliseconds(5000))
            .show()
            .unwrap();

        println!("❌ Failed to copy to clipboard, but text extracted:\n{}", text);
        println!("💡 You can manually copy this text from the terminal");
    }


    let _ = fs::remove_file(tmpfile);
}

fn capture_wayland_fullscreen(tmpfile: &str) -> bool {
    // Try GNOME screenshot first (most common on Ubuntu Wayland)
    if command_exists("gnome-screenshot") {
        println!("📷 Capturing full screen with gnome-screenshot...");
        let status = Command::new("gnome-screenshot")
            .args(["-f", tmpfile])
            .stderr(Stdio::piped())
            .status();  
        
        if let Ok(status) = status {
            if status.success() && std::path::Path::new(tmpfile).exists() {
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
            if status.success() && std::path::Path::new(tmpfile).exists() {
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

fn capture_wayland(tmpfile: &str) -> bool {
    // Try GNOME screenshot with area selection first
    if command_exists("gnome-screenshot") {
        println!("🖱️  Click and drag to select area (GNOME Wayland mode)");
        println!("💡 Press Escape to cancel selection");
        
        let status = Command::new("gnome-screenshot")
            .args(["-a", "-f", tmpfile])
            .stderr(Stdio::piped())
            .status();
        
        if let Ok(status) = status {
            if status.success() && std::path::Path::new(tmpfile).exists() {
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
            .args(["-g", &area, tmpfile])
            .stderr(Stdio::piped())
            .status();

        if let Ok(status) = status {
            if status.success() && std::path::Path::new(tmpfile).exists() {
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

fn capture_x11(tmpfile: &str) -> bool {
    // Try different X11 screenshot tools in order of preference
    
    // First try gnome-screenshot (most common on Ubuntu)
    if command_exists("gnome-screenshot") {
        println!("🖱️  Select area with your mouse (press and drag)");
        let status = Command::new("gnome-screenshot")
            .args(["-a", "-f", tmpfile])
            .status();
        
        if let Ok(status) = status {
            if status.success() && std::path::Path::new(tmpfile).exists() {
                return true;
            }
        }
    }
    
    // Try flameshot (provides overlay)
    if command_exists("flameshot") {
        println!("🖱️  Use Flameshot overlay to select area and save");
        let status = Command::new("flameshot")
            .args(["gui", "-p", tmpfile])
            .status();
        
        if let Ok(status) = status {
            if status.success() && std::path::Path::new(tmpfile).exists() {
                return true;
            }
        }
    }
    
    // Try maim with slop for area selection
    if command_exists("maim") && command_exists("slop") {
        println!("🖱️  Select area with your mouse (drag to select)");
        
        let slop_output = Command::new("slop")
            .args(["-f", "%x,%y,%w,%h"])
            .stdout(Stdio::piped())
            .stderr(Stdio::null())
            .output();
        
        if let Ok(slop_result) = slop_output {
            let geometry = String::from_utf8_lossy(&slop_result.stdout).trim().to_string();
            
            if !geometry.is_empty() {
                let coords: Vec<&str> = geometry.split(',').collect();
                if coords.len() == 4 {
                    let geometry_arg = format!("{}x{}+{}+{}", coords[2], coords[3], coords[0], coords[1]);
                    
                    let status = Command::new("maim")
                        .args(["-g", &geometry_arg, tmpfile])
                        .status();
                    
                    if let Ok(status) = status {
                        return status.success() && std::path::Path::new(tmpfile).exists();
                    }
                }
            }
        }
    }
    
    // Fallback to maim with interactive selection
    if command_exists("maim") {
        println!("🖱️  Click and drag to select area");
        let status = Command::new("maim")
            .args(["-s", tmpfile])
            .status();
        
        if let Ok(status) = status {
            return status.success() && std::path::Path::new(tmpfile).exists();
        }
    }
    
    // Final fallback to scrot
    if command_exists("scrot") {
        println!("🖱️  Click and drag to select area");
        let status = Command::new("scrot")
            .args(["-s", tmpfile])
            .status();
        
        if let Ok(status) = status {
            return status.success() && std::path::Path::new(tmpfile).exists();
        }
    }
    
    eprintln!("❌ No suitable screenshot tool found!");
    eprintln!("Install one of these tools:");
    eprintln!("  sudo apt install gnome-screenshot  # (recommended for Ubuntu)");
    eprintln!("  sudo apt install flameshot         # (best overlay experience)");
    eprintln!("  sudo apt install maim slop         # (lightweight option)");
    eprintln!("  sudo apt install scrot             # (fallback option)");
    
    false
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
