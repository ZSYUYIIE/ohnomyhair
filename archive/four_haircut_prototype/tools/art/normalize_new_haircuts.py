"""Normalize the generated two-row haircut sheet into the existing 136x128 frame format.

Source and prompt provenance: docs/art/four_haircuts.md. Pillow only; no network/API calls.
"""
from pathlib import Path
from statistics import median
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / 'art_src/characters/four_haircuts_sheet.png'
CELL = (136, 128)

def main():
    sheet = Image.open(SOURCE).convert('RGBA')
    width, height = sheet.size
    for row, name in enumerate(('afro', 'long_straight')):
        sources = []
        faces = []
        for col in range(6):
            im = sheet.crop((round(col*width/6), round(row*height/2), round((col+1)*width/6), round((row+1)*height/2)))
            pixels = list(im.get_flattened_data() if hasattr(im, 'get_flattened_data') else im.getdata())
            im.putdata([(r,g,b,255 if a>200 else a) if a>=80 else (0,0,0,0) for r,g,b,a in pixels])
            face = Image.new('L', im.size)
            clean = list(im.get_flattened_data() if hasattr(im, 'get_flattened_data') else im.getdata())
            face.putdata([255 if a>128 and r>200 and g>185 and b>145 and r>b else 0 for r,g,b,a in clean])
            face_box = face.getbbox()
            if not face_box:
                raise ValueError(f'{name} pose {col}: no cream face detected')
            sources.append(im)
            faces.append(face_box)
        scale = 18 / median(b[3]-b[1] for b in faces)
        strip = Image.new('RGBA', (CELL[0]*6, CELL[1]))
        for col, (im, face_box) in enumerate(zip(sources, faces)):
            box = im.getbbox()
            cropped = im.crop(box)
            normalized = cropped.resize((round(cropped.width*scale), round(cropped.height*scale)), Image.Resampling.LANCZOS)
            x = round(74 - ((face_box[0]+face_box[2])/2-box[0])*scale)
            y = 104 - normalized.height
            if col == 3:
                face_y = ((face_box[1]+face_box[3])/2-box[1])*scale
                y = round(67-face_y)
            if x<0 or x+normalized.width>136 or y<0 or y+normalized.height>128:
                raise ValueError(f'{name} pose {col}: sprite exceeds cell bounds')
            strip.alpha_composite(normalized, (col*136+x,y))
        out = ROOT / 'assets/art/characters' / name
        out.mkdir(parents=True, exist_ok=True)
        strip.save(out/'poses.png')
        entries = ['[gd_resource type="SpriteFrames" load_steps=8 format=3]', '', '[ext_resource type="Texture2D" path="res://assets/art/characters/%s/poses.png" id="1"]' % name]
        for i in range(6):
            entries += ['', f'[sub_resource type="AtlasTexture" id="Frame{i}"]', 'atlas = ExtResource("1")', f'region = Rect2({i*136}, 0, 136, 128)']
        anims = {'idle':([0],6), 'run':([1,2],12), 'jump':([3],1), 'fall':([3],1), 'hang':([3],1)}
        anims.update({'guard':([4],1),'bounce':([5],1),'wet':([4],1)} if name=='afro' else {'rope':([4],1),'lasso':([5],1)})
        serialized = []
        for anim, (frames, fps) in anims.items():
            data = ', '.join('{"duration": 1.0, "texture": SubResource("Frame%d")}' % i for i in frames)
            serialized.append('{"frames": [%s], "loop": true, "name": &"%s", "speed": %s.0}' % (data,anim,fps))
        entries += ['', '[resource]', 'animations = [' + ',\n'.join(serialized) + ']']
        (out/'frames.tres').write_text('\n'.join(entries)+'\n', encoding='utf-8')
        print(f'{name}: {strip.size}, 6 poses, scale {scale:.3f}')

if __name__=='__main__':
    main()
