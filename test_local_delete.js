const axios = require('axios');
async function run() {
  try {
    const loginRes = await axios.post('http://localhost:3000/login', { email: 'prof.ps@ves.ac.in', password: 'pass123' });
    const token = loginRes.data.token;
    const userId = loginRes.data.user.id;
    console.log("Logged in:", userId);
    
    // Add slot
    const addRes = await axios.post('http://localhost:3000/api/timetable', {
      facultyId: userId, day: 'Wednesday', subject: 'Delete Test', type: 'Lecture', batchTarget: 'D10 - All', venue: 'M2', startTime: '12:00'
    }, { headers: { Authorization: `Bearer ${token}` } });
    const slotId = addRes.data.id;
    console.log("Added slot:", slotId);
    
    // Check it's there
    let getRes = await axios.get(`http://localhost:3000/timetable/${userId}`);
    console.log("Slots before delete:", getRes.data.filter(s => s.id === slotId).length);
    
    // Delete it
    const delRes = await axios.delete(`http://localhost:3000/api/timetable/${slotId}`, { headers: { Authorization: `Bearer ${token}` } });
    console.log("Delete status:", delRes.status);
    
    // Check it's gone IMMEDIATELY
    try {
      getRes = await axios.get(`http://localhost:3000/timetable/${userId}`);
      console.log("Slots after delete:", getRes.data.filter(s => s.id === slotId).length);
    } catch(e) {
      console.log("IMMEDIATE GET FAILED:", e.response ? e.response.data : e.message);
    }
  } catch(e) {
    console.error(e.response ? e.response.data : e.message);
  }
}
run();
