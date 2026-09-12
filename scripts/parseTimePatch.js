const fs = require('fs');
let code = fs.readFileSync('backend/index.js', 'utf8');

const parseTimeFunc = `
function parseTimeStr(tStr) {
  if (!tStr) return 0;
  const parts = tStr.trim().split(' ');
  const hm = parts[0].split(':').map(Number);
  let hr = hm[0] || 0;
  const min = hm[1] || 0;
  if (parts.length > 1) {
    const ampm = parts[1].toUpperCase();
    if (ampm === 'PM' && hr < 12) hr += 12;
    if (ampm === 'AM' && hr === 12) hr = 0;
  }
  return hr * 60 + min;
}
`;

// Replace checkTimetableOverlap
const overlapRegex = /function checkTimetableOverlap\([\s\S]*?Math\.max\(newStart, slotStart\) < Math\.min\(newEnd, slotEnd\);/m;
const overlapReplacement = `function checkTimetableOverlap(facultyId, day, batchTarget, startTime, endTime, excludeId, callback) {
  db.all('SELECT ts.*, u.name as facultyName FROM timetable_slots ts JOIN users u ON ts.facultyId = u.id WHERE ts.day = ?', [day], (err, slots) => {
    if (err) return callback(err, null);
    
    const newStart = parseTimeStr(startTime);
    const newEnd = parseTimeStr(endTime);

    for (const slot of slots) {
      if (excludeId && slot.id === excludeId) continue;
      
      const st = slot.startTime || '00:00';
      const et = slot.endTime || '00:00';
      const slotStart = parseTimeStr(st);
      const slotEnd = parseTimeStr(et);
      
      const overlaps = Math.max(newStart, slotStart) < Math.min(newEnd, slotEnd);`;

if (!code.includes('function parseTimeStr')) {
    code = code.replace('function checkTimetableOverlap', parseTimeFunc + '\n' + overlapReplacement.split('\n')[0]);
    code = code.replace(overlapRegex, overlapReplacement);
    fs.writeFileSync('backend/index.js', code);
    console.log("Patched overlap logic.");
} else {
    console.log("Already patched.");
}
