"""
Generates all platform app-icon PNGs from the "Glow Protocol" sun mark.

Design: hollow ring + 12 alternating long/short pill rays, two-tone peach.
Matches the LeafLogo component in doc/design-reference/screens/components.jsx.

Usage:
    python tools/generate_icons.py
"""

from __future__ import annotations
from PIL import Image, ImageDraw
import math, os

# ── Radiant Dew colours ──────────────────────────────────────────────────────
DARK_PEACH  = (158,  65,  44)   # #9e412c  ring + long rays
LIGHT_PEACH = (198, 106,  82)   # #c66a52  short rays
BG_TOP      = (255, 248, 246)   # #fff8f6  cream
BG_BOT      = (255, 224, 210)   # warm peach
GLOW        = (255, 178, 148)   # soft ambient glow colour

ROOT = os.path.normpath(os.path.join(os.path.dirname(__file__), ".."))


# ── Drawing ──────────────────────────────────────────────────────────────────

def _draw_icon(S: int, sun_frac: float) -> Image.Image:
    """
    Draw the sun icon at S×S pixels (before downsampling).
    sun_frac: fraction of S that the outer ray tips reach (radius).
    """
    img = Image.new("RGBA", (S, S))
    d   = ImageDraw.Draw(img)
    cx = cy = S // 2

    # Vertical gradient background
    for y in range(S):
        t = y / max(S - 1, 1)
        r = round(BG_TOP[0] + (BG_BOT[0] - BG_TOP[0]) * t)
        g = round(BG_TOP[1] + (BG_BOT[1] - BG_TOP[1]) * t)
        b = round(BG_TOP[2] + (BG_BOT[2] - BG_TOP[2]) * t)
        d.line([(0, y), (S - 1, y)], fill=(r, g, b, 255))

    # Sun geometry  (original viewBox units: ring r=6.2, long ray r2=13.6)
    outer_r = S * sun_frac          # radius of outer ray tip in pixels
    k       = outer_r / 13.6        # scale factor

    ring_r  = k * 6.2
    ring_sw = max(2, round(k * 2.1))
    ray_sw  = max(2, round(k * 1.7))

    # Soft ambient glow
    for i in range(8, 0, -1):
        alpha = round(i / 8 * 32)
        gr = round(outer_r * 0.88 + i * S * 0.014)
        d.ellipse([cx - gr, cy - gr, cx + gr, cy + gr],
                  fill=GLOW + (alpha,))

    # Ring (annulus via ellipse outline)
    d.ellipse(
        [cx - ring_r, cy - ring_r, cx + ring_r, cy + ring_r],
        outline=DARK_PEACH + (255,),
        width=ring_sw,
    )

    # 12 rays — alternating long/short, dark/light
    for i in range(12):
        angle   = math.radians(-90 + i * 30)
        is_long = (i % 2 == 0)
        r1 = k * (9.2 if is_long else 9.5)
        r2 = k * (13.6 if is_long else 12.2)
        col = DARK_PEACH + (255,) if is_long else LIGHT_PEACH + (255,)

        x1 = cx + round(r1 * math.cos(angle))
        y1 = cy + round(r1 * math.sin(angle))
        x2 = cx + round(r2 * math.cos(angle))
        y2 = cy + round(r2 * math.sin(angle))
        hw = max(1, ray_sw // 2)

        d.line([(x1, y1), (x2, y2)], fill=col, width=ray_sw)
        d.ellipse([x1 - hw, y1 - hw, x1 + hw, y1 + hw], fill=col)
        d.ellipse([x2 - hw, y2 - hw, x2 + hw, y2 + hw], fill=col)

    return img


def create_icon(out_size: int, sun_frac: float = 0.34) -> Image.Image:
    """
    Render at 4× for anti-aliasing, then downsample.
    sun_frac=0.34 means the outer tips reach 34% of the half-width.
    """
    SS = 4
    raw = _draw_icon(out_size * SS, sun_frac)
    return raw.resize((out_size, out_size), Image.LANCZOS)


def create_maskable(out_size: int) -> Image.Image:
    """Maskable icon: artwork fits within the 80% safe-zone circle."""
    return create_icon(out_size, sun_frac=0.34 * 0.76)


# ── File helpers ─────────────────────────────────────────────────────────────

def save(img: Image.Image, *path_parts: str) -> None:
    path = os.path.join(ROOT, *path_parts)
    img.save(path)
    rel = os.path.relpath(path, ROOT)
    print(f"  {rel}")


# ── Main ─────────────────────────────────────────────────────────────────────

def main() -> None:
    print("Generating app icons …\n")

    master = create_icon(1024)

    # Master source copy
    os.makedirs(os.path.join(ROOT, "assets", "images"), exist_ok=True)
    save(master, "assets", "images", "app_icon.png")

    # ── Android mipmap ──────────────────────────────────────────────────────
    print("Android:")
    for density, px in [("mdpi", 48), ("hdpi", 72), ("xhdpi", 96),
                        ("xxhdpi", 144), ("xxxhdpi", 192)]:
        icon = master.resize((px, px), Image.LANCZOS)
        save(icon, "android", "app", "src", "main", "res",
             f"mipmap-{density}", "ic_launcher.png")

    # ── Web / PWA ────────────────────────────────────────────────────────────
    print("Web:")
    for px in (192, 512):
        save(master.resize((px, px), Image.LANCZOS),
             "web", "icons", f"Icon-{px}.png")
        save(create_maskable(px),
             "web", "icons", f"Icon-maskable-{px}.png")
    save(master.resize((32, 32), Image.LANCZOS), "web", "favicon.png")

    # ── iOS ──────────────────────────────────────────────────────────────────
    print("iOS:")
    ios_dir = ("ios", "Runner", "Assets.xcassets", "AppIcon.appiconset")
    ios_sizes = [
        ("Icon-App-20x20@1x.png",      20),
        ("Icon-App-20x20@2x.png",      40),
        ("Icon-App-20x20@3x.png",      60),
        ("Icon-App-29x29@1x.png",      29),
        ("Icon-App-29x29@2x.png",      58),
        ("Icon-App-29x29@3x.png",      87),
        ("Icon-App-40x40@1x.png",      40),
        ("Icon-App-40x40@2x.png",      80),
        ("Icon-App-40x40@3x.png",     120),
        ("Icon-App-60x60@2x.png",     120),
        ("Icon-App-60x60@3x.png",     180),
        ("Icon-App-76x76@1x.png",      76),
        ("Icon-App-76x76@2x.png",     152),
        ("Icon-App-83.5x83.5@2x.png", 167),
        ("Icon-App-1024x1024@1x.png", 1024),
    ]
    for fname, px in ios_sizes:
        save(master.resize((px, px), Image.LANCZOS), *ios_dir, fname)

    # ── macOS ────────────────────────────────────────────────────────────────
    print("macOS:")
    macos_dir = ("macos", "Runner", "Assets.xcassets", "AppIcon.appiconset")
    macos_sizes = [
        ("app_icon_16.png",    16),
        ("app_icon_32.png",    32),
        ("app_icon_64.png",    64),
        ("app_icon_128.png",  128),
        ("app_icon_256.png",  256),
        ("app_icon_512.png",  512),
        ("app_icon_1024.png", 1024),
    ]
    for fname, px in macos_sizes:
        save(master.resize((px, px), Image.LANCZOS), *macos_dir, fname)

    # ── Windows ICO ──────────────────────────────────────────────────────────
    print("Windows:")
    ico_path = os.path.join(ROOT, "windows", "runner", "resources", "app_icon.ico")
    ico_sizes = [16, 32, 48, 64, 128, 256]
    base_ico = master.resize((ico_sizes[0], ico_sizes[0]), Image.LANCZOS).convert("RGBA")
    extra    = [master.resize((s, s), Image.LANCZOS).convert("RGBA") for s in ico_sizes[1:]]
    base_ico.save(ico_path, format="ICO",
                  append_images=extra,
                  sizes=[(s, s) for s in ico_sizes])
    print(f"  windows/runner/resources/app_icon.ico")

    print("\nDone — all icons generated.")


if __name__ == "__main__":
    main()
