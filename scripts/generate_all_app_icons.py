#!/usr/bin/env python3
"""
Generate all app icons and brand assets for Vyavahaar across Android, macOS, Windows, and Flutter.
"""
import os
import subprocess
import shutil

PROJECT_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
SRC_IMAGE = "/data/user/0/ai.antigem/files/home/.gemini/antigravity-cli/brain/845be6d1-508e-4e0b-86d6-9d2cc77469bb/.user_uploaded/media_1795500822905_d2d189e2.jpg"
TMP_DIR = "/data/user/0/ai.antigem/files/usr/tmp/vyavahaar_icons"

os.makedirs(TMP_DIR, exist_ok=True)

def run(cmd):
    subprocess.run(cmd, shell=True, check=True)

print("1. Creating Master 1024x1024 Squircle Icon with transparent corners...")
# Floodfill transparent outside the squircle
master_squircle = f"{TMP_DIR}/master_squircle_1024.png"
run(f"""
magick "{SRC_IMAGE}" \\
  -alpha set -fuzz 10% -fill "rgba(0,0,0,0)" \\
  -draw "color 0,0 floodfill" \\
  -draw "color 1253,0 floodfill" \\
  -draw "color 0,1253 floodfill" \\
  -draw "color 1253,1253 floodfill" \\
  -trim +repage \\
  -background none -gravity center -extent 1144x1144 \\
  -resize 1024x1024 "{master_squircle}"
""")

print("2. Extracting Golden Book Symbol & Adaptive Foreground...")
book_cropped = f"{TMP_DIR}/book_cropped.png"
run(f"""
magick "{master_squircle}" \\
  -alpha set -fuzz 12% -fill "rgba(0,0,0,0)" \\
  -draw "color 100,100 floodfill" \\
  -crop 820x460+102+310 +repage \\
  -trim +repage "{book_cropped}"
""")

# Scale and center the book inside 1024x1024 for adaptive icon foreground (safe zone is 66% circle)
adaptive_fg_1024 = f"{TMP_DIR}/adaptive_foreground_1024.png"
run(f"""
magick "{book_cropped}" \\
  -resize 580x -background none -gravity center -extent 1024x1024 "{adaptive_fg_1024}"
""")

# Monochrome version for Material You (Android 13+)
adaptive_mono_1024 = f"{TMP_DIR}/adaptive_monochrome_1024.png"
run(f"""
magick "{adaptive_fg_1024}" \\
  -channel RGB -evaluate set 100% +channel "{adaptive_mono_1024}"
""")

# Round icon (circle mask on #01333A background with centered book)
round_icon_1024 = f"{TMP_DIR}/icon_round_1024.png"
run(f"""
magick \\( -size 1024x1024 xc:"#01333A" "{adaptive_fg_1024}" -composite \\) \\
  \\( -size 1024x1024 xc:black -fill white -draw "circle 512,512 512,10" \\) \\
  -alpha off -compose CopyOpacity -composite "{round_icon_1024}"
""")

print("3. Generating Android Mipmap Legacy & Round Icons...")
android_res = os.path.join(PROJECT_ROOT, "android/app/src/main/res")

sizes = {
    "mipmap-mdpi": (48, 108),
    "mipmap-hdpi": (72, 162),
    "mipmap-xhdpi": (96, 216),
    "mipmap-xxhdpi": (144, 324),
    "mipmap-xxxhdpi": (192, 432),
}

for folder, (std_size, adapt_size) in sizes.items():
    dir_path = os.path.join(android_res, folder)
    os.makedirs(dir_path, exist_ok=True)
    
    # ic_launcher.png (standard squircle)
    run(f'magick "{master_squircle}" -resize {std_size}x{std_size} "{dir_path}/ic_launcher.png"')
    
    # ic_launcher_round.png (round version)
    run(f'magick "{round_icon_1024}" -resize {std_size}x{std_size} "{dir_path}/ic_launcher_round.png"')
    
    # ic_launcher_foreground.png
    run(f'magick "{adaptive_fg_1024}" -resize {adapt_size}x{adapt_size} "{dir_path}/ic_launcher_foreground.png"')
    
    # ic_launcher_monochrome.png
    run(f'magick "{adaptive_mono_1024}" -resize {adapt_size}x{adapt_size} "{dir_path}/ic_launcher_monochrome.png"')
    
    # ic_launcher_background.png
    run(f'magick -size {adapt_size}x{adapt_size} xc:"#01333A" "{dir_path}/ic_launcher_background.png"')

print("4. Generating Android Drawable Adaptive Layers...")
drawable_sizes = {
    "drawable-mdpi": 108,
    "drawable-hdpi": 162,
    "drawable-xhdpi": 216,
    "drawable-xxhdpi": 324,
    "drawable-xxxhdpi": 432,
}

for folder, size in drawable_sizes.items():
    dir_path = os.path.join(android_res, folder)
    os.makedirs(dir_path, exist_ok=True)
    run(f'magick "{adaptive_fg_1024}" -resize {size}x{size} "{dir_path}/ic_launcher_foreground.png"')
    run(f'magick "{adaptive_mono_1024}" -resize {size}x{size} "{dir_path}/ic_launcher_monochrome.png"')

print("5. Generating Flutter Brand Assets in assets/brand/...")
brand_dir = os.path.join(PROJECT_ROOT, "assets/brand")
os.makedirs(brand_dir, exist_ok=True)

# vyavahaar-icon-512.png
run(f'magick "{master_squircle}" -resize 512x512 "{brand_dir}/vyavahaar-icon-512.png"')

# vyavahaar-logo-2048.png
run(f'magick "{master_squircle}" -resize 1024x1024 "{brand_dir}/vyavahaar-logo-2048.png"')

# vyavahaar-logo-transparent.png (centered book symbol with transparency)
run(f'magick "{book_cropped}" -resize 512x -background none -gravity center -extent 512x512 "{brand_dir}/vyavahaar-logo-transparent.png"')

# vyavahaar-symbol-48.png (used by AppSymbol widget across screens)
run(f'magick "{book_cropped}" -resize 48x48 -background none -gravity center -extent 48x48 "{brand_dir}/vyavahaar-symbol-48.png"')

# vyavahaar-symbol-24.png
run(f'magick "{book_cropped}" -resize 24x24 -background none -gravity center -extent 24x24 "{brand_dir}/vyavahaar-symbol-24.png"')

# vyavahaar-adaptive-foreground.png
run(f'magick "{adaptive_fg_1024}" -resize 512x512 "{brand_dir}/vyavahaar-adaptive-foreground.png"')

# vyavahaar-adaptive-background.png
run(f'magick -size 512x512 xc:"#01333A" "{brand_dir}/vyavahaar-adaptive-background.png"')

print("6. Generating macOS Icons...")
macos_dir = os.path.join(PROJECT_ROOT, "macos/Runner/Assets.xcassets/AppIcon.appiconset")
if os.path.exists(macos_dir):
    macos_sizes = [16, 32, 64, 128, 256, 512, 1024]
    for sz in macos_sizes:
        run(f'magick "{master_squircle}" -resize {sz}x{sz} "{macos_dir}/app_icon_{sz}.png"')

print("7. Generating Windows Icon...")
windows_res = os.path.join(PROJECT_ROOT, "windows/runner/resources")
if os.path.exists(windows_res):
    ico_path = os.path.join(windows_res, "app_icon.ico")
    run(f'magick "{master_squircle}" -define icon:auto-resize=256,128,64,48,32,16 "{ico_path}"')

print("All icons and brand assets generated successfully!")
