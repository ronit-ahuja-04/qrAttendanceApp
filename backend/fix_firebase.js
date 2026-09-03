const fs = require('fs');
let code = fs.readFileSync('index.js', 'utf8');

code = code.replace(
  'if (isProduction) {',
  `if (isProduction && admin.apps.length > 0) {`
);

fs.writeFileSync('index.js', code);
console.log('Fixed firebase fallback');
