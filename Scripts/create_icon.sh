#!/bin/bash

# Create app icon from SVG
# Requires: qlmanage (macOS built-in) or rsvg-convert

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
SVG_FILE="$PROJECT_DIR/Resources/AppIcon.svg"
ICONSET_DIR="$PROJECT_DIR/Resources/AppIcon.iconset"
ICNS_FILE="$PROJECT_DIR/Resources/AppIcon.icns"

echo "Creating app icon from SVG..."

# Create iconset directory
rm -rf "$ICONSET_DIR"
mkdir -p "$ICONSET_DIR"

# Check if we have rsvg-convert (best quality)
if command -v rsvg-convert &> /dev/null; then
    echo "Using rsvg-convert..."
    CONVERT_CMD="rsvg-convert"
elif command -v convert &> /dev/null; then
    echo "Using ImageMagick convert..."
    CONVERT_CMD="convert"
else
    echo "Using sips (built-in)..."
    CONVERT_CMD="sips"
fi

# Icon sizes needed for macOS
SIZES=(16 32 64 128 256 512 1024)

# Create a high-res PNG first using qlmanage or similar
if [ "$CONVERT_CMD" = "sips" ]; then
    # First create a high-res PNG using qlmanage
    qlmanage -t -s 1024 -o "$PROJECT_DIR/Resources/" "$SVG_FILE" 2>/dev/null
    if [ -f "$PROJECT_DIR/Resources/AppIcon.svg.png" ]; then
        mv "$PROJECT_DIR/Resources/AppIcon.svg.png" "$PROJECT_DIR/Resources/AppIcon_1024.png"
        SOURCE_PNG="$PROJECT_DIR/Resources/AppIcon_1024.png"
    else
        # Fallback: create a simple PNG using Python
        echo "Creating PNG with Python..."
        python3 << 'EOF'
import subprocess
import os

project_dir = os.environ.get('PROJECT_DIR', '.')
svg_file = f"{project_dir}/Resources/AppIcon.svg"
png_file = f"{project_dir}/Resources/AppIcon_1024.png"

# Try using cairosvg if available
try:
    import cairosvg
    cairosvg.svg2png(url=svg_file, write_to=png_file, output_width=1024, output_height=1024)
except ImportError:
    # Create a simple colored icon as fallback
    from PIL import Image, ImageDraw
    img = Image.new('RGBA', (1024, 1024), (26, 26, 46, 255))
    draw = ImageDraw.Draw(img)
    # Draw eye shape
    draw.ellipse([172, 312, 852, 712], fill=(255, 255, 255, 240))
    draw.ellipse([382, 382, 642, 642], fill=(226, 1, 45, 255))
    draw.ellipse([452, 452, 572, 572], fill=(15, 15, 26, 255))
    img.save(png_file)
EOF
        SOURCE_PNG="$PROJECT_DIR/Resources/AppIcon_1024.png"
    fi

    # Generate all sizes using sips
    for size in "${SIZES[@]}"; do
        sips -z $size $size "$SOURCE_PNG" --out "$ICONSET_DIR/icon_${size}x${size}.png" 2>/dev/null
    done

    # Create @2x versions
    sips -z 32 32 "$SOURCE_PNG" --out "$ICONSET_DIR/icon_16x16@2x.png" 2>/dev/null
    sips -z 64 64 "$SOURCE_PNG" --out "$ICONSET_DIR/icon_32x32@2x.png" 2>/dev/null
    sips -z 256 256 "$SOURCE_PNG" --out "$ICONSET_DIR/icon_128x128@2x.png" 2>/dev/null
    sips -z 512 512 "$SOURCE_PNG" --out "$ICONSET_DIR/icon_256x256@2x.png" 2>/dev/null
    sips -z 1024 1024 "$SOURCE_PNG" --out "$ICONSET_DIR/icon_512x512@2x.png" 2>/dev/null

elif [ "$CONVERT_CMD" = "rsvg-convert" ]; then
    for size in "${SIZES[@]}"; do
        rsvg-convert -w $size -h $size "$SVG_FILE" > "$ICONSET_DIR/icon_${size}x${size}.png"
    done

    # Create @2x versions
    rsvg-convert -w 32 -h 32 "$SVG_FILE" > "$ICONSET_DIR/icon_16x16@2x.png"
    rsvg-convert -w 64 -h 64 "$SVG_FILE" > "$ICONSET_DIR/icon_32x32@2x.png"
    rsvg-convert -w 256 -h 256 "$SVG_FILE" > "$ICONSET_DIR/icon_128x128@2x.png"
    rsvg-convert -w 512 -h 512 "$SVG_FILE" > "$ICONSET_DIR/icon_256x256@2x.png"
    rsvg-convert -w 1024 -h 1024 "$SVG_FILE" > "$ICONSET_DIR/icon_512x512@2x.png"

else
    # ImageMagick
    for size in "${SIZES[@]}"; do
        convert -background none -resize ${size}x${size} "$SVG_FILE" "$ICONSET_DIR/icon_${size}x${size}.png"
    done

    convert -background none -resize 32x32 "$SVG_FILE" "$ICONSET_DIR/icon_16x16@2x.png"
    convert -background none -resize 64x64 "$SVG_FILE" "$ICONSET_DIR/icon_32x32@2x.png"
    convert -background none -resize 256x256 "$SVG_FILE" "$ICONSET_DIR/icon_128x128@2x.png"
    convert -background none -resize 512x512 "$SVG_FILE" "$ICONSET_DIR/icon_256x256@2x.png"
    convert -background none -resize 1024x1024 "$SVG_FILE" "$ICONSET_DIR/icon_512x512@2x.png"
fi

# Convert iconset to icns
iconutil -c icns "$ICONSET_DIR" -o "$ICNS_FILE"

if [ -f "$ICNS_FILE" ]; then
    echo "✅ App icon created: $ICNS_FILE"
    # Cleanup
    rm -rf "$ICONSET_DIR"
    rm -f "$PROJECT_DIR/Resources/AppIcon_1024.png"
else
    echo "❌ Failed to create app icon"
    exit 1
fi
