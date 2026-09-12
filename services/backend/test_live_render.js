const axios = require('axios');
const fs = require('fs');

async function testRender() {
    try {
        // We will log in as the faculty to get a token
        console.log("Logging into LIVE Render backend...");
        const loginRes = await axios.post('https://qr-attendance-api-wvvs.onrender.com/login', {
            email: 'ronit.ahuja@ves.ac.in', // Faculty email from TT tests
            password: 'password' // Assuming default test password
        });

        const token = loginRes.data.token;
        const facultyId = loginRes.data.user.id;
        console.log("Login successful! Token acquired.");

        console.log("Sending Timetable Update to D15A - All...");
        const ttRes = await axios.post('https://qr-attendance-api-wvvs.onrender.com/api/timetable', {
            facultyId: facultyId,
            day: 'Monday',
            subject: 'AI Testing 101',
            type: 'Lecture',
            batchTarget: 'D15A - All',
            venue: 'Test Lab',
            startTime: '10:00'
        }, {
            headers: { Authorization: `Bearer ${token}` }
        });

        console.log("Render API Response:", ttRes.data);
    } catch (e) {
        console.error("Error connecting to Render API:");
        if (e.response) {
            console.error(e.response.data);
        } else {
            console.error(e.message);
        }
    }
}

testRender();
