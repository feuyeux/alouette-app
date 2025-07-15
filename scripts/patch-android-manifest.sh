#!/bin/bash

# Script to patch Android Manifest after Tauri generation
# This ensures TTS permissions and ProGuard rules are always included

PROJECT_DIR="/Users/han/coding/alouette-app"
MANIFEST_PATH="$PROJECT_DIR/src-tauri/gen/android/app/src/main/AndroidManifest.xml"
PROGUARD_PATH="$PROJECT_DIR/src-tauri/gen/android/app/proguard-rules.pro"
BUILD_GRADLE_PATH="$PROJECT_DIR/src-tauri/gen/android/app/build.gradle.kts"

# Source templates
SOURCE_MANIFEST="$PROJECT_DIR/src-tauri/android/AndroidManifest.xml"
SOURCE_PROGUARD="$PROJECT_DIR/src-tauri/android/proguard-rules.pro"

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

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

# Check if source templates exist
if [ ! -f "$SOURCE_MANIFEST" ]; then
    log_error "Source AndroidManifest template not found at $SOURCE_MANIFEST"
    exit 1
fi

if [ ! -f "$SOURCE_PROGUARD" ]; then
    log_error "Source ProGuard template not found at $SOURCE_PROGUARD"
    exit 1
fi

# Patch AndroidManifest.xml
if [ -f "$MANIFEST_PATH" ]; then
    log_info "Patching AndroidManifest.xml for TTS permissions..."
    
    # Create backup
    cp "$MANIFEST_PATH" "$MANIFEST_PATH.backup"
    
    # Check if RECORD_AUDIO permission already exists
    if ! grep -q "android.permission.RECORD_AUDIO" "$MANIFEST_PATH"; then
        log_info "Adding TTS permissions to AndroidManifest.xml"
        
        # Add TTS permissions after existing permissions
        sed -i '/android.permission.READ_EXTERNAL_STORAGE/a\    \
    <!-- TTS必需权限 -->\
    <uses-permission android:name="android.permission.RECORD_AUDIO" />\
    <uses-permission android:name="android.permission.MODIFY_AUDIO_SETTINGS" />' "$MANIFEST_PATH"
        
        log_success "TTS permissions added successfully"
    else
        log_success "TTS permissions already present"
    fi
    
    # Ensure TTS queries are present
    if ! grep -q "android.intent.action.TTS_SERVICE" "$MANIFEST_PATH"; then
        log_info "Adding TTS service queries..."
        # Add queries section after permissions
        sed -i '/<uses-permission.*READ_EXTERNAL_STORAGE.*\/>/a\    \
    \
    <!-- Text-to-Speech服务查询权限 -->\
    <queries>\
        <intent>\
            <action android:name="android.intent.action.TTS_SERVICE" />\
        </intent>\
    </queries>' "$MANIFEST_PATH"
        log_success "TTS service queries added"
    fi
else
    log_error "Android Manifest not found at $MANIFEST_PATH"
    log_error "Make sure to run 'tauri android init' first"
    exit 1
fi

# Patch ProGuard rules
if [ -f "$PROGUARD_PATH" ]; then
    log_info "Updating ProGuard rules for TTS compatibility..."
    
    # Create backup
    cp "$PROGUARD_PATH" "$PROGUARD_PATH.backup"
    
    # Copy our comprehensive ProGuard rules
    cp "$SOURCE_PROGUARD" "$PROGUARD_PATH"
    
    log_success "ProGuard rules updated with TTS protections"
else
    log_warning "ProGuard rules file not found at $PROGUARD_PATH"
fi

# Patch build.gradle.kts for HTTP access
if [ -f "$BUILD_GRADLE_PATH" ]; then
    log_info "Ensuring HTTP access in release builds..."
    
    # Create backup
    cp "$BUILD_GRADLE_PATH" "$BUILD_GRADLE_PATH.backup"
    
    # Check if release configuration has usesCleartextTraffic set to true
    if grep -A 10 'getByName("release")' "$BUILD_GRADLE_PATH" | grep -q 'manifestPlaceholders\["usesCleartextTraffic"\] = "true"'; then
        log_success "HTTP access already enabled in release builds"
    else
        log_warning "HTTP access may not be enabled in release builds"
        log_info "Please ensure tauri.conf.json has proper Android configuration"
    fi
else
    log_warning "build.gradle.kts not found at $BUILD_GRADLE_PATH"
fi

log_success "Android configuration patching completed!"
log_info "Modified files:"
echo "  • AndroidManifest.xml - Added TTS permissions and service queries"
echo "  • proguard-rules.pro - Updated with TTS protection rules"
echo "  • Backups created with .backup extension"

echo ""
log_info "Next steps:"
echo "  1. Build your Android app: npm run build:android"
echo "  2. Test TTS functionality in both debug and release builds"
echo "  3. If issues persist, check device TTS engine settings"
