"""Full-resolution character portraits for the menus (title screen, styling chair).

The in-game strips are drawn at game size (feet to forehead ~45 px), so a menu that shows a
character at 3-4x that size blurs them. These portraits are cut from the same source sheets
at their original resolution instead: the idle pose, cleaned like the game strips, trimmed
to the figure and padded to a square. Output: assets/art/characters/portraits/<hair>.png.
Run: python -I tools/art/make_portraits.py
"""
import importlib.util
from pathlib import Path

from PIL import Image

_spec = importlib.util.spec_from_file_location("norm", Path(__file__).with_name("normalize_characters.py"))
norm = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(norm)

ROOT = norm.ROOT
OUT = ROOT / "assets" / "art" / "characters" / "portraits"
SIZE = 256   # square portrait; the figure fills its height minus the margin
MARGIN = 10


def from_old_sheet(name: str) -> Image.Image:
    """Idle pose (row 0, column 0) of a 6x8 sheet of 181 px cells."""
    sheet = Image.open(norm.SRC / f"{name}_sheet.png").convert("RGBA")
    n = norm.SOURCE_CELL
    cell = sheet.crop((0, 0, n, n))
    return norm.drop_neighbour_bleed(norm.clean_alpha(cell))


def portrait(figure: Image.Image) -> Image.Image:
    figure = figure.crop(figure.getbbox())
    scale = min((SIZE - 2 * MARGIN) / figure.height, (SIZE - 2 * MARGIN) / figure.width)
    figure = figure.resize((round(figure.width * scale), round(figure.height * scale)), Image.LANCZOS)
    out = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    out.alpha_composite(figure, ((SIZE - figure.width) // 2, SIZE - MARGIN - figure.height))
    return out


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    figures = {
        "twin_tails": from_old_sheet("twin_tails"),
        "pompadour": from_old_sheet("pompadour"),
    }
    for name, figure in figures.items():
        bbox = figure.getbbox()
        portrait(figure).save(OUT / f"{name}.png")
        print(f"{name}: source figure {bbox[2] - bbox[0]}x{bbox[3] - bbox[1]} px")


if __name__ == "__main__":
    main()
