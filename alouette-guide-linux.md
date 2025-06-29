# Alouette Linux Guide

## Desktop Application

### Environment Setup
```bash
# Install system dependencies
sudo apt update && sudo apt install -y \
  libwebkit2gtk-4.1-dev libjavascriptcoregtk-4.1-dev libgtk-3-dev \
  libsoup-3.0-dev libssl-dev libayatana-appindicator3-dev librsvg2-dev \
  build-essential clang llvm-dev libclang-dev python3-pip \
  espeak-ng flite openjdk-21-jdk wget unzip curl

# Install Edge TTS (optional)
pip3 install --use-pep517 edge-tts

# Install Node.js and Rust
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source ~/.cargo/env
```

### Build and Run
```bash
# Install dependencies
npm install
npm install -g @tauri-apps/cli

# Development mode
npm run dev

# Production build
npm run build
```

## Android Application

### Android Environment Setup
```bash
# Set environment variables
export ANDROID_HOME="$PWD/android-sdk"
export GRADLE_HOME="$PWD/gradle-8.14.2"
export PATH="$ANDROID_HOME/platform-tools:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/emulator:$GRADLE_HOME/bin:$PATH"

# Add Rust Android targets
rustup target add aarch64-linux-android armv7-linux-androideabi i686-linux-android x86_64-linux-android
```

### Initialize Android Project
```bash
# First time only
npm run tauri android init
```

### Start Android Emulator
```bash
# Create AVD (first time only)
avdmanager create avd -n Alouette_Test -k "system-images;android-34;google_apis_playstore;x86_64" -d "pixel_7"

# Start emulator
$ANDROID_HOME/emulator/emulator -avd Alouette_Test -memory 2048 -cores 2 -gpu swiftshader_indirect -no-boot-anim -no-snapshot-save &

# Wait for device
adb wait-for-device && adb devices
```

### Build and Deploy Android
```bash
# Development mode (auto-install)
npm run tauri android dev

# Manual build
npm run tauri android build --debug

# Manual install
adb install -r src-tauri/gen/android/app/build/outputs/apk/universal/debug/app-universal-debug.apk

# Launch app
adb shell am start -n com.alouette.app/com.alouette.app.MainActivity
```

### View Logs
```bash
adb logcat | grep -E "(alouette|Alouette|RustStdoutStderr)"
```
