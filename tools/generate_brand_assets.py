"""
Generates every logo-derived asset from the master file design/logo-master.png.

    pip install pillow
    python tools/generate_brand_assets.py

Outputs (all committed, so this only needs re-running when the logo changes):
  assets/brand/logo.png                          in-app logo (tight crop, 900 px wide)
  assets/brand/play_store_icon_512.png           Google Play listing icon
  android/app/src/main/res/mipmap-*/            legacy + adaptive + monochrome launcher icons
  android/app/src/main/res/mipmap-anydpi-v26/   adaptive icon definition
  android/app/src/main/res/drawable-*dpi/splash_logo.png   native splash artwork
  android/app/src/main/res/values/colors.xml    icon + splash background colour
  web/icons/*, web/favicon.png                   web / PWA icons
"""
from pathlib import Path
from PIL import Image, ImageChops, ImageDraw

ROOT = Path(__file__).resolve().parent.parent
MASTER = ROOT / "design" / "logo-master.png"
RES = ROOT / "android" / "app" / "src" / "main" / "res"
BG = (255, 255, 255, 255)

master = Image.open(MASTER).convert("RGBA")
logo = master.crop(master.getchannel("A").getbbox())          # tight crop, transparent corners
ASPECT = logo.width / logo.height


def fit_width(img: Image.Image, w: int) -> Image.Image:
    return img.resize((w, round(w / (img.width / img.height))), Image.LANCZOS)


