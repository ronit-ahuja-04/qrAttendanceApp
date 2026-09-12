const http = require('http');

const data = JSON.stringify({
  facultyId: "fac-123",
  day: "Monday",
  subject: "TEST",
  type: "Lec",
  batchTarget: "All",
  venue: "Room 1",
  startTime: "09:00"
});

const options = {
  hostname: 'qr-attendance-api-wvvs.onrender.com',
  port: 443,
  path: '/api/timetable',
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'Content-Length': data.length
  }
};

const req = require('https').request(options, res => {
  console.log(`statusCode: ${res.statusCode}`);
  res.on('data', d => {
    process.stdout.write(d);
  });
});

req.on('error', error => {
  console.error(error);
});

req.write(data);
req.end();
