"""Turns the AI-generated character sheets into game-ready animation strips.

Source: art_src/characters/<hair>_sheet.png, 6 columns x 8 rows of 181x181 cells, one
action per row, body and hair drawn together (see docs/art/l1_art_direction.md).
Output: assets/art/characters/<hair>/<anim>.png (one horizontal strip per animation) and
assets/art/characters/frames.json, which tools/build_character_frames.gd turns into
SpriteFrames.

Per frame:
  1. clean the alpha: drop the generator's faint haze, make the body fully opaque, and
     repaint the red fringe around pink edges in the outline colour;
  2. find the face (the cream pixels) and the feet (lowest dark pixel under the face);
  3. place it in a fixed cell at SCALE: ground poses stand on the baseline, air poses keep
     the face where it is when standing, so the head doesn't jitter while the legs move;
  4. downscale with Lanczos.
Run: python -I tools/art/normalize_characters.py
"""
import json
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
SRC = ROOT / "art_src" / "characters"
OUT = ROOT / "assets" / "art" / "characters"

SOURCE_CELL = 181
SCALE = 0.45            # feet to forehead ~45 px: matches the 28x44 hitbox
CELL = (136, 128)       # output cell (game pixels)
BASELINE = 104          # feet line inside the cell; the player's feet are 22 px below its origin
INK = (43, 33, 64)

# name: (row, columns, fps, loop, pose). pose "ground" = feet on the baseline,
# "air" = face at its standing height.
ANIMS = {
    "twin_tails": {
        "idle": (0, range(6), 6, True, "ground"),
        "run": (1, range(6), 12, True, "ground"),
        "jump": (2, range(2, 6), 12, False, "air"),
        "fall": (3, range(6), 8, True, "air"),
        "attack": (4, range(6), 20, False, "ground"),
        "glide": (5, range(6), 16, True, "air"),
        "pull": (6, range(6), 15, False, "ground"),
        "carry_glide": (7, range(6), 16, True, "air"),
        "hang": (2, [5], 1, False, "air"),
    },
    "pompadour": {
        "idle": (0, range(6), 6, True, "ground"),
        "run": (1, range(6), 12, True, "ground"),
        "jump": (2, range(2, 6), 12, False, "air"),
        "fall": (3, range(6), 8, True, "air"),
        "parry": (4, range(6), 20, False, "ground"),
        "dash": (5, range(6), 30, False, "ground"),
        "hang": (2, [5], 1, False, "air"),
    },
}


def clean_alpha(im: Image.Image) -> Image.Image:
    px = im.load()
    w, h = im.size
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            if a < 48:
                px[x, y] = (0, 0, 0, 0)
                continue
            a = 255 if a > 200 else int((a - 48) * 255 / 152)
            if r > 150 and g < 90 and b < 110:  # red generator fringe, not pink (b ~160)
                r, g, b = INK
            px[x, y] = (r, g, b, a)
    return im


def drop_neighbour_bleed(cell: Image.Image) -> Image.Image:
    """Erase pieces that touch the cell border but aren't part of the main figure: the
    generator let hair and speed lines spill over from the neighbouring cells. The figure
    faces right, so a yellow piece on the right edge is this frame's own parry spark."""
    px = cell.load()
    n = SOURCE_CELL
    seen = [[False] * n for _ in range(n)]
    parts = []
    for y0 in range(n):
        for x0 in range(n):
            if seen[y0][x0] or px[x0, y0][3] == 0:
                continue
            stack, part, edge, spark = [(x0, y0)], [], False, False
            seen[y0][x0] = True
            while stack:
                x, y = stack.pop()
                part.append((x, y))
                edge |= x in (0, n - 1) or y in (0, n - 1)
                r, g, b, _ = px[x, y]
                spark |= x == n - 1 and r > 200 and g > 160 and b < 90
                for nx, ny in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
                    if 0 <= nx < n and 0 <= ny < n and not seen[ny][nx] and px[nx, ny][3] > 0:
                        seen[ny][nx] = True
                        stack.append((nx, ny))
            parts.append((part, edge and not spark))
    biggest = max(len(p) for p, _ in parts)
    for part, edge in parts:
        if edge and len(part) < biggest:
            for x, y in part:
                px[x, y] = (0, 0, 0, 0)
    return cell


