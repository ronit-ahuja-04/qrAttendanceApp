import re
import sys

filepath = 'api_services.dart'
with open(filepath, 'r') as f:
    content = f.read()

# Replace specific http calls with httpClient
content = re.sub(r'await http\.get\(', 'await httpClient.get(', content)
content = re.sub(r'await http\.post\(', 'await httpClient.post(', content)
content = re.sub(r'await http\.put\(', 'await httpClient.put(', content)
content = re.sub(r'await http\.delete\(', 'await httpClient.delete(', content)

# But we need to make sure we don't accidentally replace something else, 
# although we regex'ed exactly the function calls.

with open(filepath, 'w') as f:
    f.write(content)

print("Rewrote http calls to httpClient successfully!")
