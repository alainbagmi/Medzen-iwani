#!/usr/bin/env python3
"""
Generate web icons from the MedZen Health logo.
Usage: python3 generate_web_icons.py <path_to_logo_image>
"""

import sys
import os
from PIL import Image, ImageOps

def generate_icons(logo_path):
    """Generate web icons from the provided logo."""

    if not os.path.exists(logo_path):
        print(f"Error: Logo file not found: {logo_path}")
        sys.exit(1)

    # Create web/icons directory if it doesn't exist
    os.makedirs('web/icons', exist_ok=True)

    try:
        # Open the logo image
        img = Image.open(logo_path).convert('RGBA')
        print(f"✓ Loaded logo from: {logo_path}")
        print(f"  Original size: {img.size}")

        # Create 192x192 icon
        icon_192 = ImageOps.fit(img, (192, 192), Image.Resampling.LANCZOS)
        icon_192.save('web/icons/Icon-192.png', 'PNG')
        print("✓ Generated web/icons/Icon-192.png (192x192)")

        # Create 512x512 icon
        icon_512 = ImageOps.fit(img, (512, 512), Image.Resampling.LANCZOS)
        icon_512.save('web/icons/Icon-512.png', 'PNG')
        print("✓ Generated web/icons/Icon-512.png (512x512)")

        # Create favicon (smaller, 64x64 and as ICO)
        favicon = ImageOps.fit(img, (64, 64), Image.Resampling.LANCZOS)
        favicon.save('web/favicon.png', 'PNG')
        favicon.save('web/favicon.ico', 'ICO')
        print("✓ Generated web/favicon.png (64x64)")
        print("✓ Generated web/favicon.ico")

        # Create app launcher icon (large, 1024x1024)
        icon_1024 = ImageOps.fit(img, (1024, 1024), Image.Resampling.LANCZOS)
        icon_1024.save('web/icons/app_launcher_icon.png', 'PNG')
        print("✓ Generated web/icons/app_launcher_icon.png (1024x1024)")

        print("\n✅ All web icons generated successfully!")

    except Exception as e:
        print(f"Error processing image: {e}")
        sys.exit(1)

if __name__ == '__main__':
    if len(sys.argv) < 2:
        print("Usage: python3 generate_web_icons.py <path_to_logo_image>")
        print("\nExample: python3 generate_web_icons.py medzen_health_logo.png")
        sys.exit(1)

    generate_icons(sys.argv[1])
