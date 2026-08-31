const http = require('http');

const baseURL = 'http://localhost:3000';

function makeRequest(path, method, body = null) {
  return new Promise((resolve, reject) => {
    const options = {
      hostname: 'localhost',
      port: 3000,
      path: path,
      method: method,
      headers: {
        'Content-Type': 'application/json',
      }
    };
    
    const req = http.request(options, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        try {
          resolve({ status: res.statusCode, data: JSON.parse(data) });
        } catch(e) {
          resolve({ status: res.statusCode, data });
        }
      });
    });
    
    req.on('error', reject);
    
    if (body) req.write(JSON.stringify(body));
    req.end();
  });
}

async function runTests() {
  console.log("--- Starting Dry Run Tests ---");
  
  // 1. Get Timetable to find realistic targets
  const timetableRes = await makeRequest('/timetable', 'GET');
  if (timetableRes.status !== 200) {
    console.log("Failed to fetch timetable:", timetableRes.status);
    return;
  }
  const timetable = timetableRes.data;
  if (timetable.length === 0) {
    console.log("Timetable is empty. Cannot dry run.");
    return;
  }
  
  const target1 = timetable[0];
  const target2 = timetable.length > 1 ? timetable[1] : timetable[0];
  
  console.log(`Using targets: \n1: ${target1.subject} - ${target1.batchTarget} \n2: ${target2.subject} - ${target2.batchTarget}`);
  
  // 2. Create Combined Seminar
  const seminarBody = {
    proxyFacultyId: target1.facultyId, // assuming proxy is faculty 1
    targets: [
      {
        courseCode: target1.subject,
        batchTarget: target1.batchTarget,
        originalFacultyId: target1.facultyId,
      },
      {
         courseCode: target2.subject,
         batchTarget: target2.batchTarget,
         originalFacultyId: target2.facultyId,
      }
    ]
  };
  
  console.log("\n[TEST 1] Creating Combined Seminar...");
  const seminarRes = await makeRequest('/sessions/seminar', 'POST', seminarBody);
  console.log(`Status: ${seminarRes.status}`);
  if (seminarRes.status !== 200) {
     console.log(seminarRes.data);
     return;
  }
  
  const groupId = seminarRes.data.id;
  console.log(`Generated Group ID: ${groupId}`);
  console.log(`Targets Created: ${seminarRes.data.targets.length}`);
  
  // 3. Start Session (Generate QR)
  console.log(`\n[TEST 2] Starting Session (Generating QR for Group)...`);
  const startRes = await makeRequest(`/api/sessions/${groupId}/start`, 'POST', { totalSessionSeconds: 300 });
  console.log(`Status: ${startRes.status}`);
  if (startRes.status !== 200) {
     console.log(startRes.data);
     return;
  }
  const qrCode = startRes.data.qrCode.code;
  console.log(`QR Code generated: ${qrCode}`);
  
  // 4. Mark Attendance
  console.log(`\n[TEST 3] Marking Attendance for Unenrolled Student (Should fail)`);
  const markResFail = await makeRequest('/api/attendance/mark', 'POST', {
    sessionId: groupId,
    studentId: 'fake-student-id',
    code: qrCode
  });
  console.log(`Status: ${markResFail.status}`);
  console.log(`Response: ${JSON.stringify(markResFail.data)}`);
  
  // Try to find a valid student for target1
  // We don't have a direct query for it here, but we tested the unenrolled edge case!
  
  console.log("\n--- Dry Run Completed ---");
}

runTests();
