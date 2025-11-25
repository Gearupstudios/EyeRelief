#!/usr/bin/env python3
"""Generate macOS app icon for EyeRelief"""

import os
import subprocess
import math

def create_icon_png(size, output_path):
    """Create a simple eye icon PNG using basic drawing"""
    try:
        from PIL import Image, ImageDraw
    except ImportError:
        print("PIL not available, trying alternative...")
        return False

    # Create image with dark background
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # Scale factor
    s = size / 1024.0

    # Background rounded rectangle (approximate with ellipse corners)
    padding = int(20 * s)
    corner_radius = int(220 * s)

    # Draw background
    bg_color = (26, 26, 46, 255)
    draw.rounded_rectangle([padding, padding, size - padding, size - padding],
                          radius=corner_radius, fill=bg_color)

    # Center
    cx, cy = size // 2, size // 2

    # Eye white (sclera) - ellipse
    eye_rx = int(300 * s)
    eye_ry = int(170 * s)
    draw.ellipse([cx - eye_rx, cy - eye_ry, cx + eye_rx, cy + eye_ry],
                fill=(255, 255, 255, 242))

    # Iris - T1 Red
    iris_r = int(130 * s)
    t1_red = (226, 1, 45, 255)
    draw.ellipse([cx - iris_r, cy - iris_r, cx + iris_r, cy + iris_r],
                fill=t1_red)

    # Pupil
    pupil_r = int(60 * s)
    draw.ellipse([cx - pupil_r, cy - pupil_r, cx + pupil_r, cy + pupil_r],
                fill=(15, 15, 26, 255))

    # Light reflection
    ref_x = cx - int(42 * s)
    ref_y = cy - int(42 * s)
    ref_rx = int(30 * s)
    ref_ry = int(25 * s)
    draw.ellipse([ref_x - ref_rx, ref_y - ref_ry, ref_x + ref_rx, ref_y + ref_ry],
                fill=(255, 255, 255, 204))

    # Small reflection
    ref2_x = cx + int(38 * s)
    ref2_y = cy + int(28 * s)
    ref2_r = int(12 * s)
    draw.ellipse([ref2_x - ref2_r, ref2_y - ref2_r, ref2_x + ref2_r, ref2_y + ref2_r],
                fill=(255, 255, 255, 127))

    # Eye outline (outer ring) - T1 Red
    outline_rx = int(340 * s)
    outline_ry = int(200 * s)
    outline_width = int(40 * s)

    # Draw outline as thick ellipse border
    for i in range(outline_width):
        alpha = int(255 * (1 - i / outline_width * 0.5))
        color = (226, 1, 45, alpha)
        draw.ellipse([cx - outline_rx - i//2, cy - outline_ry - i//2,
                     cx + outline_rx + i//2, cy + outline_ry + i//2],
                    outline=color, width=1)

    img.save(output_path, 'PNG')
    return True

def main():
    script_dir = os.path.dirname(os.path.abspath(__file__))
    project_dir = os.path.dirname(script_dir)
    resources_dir = os.path.join(project_dir, 'Resources')
    iconset_dir = os.path.join(resources_dir, 'AppIcon.iconset')
    icns_path = os.path.join(resources_dir, 'AppIcon.icns')

    # Create iconset directory
    os.makedirs(iconset_dir, exist_ok=True)

    # Icon sizes for macOS
    icon_configs = [
        (16, 'icon_16x16.png'),
        (32, 'icon_16x16@2x.png'),
        (32, 'icon_32x32.png'),
        (64, 'icon_32x32@2x.png'),
        (128, 'icon_128x128.png'),
        (256, 'icon_128x128@2x.png'),
        (256, 'icon_256x256.png'),
        (512, 'icon_256x256@2x.png'),
        (512, 'icon_512x512.png'),
        (1024, 'icon_512x512@2x.png'),
    ]

    print("Generating icon images...")
    for size, filename in icon_configs:
        output_path = os.path.join(iconset_dir, filename)
        if create_icon_png(size, output_path):
            print(f"  Created {filename}")
        else:
            print(f"  Failed to create {filename}")
            return False

    # Convert to icns using iconutil
    print("Converting to icns...")
    result = subprocess.run(['iconutil', '-c', 'icns', iconset_dir, '-o', icns_path],
                          capture_output=True, text=True)

    if result.returncode == 0:
        print(f"✅ App icon created: {icns_path}")
        # Cleanup
        import shutil
        shutil.rmtree(iconset_dir, ignore_errors=True)
        return True
    else:
        print(f"❌ iconutil failed: {result.stderr}")
        return False

if __name__ == '__main__':
    main()
