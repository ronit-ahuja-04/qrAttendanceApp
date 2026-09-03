const fs = require('fs');
let code = fs.readFileSync('index.js', 'utf8');

// 1. Fix "createdAt" and "slotId"
code = code.replace(/"slotId"/g, 'slotId');
code = code.replace(/"createdAt"::timestamp/g, 'createdAt');

// 2. Fix role = "student"
code = code.replace(/role \= "student"/g, "role = 'student'");
code = code.replace(/role=\"student\"/g, "role='student'");

fs.writeFileSync('index.js', code);
console.log('Fixed quotes in index.js');
