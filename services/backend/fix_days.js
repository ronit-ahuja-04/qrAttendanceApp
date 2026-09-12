const fs = require('fs');
let code = fs.readFileSync('seed_timetable.js', 'utf8');
code = code.replace(/'Monday'/g, "'Mon'");
code = code.replace(/'Tuesday'/g, "'Tue'");
code = code.replace(/'Wednesday'/g, "'Wed'");
code = code.replace(/'Thursday'/g, "'Thu'");
code = code.replace(/'Friday'/g, "'Fri'");
fs.writeFileSync('seed_timetable.js', code);
console.log("Fixed days!");
