from PIL import Image, ImageDraw
import math, os

def heart_points(cx, cy, size, num_points=120):
    pts = []
    for i in range(num_points):
        t = 2 * math.pi * i / num_points
        x = 16 * math.sin(t) ** 3
        y = 13 * math.cos(t) - 5 * math.cos(2 * t) - 2 * math.cos(3 * t) - math.cos(4 * t)
        pts.append((cx + int(x * size / 16), cy - int(y * size / 16)))
    return pts

def create_icon(size):
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # Gradient background
    for y in range(size):
        for x in range(size):
            t = (x + y) / (2 * size)
            r = int(255 * (1 - t) + 252 * t)
            g = int(230 * (1 - t) + 107 * t)
            b = int(240 * (1 - t) + 157 * t)
            draw.point((x, y), fill=(r, g, b, 255))

    cx, cy = size // 2, size // 2 + size // 12

    # Outer glow
    glow_radius = int(size * 0.42)
    for r in range(glow_radius, int(size * 0.32), -2):
        alpha = int(35 * (1 - (r - size * 0.32) / (glow_radius - size * 0.32)))
        heart = heart_points(cx, cy, r, 80)
        draw.polygon(heart, fill=(255, 255, 255, alpha))

    # Main white heart
    heart_pts = heart_points(cx, cy, int(size * 0.32), 100)
    draw.polygon(heart_pts, fill=(255, 255, 255, 255))

    # Inner pink heart
    inner_pts = heart_points(cx, cy, int(size * 0.20), 100)
    draw.polygon(inner_pts, fill=(255, 107, 157, 240))

    return img

base = r"C:\Users\diego\Documents\Nueva carpeta\iphone app\Novios\Assets.xcassets\AppIcon.appiconset"

sizes = {
    "20@2x": 40, "20@3x": 60,
    "29@2x": 58, "29@3x": 87,
    "40@2x": 80, "40@3x": 120,
    "60@2x": 120, "60@3x": 180,
    "1024": 1024,
}

# Create 1024 base
img_1024 = create_icon(1024)
img_1024.save(f"{base}/AppIcon-1024.png", "PNG")

# Create other sizes from base
for name, sz in sizes.items():
    if name != "1024":
        resized = img_1024.resize((sz, sz), Image.Resampling.LANCZOS)
        resized.save(f"{base}/AppIcon-{name}.png", "PNG")

print("All icons generated")

# Also update assets/app_icon.png for the Flutter side
img_copy = img_1024.copy()
img_copy.save(r"C:\Users\diego\Documents\Nueva carpeta\assets\app_icon.png", "PNG")
print("Updated assets/app_icon.png")
