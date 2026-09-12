const fs = require('fs');

let content = fs.readFileSync('seed_timetable.js', 'utf8');

const timeMap = {
  '09:00': '08:30',
  '10:00': '09:30',
  '11:00': '10:30',
  '11:15': '10:45',
  '12:15': '11:45',
  '13:15': '12:45',
  '14:00': '13:30',
  '15:00': '14:30',
  '16:00': '15:30'
};

for (const [oldT, newT] of Object.entries(timeMap)) {
  content = content.replace(new RegExp(oldT, 'g'), newT);
}

fs.writeFileSync('seed_timetable.js', content);
console.log('Updated seed_timetable.js timings.');
