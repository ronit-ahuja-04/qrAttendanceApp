const fs = require('fs');
const code = fs.readFileSync('index.js', 'utf8');
let depth = 0;
const lines = code.split('\n');
for (let i = 0; i < lines.length; i++) {
  const line = lines[i];
  // ignore comments and strings for a naive count
  // actually, let's just use acorn to parse
}
