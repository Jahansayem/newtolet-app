from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageChops, ImageDraw, ImageFilter


SIZE = 1024
RADIUS = 232
ROOT = Path(__file__).resolve().parents[1]
ICONS_DIR = ROOT / "assets" / "icons"


def mix_channel(a: int, b: int, t: float) -> int:
    return round(a + (b - a) * t)


def mix_color(a: tuple[int, int, int], b: tuple[int, int, int], t: float) -> tuple[int, int, int]:
    return tuple(mix_channel(x, y, t) for x, y in zip(a, b))


def draw_symbol(
    canvas: Image.Image,
    *,
    stroke: int,
    color: tuple[int, int, int, int],
    shadow: bool,
) -> None:
    base = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(base)

    roof = [(258, 414), (512, 226), (766, 414)]
    left_wall = [(336, 414), (336, 744)]
    right_wall = [(688, 414), (688, 744)]
    diagonal = [(336, 744), (688, 414)]

    for points in (roof, left_wall, right_wall, diagonal):
        draw.line(points, fill=color, width=stroke, joint="curve")

    # Cut a clean doorway gap so the house silhouette stays legible at small sizes.
    door_gap = Image.new("L", canvas.size, 0)
    gap_draw = ImageDraw.Draw(door_gap)
    gap_draw.rounded_rectangle((454, 560, 570, 760), radius=46, fill=255)
    alpha = base.getchannel("A")
    alpha = ImageChops.subtract(alpha, door_gap)
    base.putalpha(alpha)

    if shadow:
        shadow_layer = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
        shadow_layer.paste(base, (0, 20))
        shadow_layer = shadow_layer.filter(ImageFilter.GaussianBlur(22))
        shadow_tint = Image.new("RGBA", canvas.size, (6, 45, 24, 96))
        shadow_layer = ImageChops.multiply(shadow_layer, shadow_tint)
        canvas.alpha_composite(shadow_layer)

    canvas.alpha_composite(base)


def build_background() -> Image.Image:
    image = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    pixels = image.load()

    top = (110, 205, 136)
    mid = (39, 145, 88)
    bottom = (15, 80, 47)

    for y in range(SIZE):
        for x in range(SIZE):
            diag = (x * 0.38 + y * 0.92) / ((SIZE - 1) * 1.30)
            diag = max(0.0, min(1.0, diag))
            if diag < 0.55:
                color = mix_color(top, mid, diag / 0.55)
            else:
                color = mix_color(mid, bottom, (diag - 0.55) / 0.45)
            pixels[x, y] = (*color, 255)

    highlight = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    highlight_draw = ImageDraw.Draw(highlight)
    highlight_draw.ellipse((128, 72, 760, 650), fill=(255, 255, 255, 82))
    highlight_draw.ellipse((560, 598, 952, 972), fill=(8, 48, 24, 70))
    highlight = highlight.filter(ImageFilter.GaussianBlur(42))
    image.alpha_composite(highlight)

    mask = Image.new("L", (SIZE, SIZE), 0)
    mask_draw = ImageDraw.Draw(mask)
    mask_draw.rounded_rectangle((0, 0, SIZE - 1, SIZE - 1), radius=RADIUS, fill=255)
    image.putalpha(mask)
    return image


def write_svg_files() -> None:
    full_svg = """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1024 1024" fill="none">
  <defs>
    <linearGradient id="bg" x1="132" y1="98" x2="854" y2="932" gradientUnits="userSpaceOnUse">
      <stop stop-color="#6ECD88"/>
      <stop offset="0.56" stop-color="#279158"/>
      <stop offset="1" stop-color="#0F502F"/>
    </linearGradient>
    <filter id="shadow" x="188" y="170" width="654" height="710" filterUnits="userSpaceOnUse" color-interpolation-filters="sRGB">
      <feOffset dy="20"/>
      <feGaussianBlur stdDeviation="22"/>
      <feColorMatrix type="matrix" values="0 0 0 0 0.0235 0 0 0 0 0.1764 0 0 0 0 0.0941 0 0 0 0.36 0"/>
    </filter>
  </defs>
  <rect width="1024" height="1024" rx="232" fill="url(#bg)"/>
  <circle cx="418" cy="278" r="268" fill="white" fill-opacity="0.16"/>
  <circle cx="760" cy="786" r="178" fill="#083019" fill-opacity="0.22"/>
  <g filter="url(#shadow)">
    <path d="M258 414L512 226L766 414M336 414V744M688 414V744M336 744L688 414" stroke="#F7FFF8" stroke-width="92" stroke-linecap="round" stroke-linejoin="round"/>
    <path d="M454 560H570V760H454V560Z" fill="#279158"/>
  </g>
  <path d="M258 414L512 226L766 414M336 414V744M688 414V744M336 744L688 414" stroke="#F7FFF8" stroke-width="92" stroke-linecap="round" stroke-linejoin="round"/>
  <path d="M454 560H570V760H454V560Z" fill="#279158"/>
</svg>
"""

    foreground_svg = """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1024 1024" fill="none">
  <path d="M258 414L512 226L766 414M336 414V744M688 414V744M336 744L688 414" stroke="#F7FFF8" stroke-width="92" stroke-linecap="round" stroke-linejoin="round"/>
  <path d="M454 560H570V760H454V560Z" fill="none"/>
</svg>
"""

    (ICONS_DIR / "newtolet_app_icon.svg").write_text(full_svg, encoding="utf-8")
    (ICONS_DIR / "newtolet_app_icon_foreground.svg").write_text(
        foreground_svg,
        encoding="utf-8",
    )


def main() -> None:
    ICONS_DIR.mkdir(parents=True, exist_ok=True)

    full_icon = build_background()
    draw_symbol(full_icon, stroke=92, color=(247, 255, 248, 255), shadow=True)
    full_icon.save(ICONS_DIR / "newtolet_app_icon.png")

    foreground = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    draw_symbol(foreground, stroke=92, color=(247, 255, 248, 255), shadow=False)
    foreground.save(ICONS_DIR / "newtolet_app_icon_foreground.png")

    write_svg_files()


if __name__ == "__main__":
    main()
