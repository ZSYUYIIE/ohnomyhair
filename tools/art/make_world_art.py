"""Draws the world art for Levels 2-4 in the Level 1 doodle style, using make_l1_art.py's
helpers (wobbly outline, flat fills, supersampled then downscaled):
  * one cabinet tileset per level (same shapes as L1, its own wood or ceramic colours);
  * one painted wall per room (thin lines tinted from the wall colour, low contrast, and no
    long horizontal edge that could pass for a ledge);
  * the enemies and the props that were still drawn as code rectangles: clipper bot,
    scissors, scissor dispenser, barber bot, service bell, staff door and the barber's chair.
Text, lights, HP bars and other state cues stay in code. Style rules:
docs/art/l1_art_direction.md. Rerun after changing anything here.
Run: python -I tools/art/make_world_art.py
"""
import importlib.util
import math
import random
from pathlib import Path

from PIL import Image

_spec = importlib.util.spec_from_file_location("l1art", Path(__file__).with_name("make_l1_art.py"))
art = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(art)

ROOT, PROPS, TILE = art.ROOT, art.PROPS, art.TILE
INK, CHROME, INTERACT, EXIT = art.INK, art.CHROME, art.INTERACT, art.EXIT
shape, stroke, ellipse_pts, rect_pts, mix = art.shape, art.stroke, art.ellipse_pts, art.rect_pts, art.mix
canvas, finish, Wall = art.canvas, art.finish, art.Wall
ENEMIES = ROOT / "assets" / "art" / "enemies"

DANGER = (231, 76, 60)
DEFLECT = (92, 225, 230)    # parried scissors (code used #5ce1e6): cyan, not P2's blue
GOLDEN = (255, 210, 63)
WOOD = (176, 141, 87)
LEATHER = (142, 47, 60)
SLATE = (52, 73, 94)
NIGHT = (44, 62, 110)
PINK, BLUE = (255, 95, 162), (58, 143, 214)

# --- Tiles ----------------------------------------------------------------------
# Same 4x5 atlas layout as L1 (LevelBuilder._edge_tile); only the colours change.
TILE_PALETTES = {
    "l2": {"CABINET": (186, 138, 110), "CABINET_GROOVE": (160, 112, 88),       # reception walnut
           "COUNTER": (250, 244, 232), "COUNTER_SHADE": (150, 108, 84)},
    "l3": {"CABINET": (166, 184, 198), "CABINET_GROOVE": (138, 158, 174),      # wash-room ceramic
           "COUNTER": (252, 252, 248), "COUNTER_SHADE": (118, 140, 158)},
    "l4": {"CABINET": (146, 98, 100), "CABINET_GROOVE": (120, 78, 82),         # after-hours mahogany
           "COUNTER": (242, 230, 216), "COUNTER_SHADE": (140, 100, 96)},
}


