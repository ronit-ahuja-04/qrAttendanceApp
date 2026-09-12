const fs = require('fs');

let content = fs.readFileSync('seed_timetable.js', 'utf8');

const timeMap = {
  '10:45': '10:30',
  '11:45': '11:30',
  '12:45': '12:30'
};

for (const [oldT, newT] of Object.entries(timeMap)) {
  content = content.replace(new RegExp(oldT, 'g'), newT);
}

fs.writeFileSync('seed_timetable.js', content);
console.log('Fixed break times in seed_timetable.js');
