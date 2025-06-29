#!/bin/bash

# Alouette Android Clean Script for macOS
# Clean Android build artifacts and reset development environment

set -e

# Configuration
PROJECT_DIR="/Users/han/coding/alouette-app"

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

cd "$PROJECT_DIR"

log_info "Cleaning Android build artifacts..."

# Clean Tauri Android build
if [ -d "src-tauri/gen/android" ]; then
    log_info "Removing Android build directory..."
    rm -rf src-tauri/gen/android
    log_success "Android build directory cleaned"
else
    log_info "No Android build directory found"
fi

# Clean Rust target directory for Android
if [ -d "src-tauri/target" ]; then
    log_info "Cleaning Rust target directory..."
    cd src-tauri
    cargo clean
    cd ..
    log_success "Rust target directory cleaned"
fi

# Clean Node.js build artifacts
if [ -d "dist" ]; then
    log_info "Removing frontend build directory..."
    rm -rf dist
    log_success "Frontend build directory cleaned"
fi

if [ -d "node_modules" ]; then
    log_warning "Node modules directory found"
    read -p "Do you want to remove node_modules? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm -rf node_modules
        log_success "Node modules removed"
        log_info "Run 'npm install' to reinstall dependencies"
    fi
fi

# Uninstall app from connected devices
if command -v adb &> /dev/null && adb devices | grep -q "device$"; then
    log_info "Uninstalling app from connected devices..."
    adb uninstall com.alouette.app 2>/dev/null && log_success "App uninstalled" || log_info "App was not installed"
fi

log_success "Clean complete!"
log_info "Use 'bash scripts/macos/android-build.sh' to rebuild"