def is_cream(p) -> bool:
    return p[3] > 200 and p[0] > 225 and p[1] > 215 and p[2] > 190


def is_dark(p) -> bool:
    return p[3] > 128 and p[0] * 0.3 + p[1] * 0.59 + p[2] * 0.11 < 90


def measure(cell: Image.Image):
    """Face centre and feet line, in cell pixels."""
    px = cell.load()
    n = sx = sy = 0
    for y in range(SOURCE_CELL):
        for x in range(SOURCE_CELL):
            if is_cream(px[x, y]):
                n += 1
                sx += x
                sy += y
    fx, fy = sx / n, sy / n
    feet = max(y for y in range(SOURCE_CELL) for x in range(max(0, int(fx) - 55), min(SOURCE_CELL, int(fx) + 55))
               if is_dark(px[x, y]))
    return fx, fy, feet


def place(img: Image.Image, x: int, y: int) -> Image.Image:
    """img drawn at (x, y) on an empty cell; parts outside the cell are cut off."""
    frame = Image.new("RGBA", CELL, (0, 0, 0, 0))
    src = img.crop((max(0, -x), max(0, -y), img.width, img.height))
    frame.alpha_composite(src, (max(0, x), max(0, y)))
    return frame


def main() -> None:
    manifest = {"cell": CELL, "baseline": BASELINE, "scale": SCALE, "characters": {}}
    for hair, anims in ANIMS.items():
        sheet = clean_alpha(Image.open(SRC / f"{hair}_sheet.png").convert("RGBA"))
        cells = {}
        for row in range(8):
            for col in range(6):
                box = (col * SOURCE_CELL, row * SOURCE_CELL, (col + 1) * SOURCE_CELL, (row + 1) * SOURCE_CELL)
                cell = drop_neighbour_bleed(sheet.crop(box))
                cells[row, col] = (cell, *measure(cell))
        # Standing face height above the feet, from the idle row.
        idle = [cells[0, c] for c in range(6)]
        face_above_feet = sum(feet - fy for _, _, fy, feet in idle) / len(idle)

        (OUT / hair).mkdir(parents=True, exist_ok=True)
        entry = {}
        for name, (row, cols, fps, loop, pose) in anims.items():
            cols = list(cols)
            strip = Image.new("RGBA", (CELL[0] * len(cols), CELL[1]), (0, 0, 0, 0))
            for i, col in enumerate(cols):
                cell, fx, fy, feet = cells[row, col]
                big = cell.resize((round(SOURCE_CELL * SCALE),) * 2, Image.LANCZOS)
                # Where the face/feet land after scaling, then shift them onto the anchors.
                anchor_y = feet if pose == "ground" else fy + face_above_feet
                dx = CELL[0] / 2 - fx * SCALE
                dy = BASELINE - anchor_y * SCALE
                frame = place(big, round(dx), round(dy))
                bbox = frame.getbbox()
                if bbox and (bbox[0] == 0 or bbox[1] == 0 or bbox[2] == CELL[0] or bbox[3] == CELL[1]):
                    print(f"  note: {hair}/{name} frame {i} touches the cell edge {bbox}")
                strip.alpha_composite(frame, (i * CELL[0], 0))
            strip.save(OUT / hair / f"{name}.png")
            entry[name] = {"file": f"{hair}/{name}.png", "frames": len(cols), "fps": fps, "loop": loop}
            print(f"{hair}/{name}: {len(cols)} frames")
        manifest["characters"][hair] = entry
    (OUT / "frames.json").write_text(json.dumps(manifest, indent=2))


if __name__ == "__main__":
    main()
