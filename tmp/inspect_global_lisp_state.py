import json
import re
import sys
from collections import Counter
from pathlib import Path

sys.stdout.reconfigure(encoding='utf-8')
source = Path('C:/Users/popul/OneDrive/เดสก์ท็อป/.codex-global-state.json')
data = json.loads(source.read_text(encoding='utf-8-sig'))
pattern = re.compile(r'autolisp|(?<![a-z])lisp(?![a-z])|\.lsp\b', re.I)
matches = []
group_counts = Counter()
node_count = 0
occurrence_count = 0

def walk(value, path):
    global node_count, occurrence_count
    if isinstance(value, dict):
        for key, child in value.items():
            walk(child, path + [str(key)])
    elif isinstance(value, list):
        for index, child in enumerate(value):
            walk(child, path + [str(index)])
    elif isinstance(value, str):
        found = list(pattern.finditer(value))
        if found:
            node_count += 1
            occurrence_count += len(found)
            group_counts[' / '.join(path[:3])] += 1
            excerpts = []
            for item in found[:3]:
                excerpt = value[max(0, item.start()-120): min(len(value), item.end()+220)]
                excerpts.append(excerpt)
            matches.append({'path': path, 'length': len(value), 'occurrences': len(found), 'excerpts': excerpts})

walk(data, [])
report = {
    'source': str(source),
    'top_level_keys': list(data),
    'matched_string_count': node_count,
    'total_occurrences': occurrence_count,
    'groups': group_counts.most_common(),
    'matches': matches,
}
destination = Path('C:/TA/TA_COMPELETE/tmp/global_lisp_state_inspection.json')
destination.write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding='utf-8')
print(json.dumps({k: v for k, v in report.items() if k != 'matches'}, ensure_ascii=False, indent=2))
print('FIRST_MATCHES')
print(json.dumps(matches[:12], ensure_ascii=False, indent=2))
