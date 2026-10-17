"""Draws Level 1's world art: the salon cabinet tileset, the three room backgrounds and
the prop textures. Style rules: docs/art/l1_art_direction.md.

Everything is flat colour with a wobbly hand-drawn outline, like the character sheets:
  * gameplay things (tiles, props) use the dark ink line (INK, ~3 px at game size);
  * backgrounds use thinner lines tinted from the wall colour, low contrast, and never a
    long horizontal edge that could pass for a platform.
Shapes are drawn at SS x size and downscaled, which gives clean anti-aliased lines.
Output goes to assets/art/l1/ and assets/art/props/; rerun after changing anything here.
Run: python -I tools/art/make_l1_art.py
"""
import math
import random
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[2]
L1 = ROOT / "assets" / "art" / "l1"
PROPS = ROOT / "assets" / "art" / "props"

SS = 4  # supersampling factor
TILE = 32
INK = (43, 33, 64)

# Palette roles (see the art direction doc).
CABINET = (214, 176, 138)
CABINET_GROOVE = (190, 150, 112)
COUNTER = (250, 244, 232)
COUNTER_SHADE = (176, 140, 104)
INTERACT = (241, 196, 15)
EXIT = (46, 204, 113)
GEL = (155, 231, 216)
DYE = (142, 68, 173)
CHROME = (214, 220, 228)


def mix(a, b, t):
    return tuple(round(x + (y - x) * t) for x, y in zip(a, b))


# --- Wobbly lines -------------------------------------------------------------

def edge_wobble(rng: random.Random, amp: float):
    """f(t) for t in 0..1, zero at both ends: tiles stay seamless."""
    terms = [(k, rng.uniform(-1, 1) * amp / k ** 0.7) for k in (1, 2, 3)]
    return lambda t: sum(a * math.sin(k * math.pi * t) for k, a in terms)


def wobble_path(points, rng, amp=1.0, step=10.0, closed=False):
    """Subdivide a polyline and push each point sideways by smooth noise."""
    pts = list(points) + ([points[0]] if closed else [])
    out = []
    phase = rng.uniform(0, 100)
    dist = 0.0
    for (x0, y0), (x1, y1) in zip(pts, pts[1:]):
        length = math.hypot(x1 - x0, y1 - y0)
        n = max(1, int(length / step))
        nx, ny = (-(y1 - y0) / length, (x1 - x0) / length) if length else (0, 0)
        for i in range(n):
            t = i / n
            d = dist + t * length
            off = amp * (math.sin(d * 0.045 + phase) * 0.6 + math.sin(d * 0.13 + phase * 1.7) * 0.4)
            out.append((x0 + (x1 - x0) * t + nx * off, y0 + (y1 - y0) * t + ny * off))
        dist += length
    out.append(out[0] if closed else pts[-1])
    return out


def scaled(points, s=SS):
    return [(x * s, y * s) for x, y in points]


def stroke(draw, points, color, width, s=SS):
    draw.line(scaled(points, s), fill=color, width=round(width * s), joint="curve")
    r = width * s / 2
    for x, y in (points[0], points[-1]):
        draw.ellipse((x * s - r, y * s - r, x * s + r, y * s + r), fill=color)


def shape(draw, points, fill, line=None, width=3.0, rng=None, amp=1.0, s=SS):
    pts = wobble_path(points, rng, amp, closed=True) if rng else points + [points[0]]
    draw.polygon(scaled(pts, s), fill=fill)
    if line:
        stroke(draw, pts, line, width, s)


def ellipse_pts(cx, cy, rx, ry, n=36):
    return [(cx + rx * math.cos(2 * math.pi * i / n), cy + ry * math.sin(2 * math.pi * i / n)) for i in range(n)]


def rect_pts(x, y, w, h, r=0.0):
    if r <= 0:
        return [(x, y), (x + w, y), (x + w, y + h), (x, y + h)]
    pts = []
    for cx, cy, a0 in ((x + w - r, y + r, -90), (x + w - r, y + h - r, 0), (x + r, y + h - r, 90), (x + r, y + r, 180)):
        for i in range(7):
            a = math.radians(a0 + i * 15)
            pts.append((cx + r * math.cos(a), cy + r * math.sin(a)))
    return pts


def canvas(w, h, bg=(0, 0, 0, 0)):
    img = Image.new("RGBA", (w * SS, h * SS), bg)
    return img, ImageDraw.Draw(img)


