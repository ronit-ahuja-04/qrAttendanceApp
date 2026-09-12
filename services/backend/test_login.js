const http = require('https');

const data = JSON.stringify({
  email: 'f1@example.com',
  password: 'password123'
});

const options = {
  hostname: 'qr-attendance-api-wvvs.onrender.com',
  path: '/login',
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'Content-Length': data.length
  }
};

const req = http.request(options, (res) => {
  let resData = '';
  res.on('data', chunk => resData += chunk);
  res.on('end', () => {
    console.log('Login status:', res.statusCode);
    try {
      const parsed = JSON.parse(resData);
      console.log('Token received:', parsed.token ? 'YES' : 'NO');
      
      if (parsed.token) {
        // Fetch timetable
        const tReq = http.request({
          hostname: 'qr-attendance-api-wvvs.onrender.com',
          path: '/timetable/' + parsed.id,
          method: 'GET',
          headers: {
            'Authorization': 'Bearer ' + parsed.token
          }
        }, (tRes) => {
          let tData = '';
          tRes.on('data', chunk => tData += chunk);
          tRes.on('end', () => console.log('Timetable Status:', tRes.statusCode, 'Data length:', tData.length, 'Data:', tData.substring(0, 200)));
        });
        tReq.end();
      }
    } catch(e) {
      console.log('Error:', e.message, resData);
    }
  });
});

req.write(data);
req.end();
