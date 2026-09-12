const fs = require('fs');
let code = fs.readFileSync('index.js', 'utf8');

const target = `    '/reset-password',
    '/change-password'
  ];`;

const replacement = `    '/reset-password',
    '/change-password',
    '/timetable'
  ];`;

code = code.replace(target, replacement);
fs.writeFileSync('index.js', code);
console.log('Added /timetable to public paths');
