#!/bin/bash

# EyeRelief DMG Creation Script
# This script creates a professional-looking DMG for distribution

APP_NAME="EyeRelief"
VERSION="1.1"
DMG_NAME="${APP_NAME}_${VERSION}.dmg"
SOURCE_DIR="build/Release"
DMG_TEMP_DIR="dmg_temp"

# Clean up any previous DMG creation
if [ -d "$DMG_TEMP_DIR" ]; then
    rm -rf "$DMG_TEMP_DIR"
fi

if [ -f "$DMG_NAME" ]; then
    rm -f "$DMG_NAME"
fi

# Create temporary directory for DMG contents
mkdir -p "$DMG_TEMP_DIR"

# Copy the app to temporary directory
if [ -d "$SOURCE_DIR/${APP_NAME}.app" ]; then
    cp -R "$SOURCE_DIR/${APP_NAME}.app" "$DMG_TEMP_DIR/"
    echo "Copied ${APP_NAME}.app to temporary directory"
else
    echo "Error: ${APP_NAME}.app not found in $SOURCE_DIR"
    echo "Please build the app first using Xcode"
    exit 1
fi

# Create Applications symlink for easy installation
ln -s /Applications "$DMG_TEMP_DIR/Applications"

# Create DMG with specific settings
hdiutil create \
    -volname "$APP_NAME" \
    -srcfolder "$DMG_TEMP_DIR" \
    -ov \
    -format UDZO \
    -imagekey zlib-level=9 \
    "$DMG_NAME"

# Clean up temporary directory
rm -rf "$DMG_TEMP_DIR"

echo "DMG created successfully: $DMG_NAME"
echo ""
echo "To notarize the DMG for distribution:"
echo "xcrun altool --notarize-app --primary-bundle-id \"com.yourname.eyerelief\" --username \"your@email.com\" --password \"app-specific-password\" --file \"$DMG_NAME\""
echo ""
echo "To staple the notarization ticket after approval:"
echo "xcrun stapler staple \"$DMG_NAME\""