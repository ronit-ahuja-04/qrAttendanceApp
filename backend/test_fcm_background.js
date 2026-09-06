require('dotenv').config();
const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');
const { createClient } = require('@libsql/client');

const serviceAccountPath = path.join(__dirname, 'firebase-service-account.json');
if (fs.existsSync(serviceAccountPath)) {
  const serviceAccount = require(serviceAccountPath);
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
  });
} else {
  process.exit(1);
}

let dbClient = createClient({
  url: process.env.TURSO_DATABASE_URL,
  authToken: process.env.TURSO_AUTH_TOKEN,
});

async function run() {
  const res = await dbClient.execute("SELECT id, name, fcmToken FROM users WHERE fcmToken IS NOT NULL AND fcmToken != ''");
  const user = res.rows.find(u => u.name.includes("RONIT"));
  
  if (!user) {
    console.log("User not found.");
    return;
  }

  console.log(`Sending EXACT backend payload to ${user.name}...`);
  
  const payload = {
    notification: {
      title: "Background Test",
      body: "Did this arrive while the app was closed?",
    },
    data: {
      type: "TEST",
      message: "Hello World"
    },
    android: {
      priority: 'high',
      notification: {
        channelId: 'ams_channel_id',
        priority: 'max',
        defaultSound: true,
        defaultVibrateTimings: true,
        clickAction: 'FLUTTER_NOTIFICATION_CLICK'
      }
    },
    token: user.fcmToken
  };

  console.log(`Waiting 15 seconds to let user close the app...`);
  setTimeout(async () => {
    try {
      const response = await admin.messaging().send(payload);
      console.log(`Successfully sent:`, response);
    } catch (e) {
      console.error(`Failed:`, e);
    }
  }, 15000);
}

run();
