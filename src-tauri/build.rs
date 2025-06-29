fn main() {
    // Run pre-build hook for Android consistency
    #[cfg(target_os = "android")]
    {
        use std::process::Command;
        
        let hook_path = "build-pre-hook.sh";
        if std::path::Path::new(hook_path).exists() {
            let output = Command::new("bash")
                .arg(hook_path)
                .output()
                .expect("Failed to execute pre-build hook");
            
            if !output.status.success() {
                panic!("Pre-build hook failed: {}", String::from_utf8_lossy(&output.stderr));
            }
            
            println!("cargo:warning=Pre-build hook executed successfully");
        }
    }
    
    // Skip Windows resource compilation to avoid icon issues during development
    #[cfg(not(windows))]
    tauri_build::build();
    
    #[cfg(windows)]
    {
        // Use manual tauri build configuration for Windows
        println!("cargo:rustc-check-cfg=cfg(desktop)");
        println!("cargo:rustc-cfg=desktop");
        println!("cargo:rustc-check-cfg=cfg(mobile)");
        println!("cargo:rustc-check-cfg=cfg(dev)");
        println!("cargo:rustc-cfg=dev");
        println!("cargo:warning=Windows resource compilation disabled for icon compatibility");
    }
}
