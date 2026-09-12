"""Create a source-only portable ZIP; developer utility (Python not required by users)."""
from pathlib import Path
import hashlib
import json
import re
import sys
import zipfile

root = Path(__file__).resolve().parents[1]
output = Path(sys.argv[1]).resolve()
output.mkdir(parents=True, exist_ok=True)
version = json.loads((root / '.codex-plugin/plugin.json').read_text())['version'].split('+')[0]
archive = output / f'discord-call-bridge-{version}-windows.zip'
allowed_roots = {'.codex-plugin', 'skills', 'scripts', 'config', 'tests'}
allowed_top = {'README.md', 'RESTORE.md', 'VALIDATION.md', 'Setup.cmd', '.gitignore', 'LICENSE'}
files = []
for path in root.rglob('*'):
    if not path.is_file():
        continue
    rel = path.relative_to(root)
    if rel.parts[0] not in allowed_roots and str(rel) not in allowed_top:
        continue
    if path.suffix not in {'.md', '.json', '.ps1', '.psm1', '.cmd', '.py'} and path.name not in {'.gitignore', 'LICENSE'}:
        raise ValueError(f'Unexpected release file: {rel}')
    if '__pycache__' in rel.parts or path.is_symlink():
        raise ValueError(f'Unexpected generated/link file: {rel}')
    body = path.read_text(encoding='utf-8-sig')
    prohibited = [r'C:[\\/]Users[\\/]', r'gh[pousr]_[A-Za-z0-9]{20,}', r'(?i)BEGIN .*PRIVATE KEY', r'\b[0-9a-f]{8}(?:-[0-9a-f]{4}){3}-[0-9a-f]{12}\b']
    if path.name != 'build_release.py' and any(re.search(pattern, body, re.I) for pattern in prohibited):
        raise ValueError(f'Possible machine/private data: {rel}')
    files.append((path, rel))
with zipfile.ZipFile(archive, 'w', compression=zipfile.ZIP_DEFLATED) as bundle:
    for path, rel in sorted(files):
        bundle.write(path, (Path(root.name) / rel).as_posix())
with zipfile.ZipFile(archive) as bundle:
    assert bundle.testzip() is None
checksum = hashlib.sha256(archive.read_bytes()).hexdigest()
(output / (archive.name + '.sha256')).write_text(f'{checksum}  {archive.name}\n', encoding='ascii')
print(f'{archive}\n{len(files)} files\nSHA256 {checksum}')
