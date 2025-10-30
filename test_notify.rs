fn main() { notify_rust::Notification::new().summary("Test").body("Testing notifications").show().unwrap(); }
