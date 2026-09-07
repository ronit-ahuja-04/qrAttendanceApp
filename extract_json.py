import json

with open('/Users/ronitahuja/.gemini/antigravity-ide/brain/f086623e-434b-49d3-ae9c-a2fcbce570ea/.system_generated/logs/transcript_full.jsonl', 'r') as f:
    lines = f.readlines()

for line in reversed(lines):
    data = json.loads(line)
    if data.get('type') == 'USER_INPUT' and 'schemaVersion' in data.get('content', ''):
        content = data['content']
        start_idx = content.find('{')
        end_idx = content.rfind('}')
        if start_idx != -1 and end_idx != -1:
            json_str = content[start_idx:end_idx+1]
            with open('d15a.json', 'w') as out:
                out.write(json_str)
            print("Successfully extracted JSON! Length:", len(json_str))
            break
