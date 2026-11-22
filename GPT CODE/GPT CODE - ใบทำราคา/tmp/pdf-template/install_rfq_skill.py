from pathlib import Path
import hashlib,shutil

root=Path(__file__).resolve().parents[2]
source=root/'skills/rfq-html'
personal=Path('C:/Users/popul/.codex/skills').resolve()
target=personal/'rfq-html'
assert target.resolve().parent==personal
if target.exists():raise FileExistsError(target)
expected=['SKILL.md','agents/openai.yaml','references/data-schema.md','scripts/create_rfq.py','assets/BU2-DE-26xxx-MASTER.html']
for path in expected:
    if not (source/path).is_file():raise FileNotFoundError(source/path)
shutil.copytree(source,target,ignore=shutil.ignore_patterns('__pycache__','*.pyc'))
for path in expected:
    assert hashlib.sha256((source/path).read_bytes()).digest()==hashlib.sha256((target/path).read_bytes()).digest()
print('Installed and verified: '+str(target))
