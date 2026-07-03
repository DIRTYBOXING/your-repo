from PIL import Image
import os

src = r'c:\Users\User\dev\Data Fight Central\assets\logos\dfc_logo_icon.png'
web_icons = r'c:\Users\User\dev\Data Fight Central\web\icons'
assets_icons = r'c:\Users\User\dev\Data Fight Central\assets\icons'
web_root = r'c:\Users\User\dev\Data Fight Central\web'

img = Image.open(src)
print(f'Source image: {img.size}, mode={img.mode}')

# Ensure RGBA for transparency support
if img.mode != 'RGBA':
    img = img.convert('RGBA')

# Center-crop to square (the logo is centered in the image)
w, h = img.size
if w != h:
    side = min(w, h)
    left = (w - side) // 2
    top = (h - side) // 2
    img = img.crop((left, top, left + side, top + side))
    print(f'Cropped to square: {img.size}')

# Generate web icons
for size, name in [(192, 'Icon-192.png'), (512, 'Icon-512.png'), (192, 'Icon-maskable-192.png'), (512, 'Icon-maskable-512.png')]:
    resized = img.resize((size, size), Image.LANCZOS)
    out = os.path.join(web_icons, name)
    resized.save(out, 'PNG', optimize=True)
    fsize = os.path.getsize(out)
    print(f'Saved {name} ({fsize} bytes)')

# Generate favicon (32x32)
favicon = img.resize((32, 32), Image.LANCZOS)
fav_path = os.path.join(web_root, 'favicon.png')
favicon.save(fav_path, 'PNG', optimize=True)
fsize = os.path.getsize(fav_path)
print(f'Saved favicon.png ({fsize} bytes)')

# Replace assets/icons too
for size, name in [(512, 'Icon-512.png'), (1024, 'Icon-1024.png')]:
    resized = img.resize((size, size), Image.LANCZOS)
    out = os.path.join(assets_icons, name)
    resized.save(out, 'PNG', optimize=True)
    fsize = os.path.getsize(out)
    print(f'Saved {name} ({fsize} bytes)')

# Also save 1024 jpg version
resized_1024 = img.resize((1024, 1024), Image.LANCZOS)
rgb = Image.new('RGB', resized_1024.size, (3, 8, 16))  # dark bg matching DFC theme
rgb.paste(resized_1024, mask=resized_1024.split()[3])
jpg_path = os.path.join(assets_icons, 'Icon-1024.jpg')
rgb.save(jpg_path, 'JPEG', quality=95)
fsize = os.path.getsize(jpg_path)
print(f'Saved Icon-1024.jpg ({fsize} bytes)')

print('\nDone! All icons replaced with correct DFC hexagonal shield logo.')
