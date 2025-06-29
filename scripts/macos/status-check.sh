#!/bin/bash

# Alouette Status Check Script for macOS
# Comprehensive status check for Android development environment and project

set -e

# Configuration
PROJECT_DIR="/Users/han/coding/alouette-app"
ANDROID_ENV_DIR="/Users/han/zoo"

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

echo "======================================"
echo "🔍 Alouette Project Status Check (macOS)"
echo "======================================"

# 1. Project Structure Check
log_info "Checking project structure..."
if [ -f "$PROJECT_DIR/package.json" ] && [ -f "$PROJECT_DIR/src-tauri/Cargo.toml" ]; then
    log_success "Project structure is valid"
else
    log_error "Project structure is incomplete"
fi

# 2. Android Environment Check
log_info "Checking Android environment..."
if [ -f "$ANDROID_ENV_DIR/android-env.sh" ]; then
    log_success "Android environment script found"
    source "$ANDROID_ENV_DIR/android-env.sh"
    
    if [ -n "$ANDROID_HOME" ] && [ -d "$ANDROID_HOME" ]; then
        log_success "Android SDK found at: $ANDROID_HOME"
    else
        log_error "Android SDK not found"
    fi
    
    if [ -n "$NDK_HOME" ] && [ -d "$NDK_HOME" ]; then
        log_success "Android NDK found at: $NDK_HOME"
    else
        log_error "Android NDK not found"
    fi
else
    log_error "Android environment script not found at $ANDROID_ENV_DIR/android-env.sh"
fi

# 3. Device/Emulator Check
log_info "Checking connected devices..."
if command -v adb &> /dev/null; then
    DEVICES=$(adb devices | grep -E "device$|emulator" | wc -l)
    if [ "$DEVICES" -gt 0 ]; then
        log_success "$DEVICES Android device(s)/emulator(s) connected"
        adb devices
        
        # Check emulator architecture
        if adb devices | grep -q "emulator"; then
            ARCH=$(adb shell getprop ro.product.cpu.abi 2>/dev/null || echo "unknown")
            log_info "Emulator architecture: $ARCH"
        fi
    else
        log_warning "No Android devices or emulators connected"
    fi
else
    log_error "ADB not found in PATH"
fi

# 4. Dependencies Check
log_info "Checking Node.js dependencies..."
cd "$PROJECT_DIR"
if [ -f "package.json" ]; then
    if npm list --depth=0 | grep -q "tauri"; then
        log_success "Tauri CLI is installed"
    else
        log_warning "Tauri CLI may not be installed"
    fi
else
    log_error "package.json not found"
fi

# 5. Rust Dependencies Check
log_info "Checking Rust dependencies..."
if command -v rustc &> /dev/null; then
    RUST_VERSION=$(rustc --version)
    log_success "Rust installed: $RUST_VERSION"
    
    # Check Android targets
    if rustup target list --installed | grep -q "aarch64-linux-android"; then
        log_success "ARM64 Android target installed"
    else
        log_warning "ARM64 Android target not installed"
        log_info "Install with: rustup target add aarch64-linux-android"
    fi
else
    log_error "Rust not found"
fi

# 6. Recent Build Check
log_info "Checking recent builds..."
if [ -d "$PROJECT_DIR/src-tauri/gen/android" ]; then
    APK_COUNT=$(find "$PROJECT_DIR/src-tauri/gen/android" -name "*.apk" -type f | wc -l)
    if [ "$APK_COUNT" -gt 0 ]; then
        log_success "$APK_COUNT APK file(s) found"
        find "$PROJECT_DIR/src-tauri/gen/android" -name "*.apk" -type f -exec ls -lh {} \;
    else
        log_warning "No APK files found"
    fi
else
    log_warning "No Android build directory found"
fi

# 7. TTS Dependencies Check
log_info "Checking TTS dependencies..."
cd "$PROJECT_DIR/src-tauri"
if grep -q "rodio" Cargo.toml; then
    log_success "Rodio audio library configured"
else
    log_warning "Rodio audio library not found in Cargo.toml"
fi

echo ""
echo "======================================"
echo "Status check complete!"
echo "Use 'bash scripts/macos/android-build.sh' to build for ARM64"
echo "======================================"
