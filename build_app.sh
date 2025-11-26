#!/bin/bash

# EyeRelief Build Script
# This script builds the app and creates a DMG for distribution

set -e

APP_NAME="EyeRelief"
BUNDLE_ID="com.local.eyerelief"
VERSION="1.7"
BUILD_DIR="build"
APP_DIR="$BUILD_DIR/$APP_NAME.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"
DMG_NAME="$BUILD_DIR/${APP_NAME}.dmg"

echo "========================================"
echo "Building $APP_NAME v$VERSION..."
echo "========================================"

# Clean previous build
if [ -d "$APP_DIR" ]; then
    echo "🧹 Cleaning previous build..."
    rm -rf "$APP_DIR"
fi

# Create app bundle structure
echo "📁 Creating app bundle structure..."
mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"
mkdir -p "$CONTENTS_DIR"

# Create Info.plist with all required keys for notifications
echo "📝 Creating Info.plist..."
cat > "$CONTENTS_DIR/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>$APP_NAME</string>
    <key>CFBundleIdentifier</key>
    <string>$BUNDLE_ID</string>
    <key>CFBundleName</key>
    <string>$APP_NAME</string>
    <key>CFBundleDisplayName</key>
    <string>EyeRelief</string>
    <key>CFBundleVersion</key>
    <string>$VERSION</string>
    <key>CFBundleShortVersionString</key>
    <string>$VERSION</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleSignature</key>
    <string>????</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>LSUIElement</key>
    <false/>
    <key>NSSupportsAutomaticGraphicsSwitching</key>
    <true/>
    <key>NSAppTransportSecurity</key>
    <dict>
        <key>NSAllowsArbitraryLoads</key>
        <false/>
    </dict>
    <key>LSApplicationCategoryType</key>
    <string>public.app-category.healthcare-fitness</string>
    <key>NSUserNotificationAlertStyle</key>
    <string>alert</string>
    <key>NSUserNotificationsUsageDescription</key>
    <string>EyeRelief needs to send you notifications to remind you to take regular eye breaks following the 20-20-20 rule.</string>
    <key>LSMinimumSystemVersion</key>
    <string>11.0</string>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
</dict>
</plist>
EOF

# Copy Resources (excluding Info.plist)
if [ -d "Resources" ]; then
    echo "📦 Copying resources..."
    for item in Resources/*; do
        if [[ "$item" != *"Info.plist"* ]] && [[ "$item" != *".iconset"* ]]; then
            cp -R "$item" "$RESOURCES_DIR/" 2>/dev/null || true
        fi
    done
fi

# Copy app icon if it exists
if [ -f "Resources/AppIcon.icns" ]; then
    echo "🎨 Copying app icon..."
    cp "Resources/AppIcon.icns" "$RESOURCES_DIR/"
fi

# Compile Swift files
echo "🔨 Compiling Swift files..."
SWIFT_FILES=(
    "EyeReliefApp.swift"
    "ContentView.swift"
    "AppDelegate.swift"
    "BreakOverlayView.swift"
    "Models/TimerManager.swift"
    "Models/NotificationManager.swift"
    "Models/OverlayManager.swift"
    "Models/MenuBarManager.swift"
    "Models/SettingsManager.swift"
    "Models/LaunchAtLoginManager.swift"
    "Models/StatsManager.swift"
)

# Check if all files exist
for file in "${SWIFT_FILES[@]}"; do
    if [ ! -f "$file" ]; then
        echo "❌ Error: $file not found"
        exit 1
    fi
done

# Compile with optimization
swiftc -O -o "$MACOS_DIR/$APP_NAME" \
    "${SWIFT_FILES[@]}" \
    -framework SwiftUI \
    -framework AppKit \
    -framework Foundation \
    -framework Combine \
    -framework UserNotifications \
    -target arm64-apple-macos11.0 \
    -target x86_64-apple-macos11.0 \
    2>&1 || swiftc -O -o "$MACOS_DIR/$APP_NAME" \
    "${SWIFT_FILES[@]}" \
    -framework SwiftUI \
    -framework AppKit \
    -framework Foundation \
    -framework Combine \
    -framework UserNotifications

if [ $? -ne 0 ]; then
    echo "❌ Build failed"
    exit 1
fi

echo "✅ Compilation successful!"

# Make executable
chmod +x "$MACOS_DIR/$APP_NAME"

# Clean up macOS extended attributes that can cause signing issues
echo "🧹 Cleaning extended attributes..."
find "$APP_DIR" -name '._*' -delete 2>/dev/null || true
xattr -cr "$APP_DIR" 2>/dev/null || true

# Ad-hoc code sign (required for notifications to work properly)
echo "🔏 Code signing (ad-hoc)..."
codesign --force --deep --sign - "$APP_DIR"

if [ $? -eq 0 ]; then
    echo "✅ Code signing successful!"
else
    echo "⚠️ Code signing failed, but app may still work"
fi

echo ""
echo "✅ Build complete!"
echo "📍 App bundle: $APP_DIR"
echo ""

# Ask if user wants to create DMG
if [ "$1" == "--dmg" ]; then
    echo "========================================"
    echo "Creating DMG..."
    echo "========================================"

    # Remove old DMG
    if [ -f "$DMG_NAME" ]; then
        rm -f "$DMG_NAME"
    fi

    # Create temp directory for DMG contents
    DMG_TEMP="$BUILD_DIR/dmg_temp"
    rm -rf "$DMG_TEMP"
    mkdir -p "$DMG_TEMP"

    # Copy app
    cp -R "$APP_DIR" "$DMG_TEMP/"

    # Create Applications symlink
    ln -s /Applications "$DMG_TEMP/Applications"

    # Create DMG
    hdiutil create \
        -volname "$APP_NAME" \
        -srcfolder "$DMG_TEMP" \
        -ov \
        -format UDZO \
        -imagekey zlib-level=9 \
        "$DMG_NAME"

    # Clean up
    rm -rf "$DMG_TEMP"

    echo ""
    echo "✅ DMG created: $DMG_NAME"
fi

# Launch option
if [ "$1" == "--launch" ] || [ "$2" == "--launch" ]; then
    echo "🚀 Launching app..."
    open "$APP_DIR"
fi

echo ""
echo "========================================"
echo "Usage:"
echo "  ./build_app.sh          - Build only"
echo "  ./build_app.sh --dmg    - Build and create DMG"
echo "  ./build_app.sh --launch - Build and launch"
echo "  ./build_app.sh --dmg --launch - All"
echo "========================================"