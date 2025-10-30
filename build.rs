fn main() {
    // Only compile resources on Windows
    if cfg!(target_os = "windows") {
        let mut res = winres::WindowsResource::new();
        res.set_icon("scrotto-256.ico");
        res.set_language(0x0409); // English (US)
        if let Err(e) = res.compile() {
            eprintln!("Error compiling Windows resources: {}", e);
        }
    }
}