def finish(img, w, h):
    return img.resize((w, h), Image.LANCZOS)


# --- Tiles --------------------------------------------------------------------
# Atlas 4 x 5 of 32 px tiles. Rows 0-3: solid tile for neighbour mask 0..15
# (bit 1 = solid above, 2 = right, 4 = below, 8 = left; col = mask % 4, row = mask / 4),
# drawn with an ink edge and rounded corners where it borders open air, and a countertop
# where its top is open. Row 4: three more fully-enclosed variants, then the one-way shelf.
N, E, S, W = 1, 2, 4, 8


def solid_tile(mask: int, variant: int) -> Image.Image:
    rng = random.Random(mask * 31 + variant * 7 + 5)
    img, d = canvas(TILE, TILE)
    open_n, open_e, open_s, open_w = (not mask & b for b in (N, E, S, W))
    wob = {side: edge_wobble(rng, 0.7) for side in "nesw"}
    inset = 0.9  # keeps the wobble inside the tile
    r = 5.0
    # Outline polygon, clockwise from the top-left corner.
    pts = []

    def corner(cx, cy, a0):
        for i in range(7):
            a = math.radians(a0 + i * 15)
            pts.append((cx + r * math.cos(a), cy + r * math.sin(a)))

    top_y = lambda x: inset + wob["n"](x / TILE) if open_n else 0.0
    bot_y = lambda x: TILE - inset - wob["s"](x / TILE) if open_s else TILE
    left_x = lambda y: inset + wob["w"](y / TILE) if open_w else 0.0
    right_x = lambda y: TILE - inset - wob["e"](y / TILE) if open_e else TILE

    if open_n and open_w:
        corner(inset + r, inset + r, 180)
    else:
        pts.append((left_x(0), top_y(0)))
    for i in range(1, 16):
        x = TILE * i / 16
        if (open_n and open_w and x < r + inset) or (open_n and open_e and x > TILE - r - inset):
            continue
        pts.append((x, top_y(x)))
    if open_n and open_e:
        corner(TILE - inset - r, inset + r, 270)
    else:
        pts.append((right_x(0), top_y(TILE)))
    for i in range(1, 16):
        y = TILE * i / 16
        if (open_e and open_n and y < r + inset) or (open_e and open_s and y > TILE - r - inset):
            continue
        pts.append((right_x(y), y))
    if open_s and open_e:
        corner(TILE - inset - r, TILE - inset - r, 0)
    else:
        pts.append((right_x(TILE), bot_y(TILE)))
    for i in range(15, 0, -1):
        x = TILE * i / 16
        if (open_s and open_e and x > TILE - r - inset) or (open_s and open_w and x < r + inset):
            continue
        pts.append((x, bot_y(x)))
    if open_s and open_w:
        corner(inset + r, TILE - inset - r, 90)
    else:
        pts.append((left_x(TILE), bot_y(0)))
    for i in range(15, 0, -1):
        y = TILE * i / 16
        if (open_w and open_s and y > TILE - r - inset) or (open_w and open_n and y < r + inset):
            continue
        pts.append((left_x(y), y))

    body = Image.new("RGBA", img.size, (0, 0, 0, 0))
    bd = ImageDraw.Draw(body)
    bd.rectangle((0, 0, TILE * SS, TILE * SS), fill=CABINET)
    # Panel grooves: the seam between cabinet doors, every tile, plus a knot or screw.
    bd.line((TILE * SS - 2, 0, TILE * SS - 2, TILE * SS), fill=CABINET_GROOVE, width=SS)
    if variant == 1:
        bd.ellipse(scaled([(13, 15), (17, 19)]), outline=CABINET_GROOVE, width=SS)
    elif variant == 2:
        for y in (8, 24):
            bd.ellipse(scaled([(5, y - 1), (7, y + 1)]), fill=CABINET_GROOVE)
    elif variant == 3:
        bd.arc(scaled([(9, 9), (21, 21)]), 200, 330, fill=CABINET_GROOVE, width=SS)
    if open_n:  # countertop slab
        slab = [(x, top_y(x)) for x in range(0, TILE + 1, 2)] + [(x, top_y(x) + 9) for x in range(TILE, -1, -2)]
        bd.polygon(scaled(slab), fill=COUNTER)
        stroke(bd, [(x, top_y(x) + 9.5) for x in range(0, TILE + 1, 2)], COUNTER_SHADE, 1.2)
    if open_s:  # shaded underside
        under = [(x, bot_y(x)) for x in range(0, TILE + 1, 2)] + [(x, bot_y(x) - 5) for x in range(TILE, -1, -2)]
        bd.polygon(scaled(under), fill=CABINET_GROOVE)

    mask_img = Image.new("L", img.size, 0)
    ImageDraw.Draw(mask_img).polygon(scaled(pts), fill=255)
    img.paste(body, (0, 0), mask_img)
    # Ink along the open edges only (shared edges stay seamless), 1.4 px inside the shape.
    ink = Image.new("RGBA", img.size, (0, 0, 0, 0))
    idr = ImageDraw.Draw(ink)
    k = 1.4
    lo = lambda open_side: inset + r if open_side else 0.0
    hi = lambda open_side: TILE - inset - r if open_side else TILE
    span = lambda a, b: [a + (b - a) * i / 16 for i in range(17)]
    lines = []
    if open_n:
        lines.append([(x, top_y(x) + k) for x in span(lo(open_w), hi(open_e))])
    if open_s:
        lines.append([(x, bot_y(x) - k) for x in span(lo(open_w), hi(open_e))])
    if open_w:
        lines.append([(left_x(y) + k, y) for y in span(lo(open_n), hi(open_s))])
    if open_e:
        lines.append([(right_x(y) - k, y) for y in span(lo(open_n), hi(open_s))])
    for a, b, cx, cy, a0 in ((open_n, open_w, inset + r, inset + r, 180), (open_n, open_e, TILE - inset - r, inset + r, 270),
                             (open_s, open_e, TILE - inset - r, TILE - inset - r, 0), (open_s, open_w, inset + r, TILE - inset - r, 90)):
        if a and b:
            lines.append([(cx + (r - k) * math.cos(math.radians(a0 + i * 10)), cy + (r - k) * math.sin(math.radians(a0 + i * 10)))
                          for i in range(10)])
    for line in lines:
        stroke(idr, line, INK, 3.0)
    ink_mask = Image.new("L", img.size, 0)
    ImageDraw.Draw(ink_mask).polygon(scaled(pts), fill=255)
    img.paste(ink, (0, 0), Image.composite(ink.getchannel("A"), Image.new("L", img.size, 0), ink_mask))
    return finish(img, TILE, TILE)


