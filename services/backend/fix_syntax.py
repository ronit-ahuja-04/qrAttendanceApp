import re

with open('index.js', 'r') as f:
    content = f.read()

bad_snippet = """});
  }

  const groupId = uuidv4();
  const now = new Date().toISOString();

  try {
    const results = [];
    for (const t of targets) {"""

good_snippet = """});

app.post('/sessions/bulk', async (req, res) => {
  const { proxyFacultyId, targets } = req.body;
  if (!targets || !Array.isArray(targets) || targets.length === 0) {
    return res.status(400).json({ error: 'No targets provided' });
  }

  const groupId = uuidv4();
  const now = new Date().toISOString();

  try {
    const results = [];
    for (const t of targets) {"""

if bad_snippet in content:
    content = content.replace(bad_snippet, good_snippet)
    with open('index.js', 'w') as f:
        f.write(content)
    print("Fixed syntax error.")
else:
    print("Snippet not found.")

