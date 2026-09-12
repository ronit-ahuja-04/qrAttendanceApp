const fs = require('fs');
const lines = fs.readFileSync('backend/index.js', 'utf8').split('\n');
let depth = 0;
for (let i = 1144; i < 1260; i++) {
  const line = lines[i];
  let localDepth = depth;
  for (let char of line) {
    if (char === '{') depth++;
    if (char === '}') depth--;
  }
  console.log(`Line ${i+1} [${localDepth}->${depth}]: ${line}`);
}