def on_canvas(size: int, width_frac: float, bg=None, radius_frac: float = 0.0, source=None) -> Image.Image:
    """Logo centred on a square canvas. width_frac = logo width / canvas size."""
    src = source if source is not None else logo
    canvas = Image.new("RGBA", (size, size), bg if bg else (0, 0, 0, 0))
    if bg and radius_frac:
        mask = Image.new("L", (size, size), 0)
        ImageDraw.Draw(mask).rounded_rectangle((0, 0, size - 1, size - 1), radius=int(size * radius_frac), fill=255)
        canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))
        canvas.paste(Image.new("RGBA", (size, size), bg), (0, 0), mask)
    l = fit_width(src, round(size * width_frac))
    canvas.alpha_composite(l, ((size - l.width) // 2, (size - l.height) // 2))
    return canvas


def save(img: Image.Image, path: Path):
    path.parent.mkdir(parents=True, exist_ok=True)
    img.save(path, optimize=True)
    print("  wrote", path.relative_to(ROOT), img.size)


# ── in-app logo ────────────────────────────────────────────────────────────────
save(fit_width(logo, 900), ROOT / "assets" / "brand" / "logo.png")

# ── Android launcher icons ─────────────────────────────────────────────────────
DENSITY = {"mdpi": 1, "hdpi": 1.5, "xhdpi": 2, "xxhdpi": 3, "xxxhdpi": 4}

def _themed_mono(src: Image.Image) -> Image.Image:
    """Single-colour version for Android 13 themed icons: the H silhouette at ~40 % strength,
    with the darker parts of the scene (mountains, tree, tower shadows, road) at full strength,
    so the system tint keeps the illustration readable instead of a flat blob."""
    r, g, b, a = src.split()
    lum = Image.merge("RGB", (r, g, b)).convert("L")

    def detail(v: int) -> int:                     # dark -> 255, light -> 0 (soft edge 0.30..0.62)
        t = min(1.0, max(0.0, (158 - v) / (158 - 77)))
        return round(t * t * (3 - 2 * t) * 255)

    dark = lum.point(detail)
    base = a.point(lambda v: round(v * 0.40))
    alpha = ImageChops.lighter(ImageChops.multiply(dark, a), base)
    out = Image.new("RGBA", src.size, (0, 0, 0, 0))
    out.putalpha(alpha)
    return out


silhouette = _themed_mono(logo)

for name, scale in DENSITY.items():
    d = RES / f"mipmap-{name}"
    # legacy (API < 26): white rounded square, logo at 80 %
    save(on_canvas(round(48 * scale), 0.80, bg=BG, radius_frac=0.22), d / "ic_launcher.png")
    # adaptive layers are 108 dp; the logo stays inside the 66 dp safe circle (62 % width)
    save(on_canvas(round(108 * scale), 0.62), d / "ic_launcher_foreground.png")
    save(on_canvas(round(108 * scale), 0.62, source=silhouette), d / "ic_launcher_monochrome.png")
    # native splash artwork: 240 dp square, logo 134 dp wide (matches the Flutter splash)
    # Deliberately blank: the Flutter opening animation draws the logo as lines on white, so the native
    # splash must not already show it. (Android 12+ requires an icon to exist; a transparent one is fine.)
    save(Image.new("RGBA", (round(240 * scale), round(240 * scale)), (0, 0, 0, 0)), RES / f"drawable-{name}" / "splash_logo.png")

(RES / "mipmap-anydpi-v26").mkdir(parents=True, exist_ok=True)
(RES / "mipmap-anydpi-v26" / "ic_launcher.xml").write_text(
    '<?xml version="1.0" encoding="utf-8"?>\n'
    '<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">\n'
    '    <background android:drawable="@color/ic_launcher_background"/>\n'
    '    <foreground android:drawable="@mipmap/ic_launcher_foreground"/>\n'
    '    <monochrome android:drawable="@mipmap/ic_launcher_monochrome"/>\n'
    "</adaptive-icon>\n",
    encoding="utf-8",
)
(RES / "values" / "colors.xml").write_text(
    '<?xml version="1.0" encoding="utf-8"?>\n'
    "<resources>\n"
    '    <color name="ic_launcher_background">#FFFFFF</color>\n'
    '    <color name="splash_background">#FFFFFF</color>\n'
    "</resources>\n",
    encoding="utf-8",
)

# ── Play Store + web ───────────────────────────────────────────────────────────
save(on_canvas(512, 0.78, bg=BG), ROOT / "assets" / "brand" / "play_store_icon_512.png")
web = ROOT / "web"
save(on_canvas(192, 0.80, bg=BG, radius_frac=0.22), web / "icons" / "Icon-192.png")
save(on_canvas(512, 0.80, bg=BG, radius_frac=0.22), web / "icons" / "Icon-512.png")
save(on_canvas(192, 0.62, bg=BG), web / "icons" / "Icon-maskable-192.png")
save(on_canvas(512, 0.62, bg=BG), web / "icons" / "Icon-maskable-512.png")
save(on_canvas(64, 0.86, bg=BG, radius_frac=0.2), web / "favicon.png")

# ── partner marks (already transparent PNGs; just crop + size) ────────────────
for src_name, out_name, out_w in (("qenbel-wordmark-master.png", "qenbel_wordmark.png", 700), ("qenshar-master.png", "qenshar.png", 640)):
    m = Image.open(ROOT / "design" / src_name).convert("RGBA")
    a = m.getchannel("A").point(lambda v: 255 if v > 40 else 0)
    m = m.crop(a.getbbox())
    save(fit_width(m, out_w), ROOT / "assets" / "brand" / out_name)

# ── vector outline of the H logo, for the line-drawing intro ──────────────────
def trace_outline():
    import numpy as np
    from skimage import measure

    small = fit_width(logo, 460)
    alpha = np.array(small.getchannel("A"), dtype=float) / 255.0
    padded = np.pad(alpha, 2)                       # so contours close at the image border
    contours = measure.find_contours(padded, 0.5)
    w, h = small.size
    polys = []
    for c in contours:
        if len(c) < 60:                             # ignore specks
            continue
        c = measure.approximate_polygon(c, tolerance=0.6)
        pts = []
        for (r, col) in c:
            pts.append(round((col - 2) / w, 4))
            pts.append(round((r - 2) / h, 4))
        polys.append(pts)
    polys.sort(key=len, reverse=True)
    out = ROOT / "lib" / "core" / "brand" / "logo_outline.dart"
    NL = chr(10)
    body = ("," + NL).join("  [" + ", ".join(str(v) for v in p) + "]" for p in polys)
    out.write_text(
        "// GENERATED by tools/generate_brand_assets.py - do not edit." + NL
        + "// Outline of the MyHarur logo as closed polylines in unit coordinates (x, y pairs, 0..1)," + NL
        + "// used for the line-drawing effect in the opening animation." + NL
        + f"const double kLogoOutlineAspect = {w / h:.5f}; // width / height" + NL
        + "const List<List<double>> kLogoOutline = [" + NL + body + "," + NL + "];" + NL,
        encoding="utf-8",
    )
    print("  wrote lib/core/brand/logo_outline.dart:", len(polys), "contours,", sum(len(p) // 2 for p in polys), "points")


trace_outline()

# ── preview sheet (not shipped): icon shapes as launchers will mask them ───────
sheet = Image.new("RGBA", (5 * 220 + 20, 260), (236, 238, 245, 255))
fg = on_canvas(432, 0.62)
x = 20
for shape in ("circle", "squircle", "square", "legacy", "themed"):
    tile = Image.new("RGBA", (432, 432), BG if shape != "themed" else (30, 32, 40, 255))
    tile.alpha_composite(fg if shape != "themed" else on_canvas(432, 0.62, source=silhouette.point(lambda v: v)))
    if shape == "themed":
        tint = Image.new("RGBA", (432, 432), (170, 200, 255, 255))
        tile = Image.new("RGBA", (432, 432), (30, 32, 40, 255))
        tile.paste(tint, (0, 0), on_canvas(432, 0.62, source=silhouette).getchannel("A"))
    if shape == "legacy":
        tile = on_canvas(432, 0.80, bg=BG, radius_frac=0.22)
    mask = Image.new("L", (432, 432), 0)
    dr = ImageDraw.Draw(mask)
    if shape == "circle":
        dr.ellipse((36, 36, 395, 395), fill=255)
    elif shape in ("squircle", "themed"):
        dr.rounded_rectangle((36, 36, 395, 395), radius=110, fill=255)
    elif shape == "square":
        dr.rounded_rectangle((36, 36, 395, 395), radius=24, fill=255)
    else:
        dr.rectangle((0, 0, 431, 431), fill=255)
    tile = tile.resize((200, 200), Image.LANCZOS)
    mask = mask.resize((200, 200), Image.LANCZOS)
    sheet.paste(tile, (x, 30), mask)
    x += 220
sheet.convert("RGB").save(ROOT / "design" / "icon-preview.png")
print("  wrote design/icon-preview.png (preview only)")
