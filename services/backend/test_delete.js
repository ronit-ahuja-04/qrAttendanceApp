const axios = require('axios');
async function run() {
  try {
    const loginRes = await axios.post('http://localhost:3000/login', { email: 'ronit.ahuja@ves.ac.in', password: 'password123' });
    const token = loginRes.data.token;
    
    // Create a slot
    const addRes = await axios.post('http://localhost:3000/api/timetable', {
      facultyId: loginRes.data.user.id, day: 'Wednesday', subject: 'Delete Test', type: 'Lecture', batchTarget: 'D10 - All', venue: 'M2', startTime: '12:00', endTime: '13:00'
    }, { headers: { Authorization: `Bearer ${token}` } });
    
    const slotId = addRes.data.id;
    console.log("Added slot:", slotId);
    
    // Delete it
    const delRes = await axios.delete(`http://localhost:3000/api/timetable/${slotId}`, { headers: { Authorization: `Bearer ${token}` } });
    console.log("Delete status:", delRes.status);
    
    // Get timetable immediately
    const getRes = await axios.get(`http://localhost:3000/timetable/${loginRes.data.user.id}`);
    console.log("Timetable size:", getRes.data.length);
  } catch(e) {
    console.error(e.response ? e.response.data : e.message);
  }
}
run();
