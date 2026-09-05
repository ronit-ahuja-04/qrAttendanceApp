const axios = require('axios');
const fs = require('fs');

async function testFlow() {
  const url = 'http://localhost:3000';
  console.log('Testing flow...');
  
  try {
    // 1. Login
    const loginRes = await axios.post(`${url}/login`, {
      email: 'ronit.ahuja@ves.ac.in', // Or whatever test user is in DB
      password: 'password123'
    });
    console.log('Login status:', loginRes.status);
    const token = loginRes.data.token;
    const userId = loginRes.data.user.id;
    
    // 2. Add Timetable slot
    const ttRes = await axios.post(`${url}/api/timetable`, {
      facultyId: userId,
      day: 'Monday',
      subject: 'Test Subject',
      type: 'Lecture',
      batchTarget: 'Test Batch',
      venue: 'Room 101',
      startTime: '10:00'
    }, {
      headers: { Authorization: `Bearer ${token}` }
    });
    console.log('Add Timetable status:', ttRes.status);
    
    // 3. Remove Profile Picture
    const rmPicRes = await axios.delete(`${url}/users/${userId}/profile-picture`, {
      headers: { Authorization: `Bearer ${token}` }
    });
    console.log('Remove Profile Pic status:', rmPicRes.status);

    console.log('Flow check complete and successful!');
  } catch (err) {
    console.error('Error in flow:', err.response ? err.response.data : err.message);
  }
}

testFlow();
