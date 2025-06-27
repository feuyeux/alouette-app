fn main() {
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
