#!/bin/bash
set -e

REPO_DIR="$PWD"

APP_OUTPUT_DIR="$HOME/Applications"
mkdir -p "$APP_OUTPUT_DIR"

APP_NAME="PromptGenerator"
DISPLAY_NAME="Prompt Generator"
APP_DIR="$APP_OUTPUT_DIR/$DISPLAY_NAME.app"
MACOS_DIR="$APP_DIR/Contents/MacOS"

# Force quit any existing instances so the new build can run immediately
echo "Stopping existing app instances..."
killall "$APP_NAME" 2>/dev/null || true
killall "$DISPLAY_NAME" 2>/dev/null || true

# Clean target directories
rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR"
mkdir -p "$APP_DIR/Contents/Resources"

# Run automated tests
echo "🧪 Running automated tests..."
swiftc source/PromptEngine.swift tests/PromptEngineTests.swift -o /tmp/prompt_test_runner
/tmp/prompt_test_runner
rm -f /tmp/prompt_test_runner

# Compile Swift app source
echo "🔨 Compiling Swift sources..."
swiftc source/*.swift -o "$MACOS_DIR/$APP_NAME" -target arm64-apple-macosx12.0

# Copy Info.plist
echo "📋 Copying Info.plist..."
cp Info.plist "$APP_DIR/Contents/Info.plist"

# Generate stylish minimalist AppIcon.icns
echo "🎨 Setting up Stylish Minimalist App Icon..."
ICON_PNG="/Users/suddharay/.gemini/antigravity-ide/brain/832bec18-ea54-4008-9d26-caaa89de8b81/app_icon_prompt_generator_1786089508206.png"
if [ -f "$ICON_PNG" ]; then
    mkdir -p /tmp/AppIcon.iconset
    sips -z 16 16     "$ICON_PNG" --out /tmp/AppIcon.iconset/icon_16x16.png 2>/dev/null || true
    sips -z 32 32     "$ICON_PNG" --out /tmp/AppIcon.iconset/icon_16x16@2x.png 2>/dev/null || true
    sips -z 32 32     "$ICON_PNG" --out /tmp/AppIcon.iconset/icon_32x32.png 2>/dev/null || true
    sips -z 64 64     "$ICON_PNG" --out /tmp/AppIcon.iconset/icon_32x32@2x.png 2>/dev/null || true
    sips -z 128 128   "$ICON_PNG" --out /tmp/AppIcon.iconset/icon_128x128.png 2>/dev/null || true
    sips -z 256 256   "$ICON_PNG" --out /tmp/AppIcon.iconset/icon_128x128@2x.png 2>/dev/null || true
    sips -z 256 256   "$ICON_PNG" --out /tmp/AppIcon.iconset/icon_256x256.png 2>/dev/null || true
    sips -z 512 512   "$ICON_PNG" --out /tmp/AppIcon.iconset/icon_256x256@2x.png 2>/dev/null || true
    sips -z 512 512   "$ICON_PNG" --out /tmp/AppIcon.iconset/icon_512x512.png 2>/dev/null || true
    sips -z 1024 1024 "$ICON_PNG" --out /tmp/AppIcon.iconset/icon_512x512@2x.png 2>/dev/null || true
    iconutil -c icns /tmp/AppIcon.iconset -o "$APP_DIR/Contents/Resources/AppIcon.icns" 2>/dev/null || cp "$ICON_PNG" "$APP_DIR/Contents/Resources/AppIcon.icns"
    rm -rf /tmp/AppIcon.iconset
elif [ -f "/System/Applications/Shortcuts.app/Contents/Resources/AppIcon.icns" ]; then
    cp "/System/Applications/Shortcuts.app/Contents/Resources/AppIcon.icns" "$APP_DIR/Contents/Resources/AppIcon.icns"
fi

# Touch bundle
touch "$APP_DIR"

# Ad-hoc Code signing
echo "🔏 Code signing..."
xattr -cr "$APP_DIR" 2>/dev/null || true
codesign --force --deep --sign - "$APP_DIR"

# Register with LaunchServices
echo "🚀 Registering with LaunchServices..."
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "$APP_DIR" 2>/dev/null || true

# Copy to /Applications if writable
if [ -w "/Applications" ]; then
    rm -rf "/Applications/$DISPLAY_NAME.app"
    cp -R "$APP_DIR" "/Applications/$DISPLAY_NAME.app"
    /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "/Applications/$DISPLAY_NAME.app" 2>/dev/null || true
fi

echo ""
echo "✅ Build complete! App installed to: $APP_DIR"
echo "🚀 Launching application..."
open "$APP_DIR"
