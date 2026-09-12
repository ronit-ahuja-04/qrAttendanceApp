const fs = require('fs');
let code = fs.readFileSync('index.js', 'utf8');

code = code.replace(/role \= \'student\'\'/g, "role = \\'student\\''");
code = code.replace(/role\=\'student\'\'/g, "role=\\'student\\''");

fs.writeFileSync('index.js', code);
console.log('Fixed js syntax');
