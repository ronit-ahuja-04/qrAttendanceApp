const fs = require('fs');
let code = fs.readFileSync('index.js', 'utf8');

code = code.replace(/ORDER BY CAST\(rollNo AS INTEGER\) ASC/g, "ORDER BY rollNo ASC");

fs.writeFileSync('index.js', code);
console.log('Fixed CAST in report endpoints');
