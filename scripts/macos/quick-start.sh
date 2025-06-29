#!/bin/bash

# Alouette Quick Start Script for macOS
# Sets up environment and builds Android app for ARM64

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
echo "🚀 Alouette Quick Start for macOS"
echo "======================================"

cd "$PROJECT_DIR"

# Set up Android environment
if [ -f "$ANDROID_ENV_DIR/android-env.sh" ]; then
    log_info "Setting up Android environment..."
    source "$ANDROID_ENV_DIR/android-env.sh"
    log_success "Android environment loaded"
else
    log_error "Android environment not found at $ANDROID_ENV_DIR/android-env.sh"
    exit 1
fi

# Quick status check
log_info "Checking environment..."
if [ -z "$ANDROID_HOME" ] || [ -z "$NDK_HOME" ]; then
    log_error "Android SDK or NDK not properly configured"
    log_info "Please ensure both ANDROID_HOME and NDK_HOME are set"
    exit 1
fi

# Check for connected device/emulator
if ! adb devices | grep -q "device$"; then
    log_warning "No Android device or emulator detected"
    log_info "Please start your ARM64 emulator and try again"
    exit 1
fi

log_success "Environment ready - starting ARM64 build..."

# Build and deploy
bash scripts/macos/android-build.sh

log_success "Quick start complete!"
