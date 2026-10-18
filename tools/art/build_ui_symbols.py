"""Build compact OFL symbol fallbacks with the game's existing UI line metrics.

Requires fonttools. Original Noto sources are preserved in art_src/fonts.
"""
from pathlib import Path
from fontTools import subset
from fontTools.ttLib import TTFont
from fontTools.varLib.instancer import instantiateVariableFont

ROOT = Path(__file__).resolve().parents[2]
for source, name, chars in [
    ('NotoSansSymbols.ttf', 'SalonArrows', '\u2190\u2191\u2192\u2193'),
    ('NotoSansSymbols2-Regular.ttf', 'SalonIcons', '\u25b6\u2713\u2665'),
]:
    font = TTFont(ROOT / 'art_src/fonts' / source)
    if 'fvar' in font:
        font = instantiateVariableFont(font, {'wght': 500}, inplace=True)
    options = subset.Options()
    options.layout_features = []
    worker = subset.Subsetter(options=options)
    worker.populate(text=chars)
    worker.subset(font)
    # The source symbol families reserve space for large specialist glyphs. These
    # seven UI glyphs fit Fredoka's baseline, so they must not enlarge menu rows.
    font['hhea'].ascent, font['hhea'].descent, font['hhea'].lineGap = 974, -236, 0
    os2 = font['OS/2']
    os2.sTypoAscender, os2.sTypoDescender, os2.sTypoLineGap = 974, -236, 0
    os2.usWinAscent, os2.usWinDescent = 974, 236
    os2.fsSelection |= 1 << 7
    for record in font['name'].names:
        if record.nameID in (1, 3, 4, 6, 16):
            record.string = name.encode(record.getEncoding())
        elif record.nameID in (2, 17):
            record.string = 'Regular'.encode(record.getEncoding())
    output = ROOT / 'assets/fonts' / (name + '.ttf')
    font.save(output)
    print(output, output.stat().st_size)
