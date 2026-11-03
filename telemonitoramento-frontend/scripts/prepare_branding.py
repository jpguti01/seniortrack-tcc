"""Prepare platform assets from the supplied artwork, without redrawing it.

Run from any directory: python scripts/prepare_branding.py
Requires Pillow. The originals in assets/branding/source remain unchanged.
"""
from pathlib import Path
import math
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
BRAND = ROOT / 'assets' / 'branding'


def content_bounds(image):
    rgb = image.convert('RGB')
    mask = Image.new('L', image.size)
    pixels = rgb.get_flattened_data() if hasattr(rgb, 'get_flattened_data') else rgb.getdata()
    mask.putdata([255 if min(pixel) < 215 and max(pixel) - min(pixel) > 30 else 0
                  for pixel in pixels])
    bounds = mask.getbbox()
    if bounds is None:
        raise ValueError('No artwork found in the source image')
    return bounds


def square_crop(image, bounds, maskable=False):
    x0, y0, x1, y1 = bounds
    width, height = x1 - x0, y1 - y0
    # Maskable artwork stays within the central safe circle.
    side = math.ceil(math.hypot(width, height) / .76 if maskable else max(width, height) / .84)
    cx, cy = (x0 + x1) / 2, (y0 + y1) / 2
    left = max(0, min(round(cx - side / 2), image.width - side))
    top = max(0, min(round(cy - side / 2), image.height - side))
    return image.crop((left, top, left + side, top + side))


def save_size(image, path, size):
    path.parent.mkdir(parents=True, exist_ok=True)
    image.resize((size, size), Image.Resampling.LANCZOS).save(path, optimize=True)


def main():
    logo = Image.open(BRAND / 'source' / 'logo.png').convert('RGB')
    emblem = Image.open(BRAND / 'source' / 'emblem.png').convert('RGB')
    x0, y0, x1, y1 = content_bounds(logo)
    logo.crop((max(0, x0 - 32), max(0, y0 - 32),
               min(logo.width, x1 + 32), min(logo.height, y1 + 32))).save(BRAND / 'logo.png', optimize=True)
    bounds = content_bounds(emblem)
    regular = square_crop(emblem, bounds)
    maskable = square_crop(emblem, bounds, maskable=True)
    save_size(regular, BRAND / 'emblem.png', 256)
    web = ROOT / 'web'
    save_size(regular, web / 'favicon.png', 64)
    save_size(regular, web / 'favicon-seniortrack.png', 64)
    regular.save(web / 'favicon.ico', format='ICO', sizes=[(16, 16), (32, 32), (48, 48)])
    save_size(regular, web / 'icons' / 'apple-touch-icon.png', 180)
    for size in (192, 512):
        save_size(regular, web / 'icons' / f'seniortrack-{size}.png', size)
        save_size(maskable, web / 'icons' / f'seniortrack-maskable-{size}.png', size)
    for density, size in {'mdpi': 48, 'hdpi': 72, 'xhdpi': 96, 'xxhdpi': 144, 'xxxhdpi': 192}.items():
        save_size(maskable, ROOT / 'android' / 'app' / 'src' / 'main' / 'res' /
                  f'mipmap-{density}' / 'ic_launcher.png', size)
    print('SeniorTrack branding assets prepared.')


if __name__ == '__main__':
    main()
