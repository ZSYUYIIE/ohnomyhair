import io, urllib.request, zipfile
from pathlib import Path

URL = 'https://godot-releases.nbg1.your-objectstorage.com/4.7.2-stable/Godot_v4.7.2-stable_export_templates.tpz'
class RemoteZip(io.RawIOBase):
    def __init__(self):
        self.length = int(urllib.request.urlopen(urllib.request.Request(URL, method='HEAD')).headers['Content-Length'])
        self.position = 0
    def seekable(self): return True
    def tell(self): return self.position
    def seek(self, offset, whence=0):
        self.position = offset if whence == 0 else self.position + offset if whence == 1 else self.length + offset
        return self.position
    def read(self, size=-1):
        if size < 0: size = self.length - self.position
        if not size: return b''
        request = urllib.request.Request(URL, headers={'Range': f'bytes={self.position}-{self.position+size-1}'})
        with urllib.request.urlopen(request, timeout=120) as response:
            if response.status != 206: raise RuntimeError('Server did not honor the byte range')
            data = response.read()
        self.position += len(data)
        return data

with zipfile.ZipFile(RemoteZip()) as archive:
    names = [n for n in archive.namelist() if 'web' in n or n.endswith('version.txt')]
    print('\n'.join(names), flush=True)
    for name in names:
        if name == 'templates/web_nothreads_release.zip':
            target = Path('.godot/export-tools') / Path(name).name
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_bytes(archive.read(name))
            print(f'Downloaded {target}: {target.stat().st_size} bytes', flush=True)
