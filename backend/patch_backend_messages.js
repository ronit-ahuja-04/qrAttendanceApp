const fs = require('fs');
let code = fs.readFileSync('index.js', 'utf8');

code = code.replace(
  "return res.status(400).json({ error: 'studentNotEnrolled' });",
  "return res.status(400).json({ error: 'studentNotEnrolled', message: 'You are not enrolled in this elective subject.' });"
);

code = code.replace(
  "return res.status(400).json({ error: 'invalidOtp' });",
  "return res.status(400).json({ error: 'invalidOtp', message: 'QR Code is invalid or has expired.' });"
);

code = code.replace(
  "return res.status(400).json({ error: 'otpExpired' });",
  "return res.status(400).json({ error: 'otpExpired', message: 'This QR code has expired.' });"
);

code = code.replace(
  "return res.status(400).json({ error: 'duplicateAttendance' });",
  "return res.status(400).json({ error: 'duplicateAttendance', message: 'You have already marked attendance for this session.' });"
);

fs.writeFileSync('index.js', code);
console.log("Patched messages!");
