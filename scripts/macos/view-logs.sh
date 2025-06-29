#!/bin/bash

# Alouette Android Logs Viewer for macOS
# View real-time logs from the Android app

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

# Check if device is connected
if ! adb devices | grep -q "device$"; then
    log_error "No Android device or emulator connected"
    exit 1
fi

log_info "Starting Android logs for Alouette app..."
log_info "Press Ctrl+C to stop"
echo ""

# Clear previous logs and start real-time logging
adb logcat -c
adb logcat | grep -E "(alouette|Alouette|TTS|Audio|RustStdoutStderr)" --color=always
