const fs = require('fs');
let code = fs.readFileSync('index.js', 'utf8');

const target = `  } else {
    // Return relative URL for local dev so client can prepend baseUrl
    url = \`/uploads/\${req.file.filename}\`;
  }`;

const replacement = `  } else {
    // Fallback: Write buffer to disk if memory storage was used
    if (!req.file.filename && req.file.buffer) {
      const ext = require('path').extname(req.file.originalname);
      const filename = require('crypto').randomUUID() + ext;
      if (!require('fs').existsSync('uploads')) require('fs').mkdirSync('uploads');
      require('fs').writeFileSync('uploads/' + filename, req.file.buffer);
      url = \`/uploads/\${filename}\`;
    } else {
      url = \`/uploads/\${req.file.filename}\`;
    }
  }`;

code = code.replace(target, replacement);

fs.writeFileSync('index.js', code);
console.log('Fixed upload fallback');
