"""
Resizes the master logo to every platform icon size.

Workflow:
  1. Edit  assets/images/app_icon.png  in your image editor (1024×1024 recommended).
  2. Run   python tools/generate_icons.py

The script never overwrites the source file — only the platform icon files.

To regenerate the source PNG from the built-in drawing (overwrites source!):
    python tools/generate_icons.py --regen
"""

from __future__ import annotations
from PIL import Image, ImageDraw
import math, os, sys

ROOT   = os.path.normpath(os.path.join(os.path.dirname(__file__), ".."))
SOURCE = os.path.join(ROOT, "assets", "images", "app_icon.png")

# ── Built-in drawing (fallback / --regen) ────────────────────────────────────

DARK_PEACH  = (158,  65,  44)
LIGHT_PEACH = (198, 106,  82)
BG_TOP      = (255, 248, 246)
BG_BOT      = (255, 224, 210)
GLOW        = (255, 178, 148)


def _build_source(out_size: int = 1024) -> Image.Image:
    """Draw the Glow Protocol sun mark at out_size × out_size."""
    SS = 4
    S  = out_size * SS
    img = Image.new("RGBA", (S, S))
    d   = ImageDraw.Draw(img)
    cx = cy = S // 2

    for y in range(S):
        t = y / max(S - 1, 1)
        r = round(BG_TOP[0] + (BG_BOT[0] - BG_TOP[0]) * t)
        g = round(BG_TOP[1] + (BG_BOT[1] - BG_TOP[1]) * t)
        b = round(BG_TOP[2] + (BG_BOT[2] - BG_TOP[2]) * t)
        d.line([(0, y), (S - 1, y)], fill=(r, g, b, 255))

    sun_frac = 0.34
    outer_r  = S * sun_frac
    k        = outer_r / 13.6
    ring_r   = k * 6.2
    ring_sw  = max(2, round(k * 2.1))
    ray_sw   = max(2, round(k * 1.7))

    for i in range(8, 0, -1):
        alpha = round(i / 8 * 32)
        gr = round(outer_r * 0.88 + i * S * 0.014)
        d.ellipse([cx - gr, cy - gr, cx + gr, cy + gr],
                  fill=GLOW + (alpha,))

    d.ellipse([cx - ring_r, cy - ring_r, cx + ring_r, cy + ring_r],
              outline=DARK_PEACH + (255,), width=ring_sw)

    for i in range(12):
        angle   = math.radians(-90 + i * 30)
        is_long = (i % 2 == 0)
        r1  = k * (9.2 if is_long else 9.5)
        r2  = k * (13.6 if is_long else 12.2)
        col = DARK_PEACH + (255,) if is_long else LIGHT_PEACH + (255,)
        x1  = cx + round(r1 * math.cos(angle))
        y1  = cy + round(r1 * math.sin(angle))
        x2  = cx + round(r2 * math.cos(angle))
        y2  = cy + round(r2 * math.sin(angle))
        hw  = max(1, ray_sw // 2)
        d.line([(x1, y1), (x2, y2)], fill=col, width=ray_sw)
        d.ellipse([x1 - hw, y1 - hw, x1 + hw, y1 + hw], fill=col)
        d.ellipse([x2 - hw, y2 - hw, x2 + hw, y2 + hw], fill=col)

    return img.resize((out_size, out_size), Image.LANCZOS)


# ── Resize helpers ───────────────────────────────────────────────────────────

def _resize(master: Image.Image, px: int) -> Image.Image:
    return master.resize((px, px), Image.LANCZOS)


def _maskable(master: Image.Image, px: int) -> Image.Image:
    """Place the icon centred in an 80 % safe zone on the same background."""
    safe   = round(px * 0.76)
    canvas = _resize(master, px)          # background fill from gradient
    logo   = _resize(master, safe).convert("RGBA")
    offset = (px - safe) // 2
    canvas.paste(logo, (offset, offset), logo)
    return canvas


def _save(img: Image.Image, *parts: str) -> None:
    path = os.path.join(ROOT, *parts)
    img.save(path)
    print(f"  {os.path.relpath(path, ROOT)}")


# ── Main ─────────────────────────────────────────────────────────────────────

def main() -> None:
    regen = "--regen" in sys.argv

    if regen:
        print("Regenerating source icon …")
        os.makedirs(os.path.dirname(SOURCE), exist_ok=True)
        master = _build_source(1024)
        master.save(SOURCE)
        print(f"  {os.path.relpath(SOURCE, ROOT)}  ← source updated\n")
    elif not os.path.exists(SOURCE):
        print(f"Source not found: {SOURCE}")
        print("Run with --regen to create it, or drop your own PNG there.")
        sys.exit(1)
    else:
        master = Image.open(SOURCE).convert("RGBA")
        w, h   = master.size
        if w != h:
            print(f"WARNING: source is {w}×{h}, expected square.")
        print(f"Source: {os.path.relpath(SOURCE, ROOT)}  ({w}×{h})\n")

    print("Android:")
    for density, px in [("mdpi", 48), ("hdpi", 72), ("xhdpi", 96),
                         ("xxhdpi", 144), ("xxxhdpi", 192)]:
        _save(_resize(master, px),
              "android", "app", "src", "main", "res",
              f"mipmap-{density}", "ic_launcher.png")

    print("Web:")
    for px in (192, 512):
        _save(_resize(master, px),  "web", "icons", f"Icon-{px}.png")
        _save(_maskable(master, px), "web", "icons", f"Icon-maskable-{px}.png")
    _save(_resize(master, 32), "web", "favicon.png")

    print("iOS:")
    ios = ("ios", "Runner", "Assets.xcassets", "AppIcon.appiconset")
    for fname, px in [
        ("Icon-App-20x20@1x.png",      20), ("Icon-App-20x20@2x.png",      40),
        ("Icon-App-20x20@3x.png",      60), ("Icon-App-29x29@1x.png",      29),
        ("Icon-App-29x29@2x.png",      58), ("Icon-App-29x29@3x.png",      87),
        ("Icon-App-40x40@1x.png",      40), ("Icon-App-40x40@2x.png",      80),
        ("Icon-App-40x40@3x.png",     120), ("Icon-App-60x60@2x.png",     120),
        ("Icon-App-60x60@3x.png",     180), ("Icon-App-76x76@1x.png",      76),
        ("Icon-App-76x76@2x.png",     152), ("Icon-App-83.5x83.5@2x.png", 167),
        ("Icon-App-1024x1024@1x.png", 1024),
    ]:
        _save(_resize(master, px), *ios, fname)

    print("macOS:")
    macos = ("macos", "Runner", "Assets.xcassets", "AppIcon.appiconset")
    for fname, px in [
        ("app_icon_16.png", 16), ("app_icon_32.png", 32), ("app_icon_64.png", 64),
        ("app_icon_128.png", 128), ("app_icon_256.png", 256),
        ("app_icon_512.png", 512), ("app_icon_1024.png", 1024),
    ]:
        _save(_resize(master, px), *macos, fname)

    print("Windows:")
    ico_path = os.path.join(ROOT, "windows", "runner", "resources", "app_icon.ico")
    sizes    = [16, 32, 48, 64, 128, 256]
    imgs     = [_resize(master, s).convert("RGBA") for s in sizes]
    imgs[0].save(ico_path, format="ICO",
                 append_images=imgs[1:],
                 sizes=[(s, s) for s in sizes])
    print(f"  windows/runner/resources/app_icon.ico")

    print("\nDone.")


if __name__ == "__main__":
    main()
