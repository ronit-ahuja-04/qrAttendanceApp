require('dotenv').config();
const { createClient } = require('@libsql/client');
const admin = require('firebase-admin');

// 1. Initialize Firebase
let serviceAccount;
try {
  serviceAccount = require('./firebase-service-account.json');
} catch(e) {
  console.log("No service account json found locally");
  process.exit(1);
}
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

// 2. Initialize DB
let dbClient = createClient({
  url: process.env.TURSO_DATABASE_URL,
  authToken: process.env.TURSO_AUTH_TOKEN,
});

async function run() {
  console.log("Simulating notifyTimetableUpdate for D15A...");
  
  // Find students in D15A
  const res = await dbClient.execute("SELECT id, name, fcmToken, notificationPrefs, division, coreBatch, electiveBatch FROM users WHERE role = 'student'");
  
  const targetStudents = res.rows.filter(s => {
      // Simulate slot.batchTarget = 'D15A - All'
      const target = 'D15A - All';
      if (!s.division || !target.includes(s.division)) return false;
      if (target.includes('All')) return true;
      if (s.coreBatch && target.includes(s.coreBatch)) return true;
      if (s.electiveBatch && target.includes(s.electiveBatch)) return true;
      return false;
  });

  console.log(`Found ${targetStudents.length} students matching D15A - All.`);
  
  for (const student of targetStudents) {
      if (!student.fcmToken) {
          console.log(`Student ${student.name} has no FCM token. Skipping.`);
          continue;
      }
      
      let prefs = { notif_master: true };
      if (student.notificationPrefs) {
          prefs = JSON.parse(student.notificationPrefs);
      }
      if (prefs.notif_master === false) {
          console.log(`Student ${student.name} has disabled notifications. Skipping.`);
          continue;
      }

      console.log(`Sending simulated timetable push to: ${student.name}`);
      
      const stringifiedData = {
          type: 'TIMETABLE_UPDATED',
          click_action: 'FLUTTER_NOTIFICATION_CLICK'
      };

      const message = {
          notification: { title: "SIMULATED TIMETABLE", body: "This is a simulated timetable notification from your AI assistant!" },
          data: stringifiedData,
          token: student.fcmToken,
          apns: {
            payload: {
              aps: {
                sound: 'default',
                contentAvailable: true,
              }
            }
          }
      };

      try {
          const response = await admin.messaging().send(message);
          console.log(`Successfully sent message to ${student.name}:`, response);
      } catch (error) {
          console.log(`Error sending message to ${student.name}:`, error);
      }
  }
}

run();