def make_tiles(level: str) -> None:
    pal = TILE_PALETTES[level]
    saved = {k: getattr(art, k) for k in pal}
    for k, v in pal.items():
        setattr(art, k, v)
    try:
        atlas = Image.new("RGBA", (TILE * 4, TILE * 5), (0, 0, 0, 0))
        for mask in range(16):
            atlas.alpha_composite(art.solid_tile(mask, 0), ((mask % 4) * TILE, (mask // 4) * TILE))
        for v in range(1, 4):
            atlas.alpha_composite(art.solid_tile(15, v), ((v - 1) * TILE, 4 * TILE))
        atlas.alpha_composite(art.shelf_tile(), (3 * TILE, 4 * TILE))
        atlas.save(ROOT / "assets" / "art" / level / f"tiles_{level}.png")
    finally:
        for k, v in saved.items():
            setattr(art, k, v)


# --- Background helpers -----------------------------------------------------------

def save(wall: Wall, level: str, name: str) -> None:
    wall.img.resize((wall.w, wall.h), Image.LANCZOS).convert("RGB").save(ROOT / "assets" / "art" / level / name)


def pinstripes(wall, step=32):
    for x in range(0, wall.w, step):
        wall.d.line((x * wall.s, 0, x * wall.s, wall.h * wall.s), fill=wall.shade, width=wall.s)


def clock(wall, cx, cy, r, hour, minute):
    wall.shape(ellipse_pts(cx, cy, r + 8, r + 8, 40), wall.tint(WOOD, 0.3))
    wall.shape(ellipse_pts(cx, cy, r, r, 40), wall.light, width=1.6)
    for i in range(12):
        a = math.radians(i * 30)
        wall.path([(cx + math.sin(a) * r * 0.78, cy - math.cos(a) * r * 0.78),
                   (cx + math.sin(a) * r * 0.9, cy - math.cos(a) * r * 0.9)], wall.line, 1.6, amp=0)
    for frac, length, width in ((((hour % 12) + minute / 60) / 12, 0.5, 3.0), (minute / 60, 0.75, 2.0)):
        a = frac * 2 * math.pi
        wall.path([(cx, cy), (cx + math.sin(a) * r * length, cy - math.cos(a) * r * length)], wall.line, width, amp=0)


def plant(wall, cx, base):
    leaf = wall.tint((96, 168, 96), 0.32)
    for dx, dy, rx, ry in ((-26, -70, 16, 30), (24, -76, 16, 32), (0, -96, 15, 34), (-40, -40, 14, 22), (40, -44, 14, 22)):
        wall.shape(ellipse_pts(cx + dx, base - 60 + dy, rx, ry, 24), leaf, width=1.6)
    wall.shape([(cx - 34, base - 66), (cx + 34, base - 66), (cx + 24, base), (cx - 24, base)], wall.tint((214, 120, 80), 0.3))


def scissor_doodle(wall, cx, cy, size, color, angle=0.0):
    ca, sa = math.cos(angle), math.sin(angle)
    rot = lambda x, y: (cx + x * ca - y * sa, cy + x * sa + y * ca)
    for sgn in (1, -1):
        wall.path([rot(-size * 0.2, sgn * size * 0.18), rot(size, -sgn * size * 0.12)], color, 3.0, amp=0.3)
        wall.shape([rot(-size * 0.45 + size * 0.16 * math.cos(t), sgn * size * 0.24 + size * 0.14 * math.sin(t))
                    for t in [i * math.pi / 8 for i in range(16)]], wall.light, width=1.8)


def comb_doodle(wall, x, y, w, color):
    wall.shape(rect_pts(x, y, w, 10, 4), color, width=1.6)
    for i in range(int(w / 6)):
        wall.path([(x + 4 + i * 6, y + 10), (x + 4 + i * 6, y + 22)], wall.line, 1.4, amp=0)


def bubbles(wall, spots):
    for cx, cy, r in spots:
        wall.shape(ellipse_pts(cx, cy, r, r, 24), wall.light, width=1.6)
        wall.path([(cx - r * 0.5, cy - r * 0.2), (cx - r * 0.2, cy - r * 0.55)], (255, 255, 255), 1.6, amp=0)


def gear(wall, cx, cy, r, teeth, color):
    pts = []
    for i in range(teeth * 4):
        a = 2 * math.pi * i / (teeth * 4)
        rr = r if (i % 4) in (0, 1) else r * 0.8
        pts.append((cx + rr * math.cos(a), cy + rr * math.sin(a)))
    wall.shape(pts, color, width=1.8, amp=0.6)
    wall.shape(ellipse_pts(cx, cy, r * 0.32, r * 0.32, 24), wall.color, width=1.6)


def hood_dryer(wall, cx, base):
    """Old-school sit-under hood dryer on a stand."""
    coral = wall.tint((240, 140, 96), 0.28)
    wall.path([(cx, base), (cx, base - 150)], wall.line, 5.0, amp=0.3)
    wall.shape(ellipse_pts(cx, base, 40, 8, 24), wall.shade)
    wall.shape(ellipse_pts(cx + 6, base - 196, 64, 48, 36), coral)
    wall.shape([(cx - 40, base - 166), (cx + 60, base - 172), (cx + 52, base - 150), (cx - 34, base - 146)], wall.light, width=1.6)
    for i in range(3):
        wall.path([(cx - 20 + i * 18, base - 222), (cx - 16 + i * 18, base - 206)], wall.soft, 2.0, amp=0)


def towel(wall, cx, top, color):
    wall.shape(ellipse_pts(cx, top, 5, 5, 12), wall.shade)
    wall.shape(rect_pts(cx - 26, top + 6, 52, 90, 10), color)
    for y in (top + 70, top + 80):
        wall.path([(cx - 20, y), (cx + 20, y)], wall.light, 3.0, amp=0.3)


def hose(wall, cx, length):
    pts = [(cx, 0)] + [(cx + 14 * math.sin(i * 0.9), i * length / 6) for i in range(1, 7)]
    wall.path(pts, wall.line, 3.0)
    end = pts[-1]
    wall.shape([(end[0] - 16, end[1]), (end[0] + 16, end[1]), (end[0] + 10, end[1] + 18), (end[0] - 10, end[1] + 18)],
               wall.tint(CHROME, 0.5))


def swap_arrows(wall, x0, x1, y):
    """Two curved arrows between the haircut sketches: the chair swaps them."""
    mid = (x0 + x1) / 2
    for sgn in (1, -1):
        pts = [(x0 + (x1 - x0) * t, y + sgn * (-34 * math.sin(math.pi * t))) for t in [i / 10 for i in range(11)]]
        if sgn < 0:
            pts.reverse()
        wall.path(pts, wall.tint(PINK, 0.35), 2.4, amp=0.2)
        ex, ey = pts[-1]
        d = 1 if sgn > 0 else -1
        wall.path([(ex - 9 * d, ey - 6 * sgn), (ex, ey), (ex - 9 * d, ey + 7 * sgn)], wall.tint(PINK, 0.35), 2.4, amp=0)
    del mid


# --- Level 2: reception ---------------------------------------------------------

def bg_l2_reception() -> None:
    wall = Wall((227, 220, 239), 41)
    pinstripes(wall)
    for cx in (170, 1100):
        art.lamp(wall, cx)
    clock(wall, 860, 170, 54, 10, 10)
    # Appointment board, pinned cards.
    wall.shape(rect_pts(220, 120, 200, 140, 10), wall.tint(WOOD, 0.3))
    for i, (x, y) in enumerate(((236, 136), (300, 132), (360, 142), (240, 196), (310, 200), (368, 194))):
        wall.shape(rect_pts(x, y, 46, 40, 3), wall.light, width=1.4)
        wall.shape(ellipse_pts(x + 23, y + 4, 4, 4, 12), wall.tint(PINK if i % 2 else BLUE, 0.3), line=False)
    art.hair_sketch(wall, 540, 470, True)
    art.hair_sketch(wall, 680, 470, False)
    scissor_doodle(wall, 560, 200, 44, wall.tint(DANGER, 0.22), -0.5)
    plant(wall, 400, 600)
    save(wall, "l2", "bg_l2_01_reception.png")


def bg_l2_corridor() -> None:
    wall = Wall((223, 231, 242), 42)
    # Pegboard of hanging tools.
    wall.shape(rect_pts(110, 90, 420, 230, 16), wall.tint(WOOD, 0.22))
    for x in range(130, 520, 24):
        for y in range(108, 310, 24):
            wall.d.ellipse(((x - 2) * wall.s, (y - 2) * wall.s, (x + 2) * wall.s, (y + 2) * wall.s), fill=wall.soft)
    scissor_doodle(wall, 190, 180, 50, wall.tint(CHROME, 0.6), 1.2)
    scissor_doodle(wall, 300, 190, 40, wall.tint(DANGER, 0.2), 1.4)
    comb_doodle(wall, 360, 140, 90, wall.tint(INTERACT, 0.25))
    comb_doodle(wall, 380, 240, 70, wall.tint(BLUE, 0.22))
    wall.shape(rect_pts(450, 160, 20, 90, 8), wall.tint(WOOD, 0.4))          # brush handle
    wall.shape(ellipse_pts(460, 150, 22, 18, 24), wall.tint((120, 90, 70), 0.3))
    # Staff lockers, staggered so their tops never line up into a ledge.
    for i, x in enumerate((720, 790, 860, 930)):
        top = 120 + (i % 2) * 22
        wall.shape(rect_pts(x, top, 62, 260 - (i % 2) * 22, 6), wall.tint(CHROME, 0.45))
        for y in range(top + 20, top + 60, 10):
            wall.path([(x + 14, y), (x + 48, y)], wall.soft, 1.6, amp=0)
        wall.shape(ellipse_pts(x + 50, top + 130, 4, 4, 12), wall.shade)
    wall.shape(rect_pts(610, 0, 18, 720), wall.tint(CHROME, 0.4), width=1.6)   # pipe
    for t, c in ((0, PINK), (1, (96, 168, 96)), (2, INTERACT)):
        wall.shape(rect_pts(1090, 420 - t * 34, 120, 34, 14), wall.tint(c, 0.22))  # rolled towels
    save(wall, "l2", "bg_l2_02_corridor.png")


# --- Level 3: wash & blow-dry ---------------------------------------------------

def bg_l3_blow_dry() -> None:
    wall = Wall((251, 233, 222), 51)
    art.stripes(wall, 56, 20)
    for cx in (220, 1060):
        hood_dryer(wall, cx, 470)
    for cx in (500, 780):
        art.lamp(wall, cx)
        art.mirror(wall, cx, 104, 100, 130)
    rng = wall.rng
    for _ in range(9):  # warm air swirls
        x, y = rng.uniform(80, 1200), rng.uniform(260, 520)
        wall.path([(x + i * 8, y - 14 * math.sin(i * 0.9)) for i in range(8)], wall.tint((240, 140, 96), 0.18), 2.0, amp=0.2)
    save(wall, "l3", "bg_l3_01_blow_dry.png")


def bg_l3_shampoo() -> None:
    wall = Wall((226, 241, 244), 52)
    for row, y in enumerate(range(0, wall.h, 40)):  # staggered wall tiles
        wall.d.line((0, y * wall.s, wall.w * wall.s, y * wall.s), fill=wall.shade, width=wall.s)
        for x in range(20 * (row % 2), wall.w, 40):
            wall.d.line((x * wall.s, y * wall.s, x * wall.s, (y + 40) * wall.s), fill=wall.shade, width=wall.s)
    for nx in (150, 880):  # niches of shampoo bottles
        wall.shape(rect_pts(nx, 130, 240, 120, 24), wall.shade)
        for i, c in enumerate(((96, 168, 96), (142, 68, 173), INTERACT, (240, 140, 96))):
            h = 60 + (i % 2) * 16
            wall.shape(rect_pts(nx + 26 + i * 52, 230 - h, 36, h, 10), wall.tint(c, 0.25), width=1.6)
            wall.shape(rect_pts(nx + 38 + i * 52, 222 - h, 12, 10, 2), wall.light, width=1.4)
    for cx, c in ((560, PINK), (650, (96, 168, 96))):
        towel(wall, cx, 150, wall.tint(c, 0.22))
    bubbles(wall, ((300, 360, 14), (340, 330, 8), (760, 300, 18), (810, 270, 9), (1100, 380, 12), (1140, 340, 7)))
    save(wall, "l3", "bg_l3_02_shampoo.png")


def bg_l3_rinse() -> None:
    wall = Wall((243, 230, 244), 53)
    rng = wall.rng
    for _ in range(80):
        x, y = rng.uniform(0, 1280), rng.uniform(40, 700)
        wall.d.ellipse(((x - 3) * wall.s, (y - 3) * wall.s, (x + 3) * wall.s, (y + 3) * wall.s), fill=wall.shade)
    for cx, length in ((140, 150), (420, 110), (1150, 170)):
        hose(wall, cx, length)
    for cx, cy in ((640, 200), (900, 330)):  # rinse swirls
        pts = [(cx + (6 + t * 5) * math.cos(t), cy + (6 + t * 5) * math.sin(t)) for t in [i * 0.3 for i in range(40)]]
        wall.path(pts, wall.tint((74, 163, 223), 0.2), 2.4, amp=0.2)
    bubbles(wall, ((260, 420, 22), (300, 380, 10), (520, 330, 16), (720, 420, 26), (770, 380, 10),
                   (1010, 250, 20), (1060, 220, 9), (1180, 420, 14)))
    save(wall, "l3", "bg_l3_03_rinse.png")


# --- Level 4: after hours -------------------------------------------------------

def bg_l4_closing() -> None:
    wall = Wall((239, 227, 208), 61)
    art.stripes(wall, 48, 24)
    # Arched window onto the night street.
    cx, top, w, h = 640, 90, 240, 230
    arch = [(cx - w / 2, top + h), (cx - w / 2, top + w / 2)] + \
           [(cx - w / 2 * math.cos(a), top + w / 2 - w / 2 * math.sin(a)) for a in [i * math.pi / 16 for i in range(17)]] + \
           [(cx + w / 2, top + h)]
    wall.shape(arch, wall.tint(WOOD, 0.35))
    inner = [(x * 0.9 + cx * 0.1, y * 0.92 + (top + h) * 0.08) for x, y in arch]
    wall.shape(inner, wall.tint(NIGHT, 0.4))
    wall.shape(ellipse_pts(cx + 50, top + 70, 22, 22, 24), wall.light, line=False)      # moon
    wall.shape(ellipse_pts(cx + 60, top + 62, 20, 20, 24), wall.tint(NIGHT, 0.4), line=False)
    for sx, sy in ((cx - 60, top + 60), (cx - 20, top + 120), (cx - 80, top + 160), (cx + 10, top + 40)):
        wall.shape(ellipse_pts(sx, sy, 2.5, 2.5, 8), wall.light, line=False)
    wall.path([(cx, top + 6), (cx, top + h - 6)], wall.tint(WOOD, 0.35), 4.0, amp=0)
    # Hanging sign with a moon: the shop is closed (no words baked in).
    wall.path([(300, 60), (260, 120)], wall.line, 1.6, amp=0)
    wall.path([(300, 60), (340, 120)], wall.line, 1.6, amp=0)
    wall.shape(rect_pts(240, 120, 120, 70, 10), wall.tint(DANGER, 0.22))
    wall.shape(ellipse_pts(300, 155, 18, 18, 24), wall.light, line=False)
    wall.shape(ellipse_pts(308, 150, 16, 16, 24), wall.tint(DANGER, 0.22), line=False)
    clock(wall, 1000, 170, 50, 11, 55)
    # Broom leaning on the wall, a pile of swept hair beside it.
    wall.path([(800, 300), (860, 520)], wall.tint(WOOD, 0.45), 6.0, amp=0.3)
    wall.shape([(846, 500), (876, 494), (902, 590), (840, 600)], wall.tint(INTERACT, 0.22))
    for i in range(6):
        wall.path([(920 + i * 9, 590), (930 + i * 9, 560 - (i % 3) * 8)], wall.tint(PINK if i % 2 else BLUE, 0.25), 2.0, amp=0.6)
    save(wall, "l4", "bg_l4_01_closing.png")


def bg_l4_chair() -> None:
    wall = Wall((246, 221, 228), 62)
    pinstripes(wall, 40)
    # Spotlight from the ceiling onto the chair tunnel (tiles 15-22).
    wall.shape([(600, 0), (680, 0), (760, 600), (520, 600)], wall.tint((255, 255, 255), 0.35), line=False)
    for x in (120, 1150):
        art.barber_pole(wall, x, 130, 130)
    art.mirror(wall, 290, 110, 130, 170)
    art.mirror(wall, 960, 120, 110, 150)
    # The shop's two haircut sketches, with arrows swapping them: a hint at the chair.
    art.hair_sketch(wall, 220, 420, True)
    art.hair_sketch(wall, 400, 420, False)
    swap_arrows(wall, 258, 362, 420)
    save(wall, "l4", "bg_l4_02_chair.png")


def bg_l4_workshop() -> None:
    wall = Wall((226, 214, 214), 63)
    for x in (470, 830):  # pillars with faded warning stripes
        wall.shape(rect_pts(x, 0, 44, 720), wall.shade)
        for y in range(-20, 720, 40):
            wall.path([(x + 4, y + 30), (x + 40, y)], wall.tint(DANGER, 0.18), 8.0, amp=0)
    gear(wall, 170, 160, 72, 10, wall.tint(CHROME, 0.4))
    gear(wall, 280, 260, 44, 8, wall.tint(WOOD, 0.3))
    gear(wall, 1090, 190, 82, 12, wall.tint(CHROME, 0.4))
    # Blueprint of the barber bot, pinned between the pillars.
    bp = wall.tint((70, 110, 170), 0.25)
    wall.shape(rect_pts(540, 110, 240, 180, 6), bp)
    lite = wall.light
    wall.path(rect_pts(610, 170, 70, 90) + [(610, 170)], lite, 1.6, amp=0.3)
    wall.path(rect_pts(620, 140, 50, 30) + [(620, 140)], lite, 1.6, amp=0.3)
    wall.path([(680, 210), (720, 195)], lite, 1.6, amp=0)
    wall.path([(680, 222), (720, 237)], lite, 1.6, amp=0)
    wall.shape(ellipse_pts(645, 132, 14, 5, 16), lite, line=False)
    for cx in (40, 360, 980):  # cables sagging from the ceiling
        wall.path([(cx + t * 120, 8 + 40 * math.sin(math.pi * t)) for t in [i / 10 for i in range(11)]], wall.line, 2.4, amp=0.2)
    save(wall, "l4", "bg_l4_03_workshop.png")


# --- Enemies and props ------------------------------------------------------------

def clipper_bot() -> None:
    """Two 44x32 frames, facing right, feet at (22, 31): patrolling | stunned."""
    strip = Image.new("RGBA", (88, 32), (0, 0, 0, 0))
    for i, stunned in enumerate((False, True)):
        rng = random.Random(4)
        img, d = canvas(44, 32)
        body = mix(SLATE, (255, 255, 255), 0.45) if stunned else SLATE
        stroke(d, [(8, 26), (2, 30)], INK, 2.2)                                         # cord
        for k in range(5):                                                              # blade teeth
            y = 8 + k * 4.4
            stroke(d, [(34, y), (41, y)], INK, 3.2)
            stroke(d, [(34, y), (40.5, y)], CHROME, 1.6)
        shape(d, rect_pts(36, 6, 4, 22, 1.5), CHROME, INK, 2.0, rng, 0.2)               # blade plate
        shape(d, rect_pts(6, 4, 31, 26, 9), body, INK, 2.8, rng, 0.5)                   # body
        shape(d, rect_pts(10, 8, 18, 6, 3), mix(body, (255, 255, 255), 0.25), None)     # shine
        if stunned:
            for dx in (-1, 1):
                stroke(d, [(22 + dx * 3, 15), (22 - dx * 3, 21)], INK, 1.8)
        else:
            shape(d, ellipse_pts(22, 19, 3.4, 3.4, 12), EXIT, INK, 1.4)                  # power light
        strip.alpha_composite(finish(img, 44, 32), (i * 44, 0))
    strip.save(ENEMIES / "enemy_clipper.png")


def scissors() -> None:
    """Three 28x16 frames pointing right, centred: enemy (red) | parried (cyan) | golden."""
    strip = Image.new("RGBA", (84, 16), (0, 0, 0, 0))
    for i, c in enumerate((DANGER, DEFLECT, GOLDEN)):
        rng = random.Random(8)
        img, d = canvas(28, 16)
        for sgn in (1, -1):
            shape(d, [(10, 8 + sgn * 1.5), (27, 8 - sgn * 3.5), (26, 8 - sgn * 1.0)], mix(c, (255, 255, 255), 0.35), INK, 1.8)
        for sgn in (1, -1):
            shape(d, ellipse_pts(6, 8 + sgn * 4, 4.6, 3.4, 16), c, INK, 2.0, rng, 0.2)
        shape(d, ellipse_pts(12, 8, 1.6, 1.6, 8), INK)
        strip.alpha_composite(finish(img, 28, 16), (i * 28, 0))
    strip.save(ENEMIES / "enemy_scissor.png")


def dispenser() -> None:
    """36x36 scissor dispenser, nozzle on the right, centred. Lights and jam puff are code."""
    rng = random.Random(12)
    img, d = canvas(36, 36)
    shape(d, rect_pts(28, 12, 7, 12, 2), mix(CHROME, INK, 0.45), INK, 2.2, rng, 0.2)       # nozzle
    shape(d, rect_pts(3, 3, 28, 30, 6), CHROME, INK, 2.8, rng, 0.5)
    shape(d, rect_pts(7, 7, 18, 4, 2), (255, 255, 255), None)
    for sgn in (1, -1):                                                                     # logo
        stroke(d, [(12, 20 + sgn * 1), (24, 20 - sgn * 7)], mix(CHROME, INK, 0.5), 1.8)
        shape(d, ellipse_pts(10, 22 + sgn * 4, 3, 2.4, 12), DANGER, INK, 1.2)
    finish(img, 36, 36).save(ENEMIES / "enemy_dispenser.png")


def barber_bot() -> None:
    """Three 144x144 frames facing right, feet at (72, 140): normal | dazed | hurt flash."""
    strip = Image.new("RGBA", (432, 144), (0, 0, 0, 0))
    for i, mode in enumerate(("normal", "dazed", "hurt")):
        rng = random.Random(30)
        img, d = canvas(144, 144)
        body = {"normal": (192, 57, 43), "dazed": (150, 160, 162), "hurt": (255, 236, 232)}[mode]
        top = 12
        for sgn, y in ((1, top + 64), (-1, top + 76)):                                     # scissor arm
            shape(d, [(118, y), (140, y - sgn * 10), (138, y - sgn * 4), (118, y + 6)], CHROME, INK, 2.6, rng, 0.3)
        shape(d, ellipse_pts(122, top + 70, 6, 6, 16), mix(CHROME, INK, 0.4), INK, 2.0)
        for x in (44, 100):                                                                 # wheels
            shape(d, ellipse_pts(x, 132, 12, 8, 20), mix(SLATE, INK, 0.3), INK, 2.6, rng, 0.3)
        shape(d, rect_pts(24, top + 24, 96, 100, 18), body, INK, 3.2, rng, 0.8)              # body
        shape(d, [(40, top + 50), (104, top + 50), (96, top + 118), (48, top + 118)],         # barber apron
              mix(body, (255, 255, 255), 0.7), INK, 2.2, rng, 0.5)
        for y in range(top + 62, top + 112, 14):
            stroke(d, [(52, y), (92, y)], mix(body, (255, 255, 255), 0.3), 2.0)
        shape(d, rect_pts(32, top + 8, 80, 26, 10), SLATE, INK, 3.0, rng, 0.6)             # head
        eye = GOLDEN if mode == "dazed" else INTERACT
        if mode == "dazed":
            for dx in (-1, 1):
                stroke(d, [(92 + dx * 5, top + 16), (92 - dx * 5, top + 26)], eye, 2.6)
        else:
            shape(d, rect_pts(84, top + 13, 16, 10, 3), eye, INK, 1.6)
        # Curly moustache, because he's a barber.
        for sgn in (1, -1):
            pts = [(72 + sgn * (4 + 14 * t), top + 40 - 6 * math.sin(math.pi * t) + 4 * t) for t in [k / 8 for k in range(9)]]
            stroke(d, pts, INK, 3.4)
        knob = GOLDEN if mode == "dazed" else mix(CHROME, INK, 0.3)                          # weak point
        shape(d, rect_pts(54, top - 4, 36, 14, 6), knob, INK, 2.6, rng, 0.4)
        strip.alpha_composite(finish(img, 144, 144), (i * 144, 0))
    strip.save(ENEMIES / "enemy_barber_bot.png")


def bell() -> None:
    """Two 32x36 frames, centred at (16, 16): waiting (chrome) | rung (gold)."""
    strip = Image.new("RGBA", (64, 36), (0, 0, 0, 0))
    for i, rung in enumerate((False, True)):
        rng = random.Random(15)
        img, d = canvas(32, 36)
        dome = GOLDEN if rung else CHROME
        shape(d, rect_pts(13, 1, 6, 9, 2), mix(CHROME, INK, 0.4), INK, 2.0)                 # bracket
        shape(d, rect_pts(2, 9, 28, 6, 2), WOOD, INK, 2.2, rng, 0.3)                         # base plate
        shape(d, [(4, 30)] + [(16 - 12 * math.cos(a), 30 - 14 * math.sin(a)) for a in [k * math.pi / 12 for k in range(13)]],
              dome, INK, 2.6, rng, 0.3)
        shape(d, rect_pts(2, 29, 28, 5, 2), mix(dome, INK, 0.25), INK, 2.0)
        shape(d, ellipse_pts(16, 15, 3, 3, 12), mix(dome, INK, 0.2), INK, 1.4)
        stroke(d, [(9, 25), (12, 20)], (255, 255, 255), 2.0)
        strip.alpha_composite(finish(img, 32, 36), (i * 32, 0))
    strip.save(PROPS / "prop_bell.png")


def staff_door() -> None:
    """32x64 nine-slice (8 px margins): wooden staff door. Window, plate and pips are code."""
    rng = random.Random(17)
    img, d = canvas(32, 64)
    wood = (142, 110, 83)
    shape(d, rect_pts(1.5, 1.5, 29, 61, 5), wood, INK, 3, rng, 0.5)
    stroke(d, [(16, 9), (16, 55)], mix(wood, INK, 0.25), 1.6)
    finish(img, 32, 64).save(PROPS / "prop_door.png")


def chair() -> None:
    """Two 112x120 frames, bottom centre at (56, 120): waiting | used (darker leather)."""
    strip = Image.new("RGBA", (224, 120), (0, 0, 0, 0))
    for i, used in enumerate((False, True)):
        rng = random.Random(19)
        img, d = canvas(112, 120)
        leather = mix(LEATHER, INK, 0.3) if used else LEATHER
        shape(d, ellipse_pts(56, 114, 42, 6, 24), mix(CHROME, INK, 0.3), INK, 2.6, rng, 0.4)  # foot
        shape(d, rect_pts(50, 76, 12, 38, 3), CHROME, INK, 2.6, rng, 0.3)                    # hydraulic pole
        shape(d, rect_pts(16, 6, 22, 70, 9), leather, INK, 3, rng, 0.6)                      # back
        shape(d, rect_pts(20, 0, 14, 10, 4), mix(CHROME, INK, 0.2), INK, 2.2)               # headrest bar
        shape(d, rect_pts(16, 60, 80, 20, 8), leather, INK, 3, rng, 0.6)                     # seat
        for x in (10, 86):                                                                   # armrests
            shape(d, rect_pts(x, 50, 18, 8, 3), CHROME, INK, 2.2)
        shape(d, rect_pts(78, 88, 26, 6, 2), CHROME, INK, 2.0)                               # footrest
        shape(d, rect_pts(52, 98, 9, 6, 2), INTERACT, INK, 1.6)                              # pump pedal
        strip.alpha_composite(finish(img, 112, 120), (i * 112, 0))
    strip.save(PROPS / "prop_chair.png")


def main() -> None:
    for level in TILE_PALETTES:
        (ROOT / "assets" / "art" / level).mkdir(parents=True, exist_ok=True)
        make_tiles(level)
    ENEMIES.mkdir(parents=True, exist_ok=True)
    for bg in (bg_l2_reception, bg_l2_corridor, bg_l3_blow_dry, bg_l3_shampoo, bg_l3_rinse,
               bg_l4_closing, bg_l4_chair, bg_l4_workshop):
        bg()
    for prop in (clipper_bot, scissors, dispenser, barber_bot, bell, staff_door, chair):
        prop()
    print("ok")


if __name__ == "__main__":
    main()
