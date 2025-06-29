# Alouette Windows Guide

## Desktop Application

### Environment Setup
```powershell
# Download and install Visual Studio Build Tools
# https://visualstudio.microsoft.com/visual-cpp-build-tools/
# Select "C++ build tools" workload

# Download and install Node.js LTS
# https://nodejs.org/

# Download and install Rust
# https://rustup.rs/

# Install Edge TTS (high-quality neural voices)
pip install --use-pep517 edge-tts
```

### Build and Run
```powershell
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
```powershell
# Download Android SDK command line tools
# https://developer.android.com/studio#command-tools

# Download Android NDK
# https://developer.android.com/ndk/downloads

# Set environment variables (adjust paths)
$env:ANDROID_HOME = "C:\android-sdk"
$env:NDK_HOME = "C:\android-ndk"
$env:PATH += ";$env:ANDROID_HOME\platform-tools;$env:ANDROID_HOME\cmdline-tools\latest\bin;$env:ANDROID_HOME\emulator"

# Add Rust Android targets
rustup target add aarch64-linux-android armv7-linux-androideabi i686-linux-android x86_64-linux-android
```

### Initialize Android Project
```powershell
# First time only
npm run tauri android init
```

### Start Android Emulator
```powershell
# Install SDK components (first time only)
sdkmanager --licenses
sdkmanager "platforms;android-34" "build-tools;34.0.0" "emulator" "system-images;android-34;google_apis_playstore;x86_64"

# Create AVD (first time only)
avdmanager create avd -n "Alouette_Test" -k "system-images;android-34;google_apis_playstore;x86_64" -d "pixel_7"

# Start emulator
emulator -avd Alouette_Test -memory 4096 -cores 2 -gpu auto -no-snapshot-save

# Wait for device (in another terminal)
adb wait-for-device
adb devices
```

### Build and Deploy Android
```powershell
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
```powershell
adb logcat | findstr "alouette Alouette RustStdoutStderr"
```
