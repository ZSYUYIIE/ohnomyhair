"""Write editable SVG tile atlases; preserve the existing 32px / 4x5 collision atlas.

The overview supplies color/material reference, not production floor tiles.
No character or room-background assets are read or changed.
"""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
PALETTES = {
    "l1": ("#e6c3d4", "#fff0d7", "#c599ad", "#a96b50"),
    "l2": ("#cf936d", "#efbc8c", "#af7057", "#8e5749"),
    "l3": ("#b8dce3", "#edf5e9", "#8aafc5", "#66899e"),
    "l4": ("#b69ab8", "#e2c5c8", "#8f729f", "#79536d"),
}


def atlas(palette: tuple[str, ...]) -> str:
    body, alternate, shade, trim = palette
    parts = ['<svg xmlns="http://www.w3.org/2000/svg" width="128" height="160" viewBox="0 0 128 160">',
             '<defs>',
             f'<linearGradient id="body" x2="0" y2="1"><stop stop-color="{body}"/><stop offset="1" stop-color="{shade}"/></linearGradient>',
             '<linearGradient id="top" x2="0" y2="1"><stop stop-color="#fffdf1"/><stop offset=".55" stop-color="#fff0ce"/><stop offset="1" stop-color="#dbb78e"/></linearGradient>',
             '</defs>']
    for index in range(20):
        x, y = index % 4 * 32, index // 4 * 32
        parts.append(f'<g transform="translate({x} {y})">')
        if index == 19:
            parts += [f'<rect y="4" width="32" height="18" rx="2" fill="{trim}"/>',
                      '<rect y="1" width="32" height="8" fill="url(#top)"/>',
                      '<path d="M0 1H32M0 22H32" fill="none" stroke="#35203e" stroke-width="2"/>']
        else:
            mask = index if index < 16 else 15
            parts += ['<rect width="32" height="32" fill="url(#body)"/>',
                      f'<path d="M0 0H16V16H0ZM16 16H32V32H16Z" fill="{alternate}" opacity=".66"/>',
                      '<path d="M0 16H32M16 0V32" stroke="#fff6e7" opacity=".35" stroke-width="1"/>']
            if not mask & 1:
                parts += ['<rect y="1" width="32" height="9" fill="url(#top)"/>',
                          '<path d="M0 1H32" stroke="#35203e" stroke-width="2"/>',
                          f'<path d="M0 11H32" stroke="{trim}" stroke-width="2"/>']
            for bit, path, highlight in [(8, "M1 0V32", "M4 0V32"), (2, "M31 0V32", "M28 0V32"), (4, "M0 31H32", "M0 28H32")]:
                if not mask & bit:
                    parts += [f'<path d="{path}" stroke="#35203e" stroke-width="2"/>',
                              f'<path d="{highlight}" stroke="{trim}" stroke-width="2"/>']
        parts.append('</g>')
    return '\n'.join(parts + ['</svg>', ''])


if __name__ == '__main__':
    for chapter, palette in PALETTES.items():
        target = ROOT / 'assets' / 'art' / chapter / 'tiles_poster.svg'
        target.write_text(atlas(palette), encoding='utf-8')
        print(target.relative_to(ROOT))
