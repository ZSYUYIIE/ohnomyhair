"""Draws the Level 3 salon-station props in the Level 1 doodle style: hair dryer, shower
head, growth tonic and the hot flat iron. Uses make_l1_art.py's helpers (wobbly ink
outline, flat fills, supersampled then downscaled) so everything matches the L1 props.
Style rules: docs/art/l1_art_direction.md. The moving parts stay in code: the dryer's warm
air, the shower's water and warning drips, the tonic's bob and sparkle, the iron's steam.
Output goes to assets/art/props/; rerun after changing anything here.
Run: python -I tools/art/make_salon_props.py
"""
import importlib.util
import random
from pathlib import Path

from PIL import Image

_spec = importlib.util.spec_from_file_location("l1art", Path(__file__).with_name("make_l1_art.py"))
art = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(art)

INK, CHROME, INTERACT, PROPS = art.INK, art.CHROME, art.INTERACT, art.PROPS
shape, stroke, ellipse_pts, rect_pts, mix = art.shape, art.stroke, art.ellipse_pts, art.rect_pts, art.mix
canvas, finish, wobble_path = art.canvas, art.finish, art.wobble_path

# Station colours. P1 pink and P2 blue stay reserved for the players, so the dryer is coral.
DRYER = (240, 140, 96)
WATER = (74, 163, 223)
TONIC = (168, 214, 84)
PLATE_COLD = (138, 144, 153)
PLATE_HOT = (231, 76, 60)


def hair_dryer() -> None:
    """64x64 floor-standing salon blow dryer, nozzle up. Bottom center = the dryer's base."""
    rng = random.Random(21)
    img, d = canvas(64, 64)
    shape(d, art.ellipse_pts(32, 58, 22, 5, 24), mix(CHROME, INK, 0.3), INK, 2.6, rng, 0.4)   # foot
    stroke(d, [(32, 56), (32, 34)], INK, 7)
    stroke(d, [(32, 56), (32, 34)], CHROME, 3.6)                                               # pole
    shape(d, rect_pts(14, 16, 36, 22, 9), DRYER, INK, 3, rng, 0.6)                            # body
    shape(d, rect_pts(20, 6, 24, 12, 3), mix(DRYER, INK, 0.2), INK, 2.6, rng, 0.5)            # nozzle
    for x in (26, 32, 38):                                                                     # grille
        stroke(d, [(x, 8.5), (x, 15)], INK, 1.6)
    shape(d, ellipse_pts(42, 27, 3.2, 3.2, 12), INTERACT, INK, 1.6)                            # switch
    stroke(d, wobble_path([(19, 22), (23, 31)], rng, 0.3), (255, 255, 255), 2.2)               # shine
    finish(img, 64, 64).save(PROPS / "prop_dryer.png")


def shower_head() -> None:
    """64x40 shower head hanging from a ceiling pipe. Top center = the pipe's mount."""
    rng = random.Random(22)
    img, d = canvas(64, 40)
    stroke(d, [(32, 0), (32, 14)], INK, 7)
    stroke(d, [(32, 0), (32, 14)], CHROME, 3.6)
    shape(d, [(10, 30), (54, 30), (44, 14), (20, 14)], CHROME, INK, 3, rng, 0.5)               # head
    shape(d, rect_pts(9, 28, 46, 7, 3), mix(CHROME, INK, 0.3), INK, 2.4, rng, 0.4)            # rose
    for x in (16, 24, 32, 40, 48):                                                             # holes
        shape(d, ellipse_pts(x, 31.5, 1.4, 1.4, 10), mix(WATER, INK, 0.4))
    stroke(d, wobble_path([(22, 17), (26, 26)], rng, 0.3), (255, 255, 255), 2)
    finish(img, 64, 40).save(PROPS / "prop_shower.png")


def growth_tonic() -> None:
    """24x36 hair-growth tonic bottle with a leaf label. Center = the bottle's center."""
    rng = random.Random(23)
    img, d = canvas(24, 36)
    shape(d, rect_pts(8, 2, 8, 6, 2), (163, 112, 73), INK, 2.2, rng, 0.3)                      # cork
    shape(d, rect_pts(9, 7, 6, 6, 1), mix(TONIC, (255, 255, 255), 0.3), INK, 2.2, rng, 0.3)   # neck
    shape(d, rect_pts(3, 12, 18, 22, 6), TONIC, INK, 2.8, rng, 0.5)                           # body
    shape(d, rect_pts(6, 18, 12, 10, 2), art.COUNTER, INK, 1.8, rng, 0.3)                      # label
    shape(d, [(12, 20), (15.5, 23), (12, 26.5), (8.5, 23)], mix(TONIC, INK, 0.35))             # leaf
    stroke(d, [(7, 15), (7, 30)], (255, 255, 255), 1.8)                                         # shine
    finish(img, 24, 36).save(PROPS / "prop_tonic.png")


def flat_iron() -> None:
    """Hot flat iron, 64x24 per frame: cold | red-hot. Bottom = the floor line."""
    strip = Image.new("RGBA", (128, 24), (0, 0, 0, 0))
    for i, plate in enumerate((PLATE_COLD, PLATE_HOT)):
        rng = random.Random(24)
        img, d = canvas(64, 24)
        shape(d, rect_pts(3, 14, 58, 8, 3), (60, 52, 78), INK, 2.6, rng, 0.4)                 # base
        shape(d, rect_pts(6, 8, 52, 7, 3), plate, INK, 2.4, rng, 0.4)                         # plate
        stroke(d, [(8, 9.5), (56, 9.5)], CHROME, 1.6)
        shape(d, ellipse_pts(7, 15, 5, 5, 14), (60, 52, 78), INK, 2.2)                         # hinge
        shape(d, ellipse_pts(52, 18, 2.2, 2.2, 10), PLATE_HOT if i else art.EXIT)              # light
        strip.alpha_composite(finish(img, 64, 24), (i * 64, 0))
    strip.save(PROPS / "prop_iron.png")


def main() -> None:
    PROPS.mkdir(parents=True, exist_ok=True)
    hair_dryer()
    shower_head()
    growth_tonic()
    flat_iron()
    for name in ("prop_dryer.png", "prop_shower.png", "prop_tonic.png", "prop_iron.png"):
        print("wrote", (PROPS / name).relative_to(art.ROOT))


if __name__ == "__main__":
    main()
