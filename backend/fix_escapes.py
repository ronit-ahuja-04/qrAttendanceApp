with open('index.js', 'r') as f:
    content = f.read()

content = content.replace('\\`', '`')
content = content.replace('\\$', '$')

with open('index.js', 'w') as f:
    f.write(content)
