#!/bin/bash

# Script to set up Tauri app icons from alouette_icon.png
# This script assumes you have ImageMagick installed

echo "Setting up Alouette app icons..."

# Check if ImageMagick is installed
if ! command -v convert &>/dev/null; then
    echo "ImageMagick is not installed. Installing with Homebrew..."
    if command -v brew &>/dev/null; then
        brew install imagemagick
    else
        echo "Please install ImageMagick manually:"
        echo "brew install imagemagick"
        exit 1
    fi
fi

# Source icon file (adjust path if needed)
SOURCE_ICON="$HOME/Downloads/alouette_icon.png"
ICONS_DIR="$(dirname "$0")/../src-tauri/icons"

# Check if source icon exists
if [ ! -f "$SOURCE_ICON" ]; then
    echo "Source icon not found at: $SOURCE_ICON"
    echo "Please ensure alouette_icon.png is in your Downloads folder, or update the SOURCE_ICON path in this script."
    exit 1
fi

# Create icons directory if it doesn't exist
mkdir -p "$ICONS_DIR"

echo "Generating icons from: $SOURCE_ICON"
echo "Output directory: $ICONS_DIR"

# Generate PNG icons for different sizes
convert "$SOURCE_ICON" -resize 32x32 "$ICONS_DIR/32x32.png"
convert "$SOURCE_ICON" -resize 128x128 "$ICONS_DIR/128x128.png"
convert "$SOURCE_ICON" -resize 256x256 "$ICONS_DIR/128x128@2x.png"

# Generate icon.ico for Windows (multiple sizes embedded)
convert "$SOURCE_ICON" \
    \( -clone 0 -resize 16x16 \) \
    \( -clone 0 -resize 32x32 \) \
    \( -clone 0 -resize 48x48 \) \
    \( -clone 0 -resize 64x64 \) \
    \( -clone 0 -resize 128x128 \) \
    \( -clone 0 -resize 256x256 \) \
    -delete 0 "$ICONS_DIR/icon.ico"

# Generate .icns for macOS (requires iconutil on macOS)
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "Generating macOS .icns file..."

    # Create iconset directory
    ICONSET_DIR="$ICONS_DIR/icon.iconset"
    mkdir -p "$ICONSET_DIR"

    # Generate all required sizes for .icns
    convert "$SOURCE_ICON" -resize 16x16 "$ICONSET_DIR/icon_16x16.png"
    convert "$SOURCE_ICON" -resize 32x32 "$ICONSET_DIR/icon_16x16@2x.png"
    convert "$SOURCE_ICON" -resize 32x32 "$ICONSET_DIR/icon_32x32.png"
    convert "$SOURCE_ICON" -resize 64x64 "$ICONSET_DIR/icon_32x32@2x.png"
    convert "$SOURCE_ICON" -resize 128x128 "$ICONSET_DIR/icon_128x128.png"
    convert "$SOURCE_ICON" -resize 256x256 "$ICONSET_DIR/icon_128x128@2x.png"
    convert "$SOURCE_ICON" -resize 256x256 "$ICONSET_DIR/icon_256x256.png"
    convert "$SOURCE_ICON" -resize 512x512 "$ICONSET_DIR/icon_256x256@2x.png"
    convert "$SOURCE_ICON" -resize 512x512 "$ICONSET_DIR/icon_512x512.png"
    convert "$SOURCE_ICON" -resize 1024x1024 "$ICONSET_DIR/icon_512x512@2x.png"

    # Create .icns file
    iconutil -c icns "$ICONSET_DIR" -o "$ICONS_DIR/icon.icns"

    # Clean up iconset directory
    rm -rf "$ICONSET_DIR"

    echo "Generated icon.icns for macOS"
fi

echo "Icon generation complete!"
echo "Generated files:"
ls -la "$ICONS_DIR"

echo ""
echo "You can now run: npm run dev"
