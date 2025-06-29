# Alouette macOS Guide

## Quick Android Development (ARM64 Focus)

### One-Command Start
```bash
bash scripts/macos/quick-start.sh
```

This automatically builds and deploys for ARM64 architecture (optimal for modern devices).

### Available macOS Scripts
- `scripts/macos/quick-start.sh` - Complete ARM64 setup and build
- `scripts/macos/android-build.sh` - ARM64-specific build and deployment  
- `scripts/macos/status-check.sh` - Environment and project status
- `scripts/macos/view-logs.sh` - Real-time Android app logs
- `scripts/macos/clean-android.sh` - Clean build artifacts

---

## Desktop Application

### Environment Setup
```bash
# Install Xcode Command Line Tools
xcode-select --install

# Install Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install dependencies
brew install openjdk@21 wget unzip curl node espeak-ng espeak

# Setup Java
echo 'export PATH="/opt/homebrew/opt/openjdk@21/bin:$PATH"' >> ~/.zshrc
echo 'export JAVA_HOME="/opt/homebrew/opt/openjdk@21"' >> ~/.zshrc
source ~/.zshrc

# Install Rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source ~/.cargo/env

# Install Edge TTS (optional)
pip3 install --use-pep517 edge-tts
```

### Build and Run
```bash
# Install dependencies
npm install
npm install -g @tauri-apps/cli
npm install --save-dev vite

# Development mode
npm run dev

# Production build
npm run build
cd src-tauri && cargo build
```

## Android Application

### Android Environment Setup (Apple Silicon)
```bash
# Create development directory
mkdir -p ~/zoo && cd ~/zoo

# Setup Android SDK and NDK (if files are in Downloads)
hdiutil attach /Users/han/Downloads/android-ndk-r28b-darwin.dmg
cp -R "/Volumes/Android NDK r28b 1/AndroidNDK13356709.app/Contents/NDK/" ./android-ndk-r28b
hdiutil detach "/Volumes/Android NDK r28b 1"
unzip /Users/han/Downloads/platform-tools-latest-darwin.zip

# Create environment script
cat > android-env.sh << 'EOF'
export ANDROID_HOME="$HOME/zoo/android-sdk"
export NDK_HOME="$HOME/zoo/android-ndk-r28b"
export PATH="$HOME/zoo/platform-tools:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/emulator:$NDK_HOME/toolchains/llvm/prebuilt/darwin-x86_64/bin:$PATH"
EOF

# Load environment
source android-env.sh

# Fix NDK tools for OpenSSL compilation
cd $NDK_HOME/toolchains/llvm/prebuilt/darwin-x86_64/bin/
ln -sf llvm-ranlib aarch64-linux-android-ranlib

# Add Rust Android targets
rustup target add aarch64-linux-android armv7-linux-androideabi i686-linux-android x86_64-linux-android
```

### Initialize Android Project
```bash
# First time only
npm run tauri android init
```

### Start Android Emulator (ARM64)
```bash
# Install SDK components (first time only)
yes | sdkmanager --licenses
sdkmanager "platforms;android-34" "build-tools;34.0.0" "emulator" "system-images;android-34;google_apis_playstore;arm64-v8a"

# Create ARM64 AVD (first time only)
avdmanager create avd -n "Alouette_ARM64" -k "system-images;android-34;google_apis_playstore;arm64-v8a" -d "pixel_7"

# Start emulator
$ANDROID_HOME/emulator/emulator -avd Alouette_ARM64 -memory 4096 -cores 4 -gpu auto -no-snapshot-save &

# Wait for device
adb wait-for-device && adb devices
```

### Build and Deploy Android
```bash
# Load environment (each session)
cd ~/zoo && source android-env.sh

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

### Android Debug Build Configuration

#### Automated Setup (Recommended)
```bash
# Build and deploy debug APK (no signing required)
bash scripts/android-build.sh
```

#### Manual Setup
```bash
# Build debug APK
npm run tauri android build --debug

# Install and run
adb install -r src-tauri/gen/android/app/build/outputs/apk/universal/debug/app-universal-debug.apk
adb shell am start -n com.alouette.app/com.alouette.app.MainActivity
```

#### Project Scripts
- **`scripts/android-build.sh`** - Builds and deploys the Android debug app

#### Troubleshooting
- Debug builds use automatic debug certificates, no manual signing required
- The `src-tauri/gen/android` directory is auto-generated
- If build fails, ensure Android environment is properly loaded: `cd ~/zoo && source android-env.sh`
- For production builds, you would need release signing, but debug mode is sufficient for development
keytool -genkey -v -keystore keystore/alouette-release.keystore \
  -alias alouette-release -keyalg RSA -keysize 2048 -validity 10000 \
  -storepass alouette2024 -keypass alouette2024 \
  -dname "CN=Alouette App, OU=Production, O=Alouette, L=Production, S=Production, C=US"
```

#### Create Keystore Properties
```bash
# Create keystore properties file
cat > keystore/keystore.properties << 'EOF'
storeFile=../../../keystore/alouette-debug.keystore
storePassword=android
keyAlias=alouette-debug
keyPassword=android

releaseStoreFile=../../../keystore/alouette-release.keystore
releaseStorePassword=alouette2024
releaseKeyAlias=alouette-release
releaseKeyPassword=alouette2024
EOF
```