def shelf_tile() -> Image.Image:
    """One-way shelf: an 8 px plank on top (the collision lip), bracket below, open ends."""
    rng = random.Random(77)
    img, d = canvas(TILE, TILE)
    w = edge_wobble(rng, 0.5)
    top = [(x, 1.2 + w(x / TILE)) for x in range(0, TILE + 1, 2)]
    bottom = [(x, 7.0 - w(x / TILE) * 0.5) for x in range(TILE, -1, -2)]
    d.polygon(scaled(top + bottom), fill=COUNTER)
    stroke(d, top, INK, 2.4)
    stroke(d, list(reversed(bottom)), INK, 2.0)
    stroke(d, [(16, 8), (16, 16), (22, 9)], CABINET_GROOVE, 1.6)
    return finish(img, TILE, TILE)


def make_tiles() -> None:
    atlas = Image.new("RGBA", (TILE * 4, TILE * 5), (0, 0, 0, 0))
    for mask in range(16):
        atlas.alpha_composite(solid_tile(mask, 0), ((mask % 4) * TILE, (mask // 4) * TILE))
    for v in range(1, 4):
        atlas.alpha_composite(solid_tile(15, v), ((v - 1) * TILE, 4 * TILE))
    atlas.alpha_composite(shelf_tile(), (3 * TILE, 4 * TILE))
    atlas.save(L1 / "tiles_salon.png")


# --- Backgrounds ----------------------------------------------------------------

class Wall:
    """Helpers for one background: tinted lines and fills derived from the wall colour."""

    def __init__(self, color, seed, w=1280, h=720, s=2):
        self.color, self.w, self.h, self.s = color, w, h, s
        self.rng = random.Random(seed)
        self.img = Image.new("RGBA", (w * s, h * s), color + (255,))
        self.d = ImageDraw.Draw(self.img)
        self.line = mix(color, INK, 0.22)
        self.soft = mix(color, INK, 0.1)
        self.light = mix(color, (255, 255, 255), 0.45)
        self.shade = mix(color, INK, 0.05)

    def shape(self, pts, fill, line=True, width=2.0, amp=1.4):
        p = wobble_path(pts, self.rng, amp, step=14, closed=True)
        self.d.polygon(scaled(p, self.s), fill=fill)
        if line:
            stroke(self.d, p, self.line, width, self.s)

    def path(self, pts, color=None, width=2.0, amp=1.2):
        stroke(self.d, wobble_path(pts, self.rng, amp, step=14), color or self.line, width, self.s)

    def tint(self, rgb, t=0.25):
        """A reserved colour (pink, blue...) washed out into the wall, never saturated."""
        return mix(self.color, rgb, t)

    def save(self, name):
        self.img.resize((self.w, self.h), Image.LANCZOS).convert("RGB").save(L1 / name)


def mirror(wall, cx, top, w, h):
    wall.shape(rect_pts(cx - w / 2 - 10, top - 10, w + 20, h + 20, 22), wall.tint((176, 141, 87), 0.3))
    wall.shape(rect_pts(cx - w / 2, top, w, h, 16), wall.light)
    for i, (a, b) in enumerate(((0.22, 0.62), (0.4, 0.75))):
        wall.path([(cx - w / 2 + w * a, top + h * 0.8), (cx - w / 2 + w * b, top + h * 0.25)], wall.soft, 3.0 - i)


def lamp(wall, cx):
    wall.path([(cx, 32), (cx, 64)], wall.soft, 1.6)
    wall.shape([(cx - 18, 82), (cx + 18, 82), (cx + 8, 62), (cx - 8, 62)], wall.tint(INTERACT, 0.3))


def barber_pole(wall, x, top, h=104):
    wall.shape(rect_pts(x, top, 20, h, 8), wall.light)
    y = top + 10
    i = 0
    while y < top + h - 6:
        c = wall.tint((214, 48, 49) if i % 2 == 0 else (45, 108, 223), 0.25)
        wall.path([(x + 3, y + 8), (x + 17, y)], c, 4.0, amp=0.3)
        y += 14
        i += 1
    for yy in (top - 8, top + h):
        wall.shape(rect_pts(x - 3, yy, 26, 8, 3), wall.shade)


def hair_sketch(wall, cx, cy, twin):
    """Pinned-up doodle of a haircut (the shop's style menu)."""
    wall.shape(rect_pts(cx - 30, cy - 34, 60, 70, 4), wall.light, width=1.6)
    wall.shape([(cx - 6, cy - 40), (cx + 6, cy - 40), (cx + 4, cy - 30), (cx - 4, cy - 30)], wall.shade, line=False)
    hair = wall.tint((255, 95, 162) if twin else (58, 143, 214), 0.3)
    if twin:
        wall.shape(ellipse_pts(cx - 18, cy - 2, 9, 14), hair, width=1.4)
        wall.shape(ellipse_pts(cx + 18, cy - 2, 9, 14), hair, width=1.4)
    wall.shape(ellipse_pts(cx, cy + 4, 14, 14), wall.light, width=1.6)
    if twin:
        wall.shape(ellipse_pts(cx, cy - 8, 15, 8), hair, width=1.4)
    else:
        wall.shape([(cx - 16, cy - 2), (cx - 12, cy - 18), (cx + 4, cy - 22), (cx + 26, cy - 16), (cx + 8, cy - 6)], hair, width=1.4)
    for ex in (cx + 2, cx + 7):
        wall.path([(ex, cy + 1), (ex, cy + 7)], wall.line, 1.6, amp=0)


def stripes(wall, step=48, width=24):
    x = 0
    while x < wall.w:
        wall.d.rectangle((x * wall.s, 0, (x + width) * wall.s, wall.h * wall.s), fill=wall.shade)
        x += step


def bg_mirror() -> None:
    wall = Wall((243, 227, 211), 11)
    stripes(wall)
    for cx in (200, 620, 1080):
        lamp(wall, cx)
        mirror(wall, cx, 104, 110, 150)
    barber_pole(wall, 400, 120)
    barber_pole(wall, 850, 120)
    hair_sketch(wall, 160, 430, True)
    hair_sketch(wall, 300, 430, False)
    wall.save("bg_l1_01_mirror.png")


def bg_washing_basin() -> None:
    wall = Wall((214, 238, 242), 22)
    for x in range(0, wall.w, 40):  # square wall tiles
        wall.d.line((x * wall.s, 0, x * wall.s, wall.h * wall.s), fill=wall.shade, width=wall.s)
    for y in range(0, wall.h, 40):
        wall.d.line((0, y * wall.s, wall.w * wall.s, y * wall.s), fill=wall.shade, width=wall.s)
    for x in (110, 1180):  # water pipes down the wall
        wall.shape(rect_pts(x, 32, 16, 700), wall.tint(CHROME, 0.4), width=1.6)
        for y in (160, 420):
            wall.shape(rect_pts(x - 4, y, 24, 14, 3), wall.tint(CHROME, 0.6), width=1.4)
    for cx, length in ((330, 170), (560, 120), (930, 150)):  # shower heads on hoses
        pts = [(cx, 32)] + [(cx + 14 * math.sin(i * 0.9), 32 + i * length / 6) for i in range(1, 7)]
        wall.path(pts, wall.line, 3.0)
        end = pts[-1]
        wall.shape([(end[0] - 16, end[1]), (end[0] + 16, end[1]), (end[0] + 10, end[1] + 18), (end[0] - 10, end[1] + 18)],
                   wall.tint(CHROME, 0.5))
        for i in range(3):
            wall.path([(end[0] - 8 + i * 8, end[1] + 26), (end[0] - 10 + i * 10, end[1] + 44)], wall.soft, 1.6)
    for cx, cy, r in ((260, 330, 14), (300, 300, 8), (700, 260, 18), (760, 230, 9), (1010, 360, 12), (1060, 320, 7), (470, 380, 10)):
        wall.shape(ellipse_pts(cx, cy, r, r, 24), wall.light, width=1.6)
        wall.path([(cx - r * 0.5, cy - r * 0.2), (cx - r * 0.2, cy - r * 0.55)], (255, 255, 255), 1.6, amp=0)
    wall.save("bg_l1_02_washing_basin.png")


def bg_gel_curtain() -> None:
    wall = Wall((239, 224, 240), 33)
    rng = wall.rng
    for _ in range(90):  # faint swirl dots
        x, y = rng.uniform(0, 1280), rng.uniform(40, 700)
        wall.d.ellipse(((x - 3) * wall.s, (y - 3) * wall.s, (x + 3) * wall.s, (y + 3) * wall.s), fill=wall.shade)
    # Gel oozing from the ceiling, kept pale and round so it can't pass for spikes or
    # for the real (solid, mint) gel.
    ooze = wall.tint(GEL, 0.18)
    wall.shape([(0, 0), (1280, 0), (1280, 44), (0, 44)], ooze)
    for x in range(30, 1280, 70):
        length = rng.choice((10, 16, 26, 40))
        wall.shape(rect_pts(x - 7, 36, 14, length, 7), ooze)
    for cx, top, w, h in ((170, 120, 110, 190), (1040, 110, 120, 200)):  # giant gel tubs
        wall.shape(rect_pts(cx - w / 2, top, w, h, 18), wall.tint(GEL, 0.14))
        wall.shape(rect_pts(cx - w / 2 - 6, top - 16, w + 12, 22, 6), wall.tint((214, 48, 49), 0.18))
        wall.shape(rect_pts(cx - w / 2 + 16, top + 50, w - 32, 50, 6), wall.light, width=1.4)
    for cx in (420, 860):  # pump bottles
        wall.shape(rect_pts(cx - 30, 170, 60, 120, 14), wall.tint(DYE, 0.15))
        wall.shape(rect_pts(cx - 8, 140, 16, 30), wall.shade)
        wall.shape([(cx - 8, 140), (cx + 34, 140), (cx + 34, 150), (cx - 8, 150)], wall.shade)
    wall.save("bg_l1_03_gel_curtain.png")


# --- Props --------------------------------------------------------------------

def lever_frames() -> None:
    """Chair-pump handle, 48x48 per frame: off (handle back) | on (handle pushed over)."""
    strip = Image.new("RGBA", (96, 48), (0, 0, 0, 0))
    for i, on in enumerate((False, True)):
        rng = random.Random(3)
        img, d = canvas(48, 48)
        tip = (36, 12) if on else (12, 12)
        stroke(d, [(24, 34), tip], INK, 7)
        stroke(d, [(24, 34), tip], CHROME, 3.6)
        shape(d, ellipse_pts(*tip, 7, 7), INTERACT, INK, 2.6, rng, 0.3)
        shape(d, rect_pts(15, 28, 18, 12, 3), CHROME, INK, 2.6, rng, 0.4)
        shape(d, rect_pts(8, 38, 32, 9, 3), mix(CHROME, INK, 0.35), INK, 2.6, rng, 0.4)
        light = EXIT if on else (231, 76, 60)
        shape(d, ellipse_pts(24, 42.5, 2.6, 2.6, 12), light)
        strip.alpha_composite(finish(img, 48, 48), (i * 48, 0))
    strip.save(PROPS / "prop_lever.png")


def exit_door() -> None:
    """64x96 glass shop door in the exit green. The OPEN sign and arrival pips are code."""
    rng = random.Random(9)
    img, d = canvas(64, 96)
    frame = mix(EXIT, INK, 0.15)
    shape(d, rect_pts(2, 2, 60, 93, 6), frame, INK, 3, rng, 0.6)
    shape(d, rect_pts(9, 30, 46, 58, 4), (214, 238, 242), INK, 2.2, rng, 0.5)
    stroke(d, wobble_path([(18, 78), (34, 44)], rng, 0.4), (255, 255, 255), 3)
    stroke(d, wobble_path([(30, 80), (44, 52)], rng, 0.4), (255, 255, 255), 2)
    shape(d, ellipse_pts(50, 60, 3.2, 3.2, 12), INTERACT, INK, 1.6)
    finish(img, 64, 96).save(PROPS / "prop_exit.png")


def nine_slice(name, size, fill, line, decorate, amp=0.8, radius=8):
    """Square nine-slice source (margins set in code): ink border, tiling middle."""
    rng = random.Random(len(name))
    img, d = canvas(size, size)
    shape(d, rect_pts(1.5, 1.5, size - 3, size - 3, radius), fill, line, 3, rng, amp)
    decorate(d, rng)
    finish(img, size, size).save(PROPS / name)


def gel(d, rng):
    for x, y, r in ((18, 22, 4), (44, 40, 3), (28, 50, 2.5), (48, 16, 2)):
        shape(d, ellipse_pts(x, y, r, r, 16), mix(GEL, (255, 255, 255), 0.5), mix(GEL, INK, 0.35), 1.2)
    stroke(d, [(10, 12), (10, 36)], (255, 255, 255), 2.4)


def lift(d, rng):
    shape(d, rect_pts(2, 2, 60, 9, 3), CHROME, INK, 2.2, rng, 0.3)
    for x in (16, 32, 48):
        shape(d, ellipse_pts(x, 38, 2.4, 2.4, 12), mix(INTERACT, INK, 0.3))


def dye(d, rng):
    shape(d, [(0, 0), (64, 0), (64, 12)] + [(x, 12 + 2.5 * math.sin(x / 64 * 4 * math.pi)) for x in range(64, -1, -4)],
          mix(DYE, (255, 255, 255), 0.35))
    stroke(d, [(x, 12 + 2.5 * math.sin(x / 64 * 4 * math.pi)) for x in range(0, 65, 4)], mix(DYE, INK, 0.3), 1.6)
    for x, y in ((18, 34), (44, 46)):
        shape(d, ellipse_pts(x, y, 3, 3, 12), mix(DYE, (255, 255, 255), 0.25))


def main() -> None:
    L1.mkdir(parents=True, exist_ok=True)
    PROPS.mkdir(parents=True, exist_ok=True)
    make_tiles()
    bg_mirror()
    bg_washing_basin()
    bg_gel_curtain()
    lever_frames()
    exit_door()
    nine_slice("prop_gel.png", 64, GEL, INK, gel, radius=10)
    nine_slice("prop_lift.png", 64, (233, 196, 106), INK, lift, radius=6)
    # Dye fills its basin edge to edge: no outline on the sides, the basin rims are drawn in code.
    nine_slice("prop_dye.png", 64, DYE, None, dye, amp=0, radius=0)
    for f in sorted(list(L1.glob("*.png")) + list(PROPS.glob("*.png"))):
        print(f.relative_to(ROOT))


if __name__ == "__main__":
    main()
