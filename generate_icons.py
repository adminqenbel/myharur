import math
from PIL import Image, ImageDraw

def create_brand_icon(size):
    # Create image with RGBA
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # Background rounded rectangle / squircle
    radius = int(size * 0.24)
    padding = int(size * 0.04)
    
    # Gradient simulation from #00D09C to #007F63 with subtle border
    for i in range(size):
        ratio = i / size
        r = int(0 * (1 - ratio) + 0 * ratio)
        g = int(208 * (1 - ratio) + 127 * ratio)
        b = int(156 * (1 - ratio) + 99 * ratio)
        # We can draw line by line inside the rounded mask
    
    # Base background mask
    bg = Image.new('RGBA', (size, size), (15, 33, 31, 255))
    mask = Image.new('L', (size, size), 0)
    mask_draw = ImageDraw.Draw(mask)
    mask_draw.rounded_rectangle([padding, padding, size - padding, size - padding], radius=radius, fill=255)
    
    # Gradient Fill
    gradient = Image.new('RGBA', (size, size))
    g_draw = ImageDraw.Draw(gradient)
    for y in range(size):
        factor = y / size
        # #051F19 to #00382B
        gr = int(5 * (1 - factor) + 0 * factor)
        gg = int(31 * (1 - factor) + 56 * factor)
        gb = int(25 * (1 - factor) + 43 * factor)
        g_draw.line([(0, y), (size, y)], fill=(gr, gg, gb, 255))
    
    img.paste(gradient, (0, 0), mask)
    
    # Outer Glow / Border
    border_draw = ImageDraw.Draw(img)
    border_draw.rounded_rectangle(
        [padding, padding, size - padding, size - padding],
        radius=radius,
        outline=(0, 208, 156, 220),
        width=max(1, int(size * 0.03))
    )
    
    # Draw Geometric 'H' twin pillars and central pulse star
    cx, cy = size / 2, size / 2
    w = size * 0.52
    h = size * 0.52
    
    left_x = cx - w * 0.38
    right_x = cx + w * 0.38
    top_y = cy - h * 0.4
    bot_y = cy + h * 0.4
    bar_w = max(2, int(size * 0.09))
    
    # Left Pillar
    border_draw.rounded_rectangle([left_x - bar_w/2, top_y, left_x + bar_w/2, bot_y], radius=int(bar_w/2), fill=(0, 208, 156, 255))
    
    # Right Pillar
    border_draw.rounded_rectangle([right_x - bar_w/2, top_y, right_x + bar_w/2, bot_y], radius=int(bar_w/2), fill=(0, 208, 156, 255))
    
    # Cross Bridge
    cross_y = cy
    cross_h = max(2, int(size * 0.08))
    border_draw.rounded_rectangle([left_x, cross_y - cross_h/2, right_x, cross_y + cross_h/2], radius=int(cross_h/2), fill=(0, 229, 255, 255))
    
    # Glowing Central Beacon
    star_radius = max(3, int(size * 0.07))
    border_draw.ellipse([cx - star_radius, cy - star_radius, cx + star_radius, cy + star_radius], fill=(255, 255, 255, 255), outline=(0, 229, 255, 255), width=max(1, int(size * 0.02)))
    
    return img

sizes_map = {
    "d:/myharur/android/app/src/main/res/mipmap-mdpi/ic_launcher.png": 48,
    "d:/myharur/android/app/src/main/res/mipmap-hdpi/ic_launcher.png": 72,
    "d:/myharur/android/app/src/main/res/mipmap-xhdpi/ic_launcher.png": 96,
    "d:/myharur/android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png": 144,
    "d:/myharur/android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png": 192,
    "d:/myharur/web/favicon.png": 64,
    "d:/myharur/web/icons/Icon-192.png": 192,
    "d:/myharur/web/icons/Icon-512.png": 512,
    "d:/myharur/web/icons/Icon-maskable-192.png": 192,
    "d:/myharur/web/icons/Icon-maskable-512.png": 512,
}

for path, sz in sizes_map.items():
    icon_img = create_brand_icon(sz)
    icon_img.save(path, "PNG")
    print(f"Generated {path} ({sz}x{sz})")

print("All app icons embedded successfully!")
