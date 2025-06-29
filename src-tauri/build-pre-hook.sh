#!/bin/bash
# Pre-build hook to ensure Android build consistency

set -e

echo "🔧 Pre-build Android consistency check..."

# Check if we're building for Android
if [[ "$CARGO_CFG_TARGET_OS" == "android" ]]; then
    echo "📱 Android build detected"
    
    # Ensure gen/android directory structure exists
    mkdir -p gen/android/app/src/main/jniLibs/arm64-v8a
    mkdir -p gen/android/app/src/main/jniLibs/armeabi-v7a
    mkdir -p gen/android/app/src/main/jniLibs/x86
    mkdir -p gen/android/app/src/main/jniLibs/x86_64
    
    echo "✅ Android directory structure verified"
    
    # Ensure target directories exist
    mkdir -p target/aarch64-linux-android/debug
    mkdir -p target/armv7-linux-androideabi/release
    mkdir -p target/i686-linux-android/release
    mkdir -p target/x86_64-linux-android/release
    
    echo "✅ Target directories verified"
fi

echo "✅ Pre-build consistency check complete"
