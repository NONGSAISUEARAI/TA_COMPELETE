import json
import sys
from pathlib import Path

sys.stdout.reconfigure(encoding='utf-8')
source = Path('C:/Users/popul/OneDrive/เดสก์ท็อป/GPT BACKUP/.codex-global-state.json')
data = json.loads(source.read_text(encoding='utf-8-sig'))
atoms = data.get('electron-persisted-atom-state', {})
report = {'source': str(source), 'prompt_history': {}, 'thread_descriptions': atoms.get('thread-descriptions-v1', {}), 'projects': data.get('local-projects', {})}
for thread, items in atoms.get('prompt-history', {}).items():
    prompts = []
    for index, item in enumerate(items):
        if isinstance(item, str):
            content = item
        elif isinstance(item, dict):
            content = item.get('markdown', '')
            if not content:
                content = item.get('text', '')
        else:
            continue
        if content:
            prompts.append({'index': index, 'text': content[:15000], 'truncated': len(content) > 15000})
    report['prompt_history'][thread] = prompts
report['workspace_context'] = {key: data.get(key) for key in ['selected-project', 'thread-workspace-root-hints', 'thread-project-assignments', 'thread-project-membership-host-ids']}
report['preference_keys'] = {key: {'type': type(value).__name__, 'count': len(value) if hasattr(value, '__len__') else None} for key, value in atoms.items() if any(word in key.lower() for word in ['prompt', 'history', 'memor', 'instruct', 'personal', 'workspace', 'description']) and 'models' not in key}
target = Path('C:/TA/TA_COMPELETE/tmp/old_codex_work_context.json')
target.write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding='utf-8')
print(json.dumps({'source': str(source), 'text_report': str(target), 'report_bytes': target.stat().st_size, 'preference_keys': report['preference_keys'], 'prompt_counts': {key: len(value) for key, value in report['prompt_history'].items()}, 'description_count': len(report['thread_descriptions']), 'project_count': len(report['projects'])}, ensure_ascii=False, indent=2))
