#!/bin/bash

# Alouette Android ARM64 Debug Build Script for macOS
# This script builds and deploys the Android app for ARM64 architecture only

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

# Check if Android environment exists
if [ ! -f "$ANDROID_ENV_DIR/android-env.sh" ]; then
    log_error "Android environment script not found at $ANDROID_ENV_DIR/android-env.sh"
    exit 1
fi

log_info "Setting up Android environment..."
cd "$ANDROID_ENV_DIR" && source android-env.sh
cd "$PROJECT_DIR"

log_info "Building Android debug app for ARM64 architecture..."
npx tauri android build --debug --target aarch64

log_info "Looking for ARM64 debug APK..."

# Look for ARM64-specific APK first, then fallback to debug APK
APK_PATH=""
if [ -f "src-tauri/gen/android/app/build/outputs/apk/aarch64/debug/app-aarch64-debug.apk" ]; then
    APK_PATH="src-tauri/gen/android/app/build/outputs/apk/aarch64/debug/app-aarch64-debug.apk"
elif [ -f "src-tauri/gen/android/app/build/outputs/apk/arm64-v8a/debug/app-arm64-v8a-debug.apk" ]; then
    APK_PATH="src-tauri/gen/android/app/build/outputs/apk/arm64-v8a/debug/app-arm64-v8a-debug.apk"
elif [ -f "src-tauri/gen/android/app/build/outputs/apk/debug/app-debug.apk" ]; then
    APK_PATH="src-tauri/gen/android/app/build/outputs/apk/debug/app-debug.apk"
else
    # Search for any debug APK
    APK_PATH=$(find src-tauri/gen/android -name "*debug*.apk" -type f | head -n 1)
fi

if [ -n "$APK_PATH" ] && [ -f "$APK_PATH" ]; then
    log_success "ARM64 debug APK found: $APK_PATH"
    
    # Display APK size
    APK_SIZE=$(du -h "$APK_PATH" | cut -f1)
    log_info "APK size: $APK_SIZE"
    
    # Check if device/emulator is connected
    if ! adb devices | grep -q "device$"; then
        log_warning "No Android device or emulator detected"
        log_info "Please ensure your ARM64 emulator is running"
        exit 1
    fi
    
    log_info "Installing APK to ARM64 device/emulator..."
    if adb install -r "$APK_PATH"; then
        log_success "APK installed successfully!"
        
        log_info "Starting application..."
        adb shell am start -n com.alouette.app/com.alouette.app.MainActivity
        
        log_success "Build and deployment complete!"
        log_info "App should now be running on your Android device/emulator"
        log_info "View logs with: bash scripts/macos/view-logs.sh"
    else
        log_error "Failed to install APK"
        log_info "You may need to check device compatibility or try manual installation"
        exit 1
    fi
else
    log_error "No ARM64 debug APK found in src-tauri/gen/android/"
    log_error "Build may have failed."
    exit 1
fi
