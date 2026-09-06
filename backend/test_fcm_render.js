require('dotenv').config();
const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');
const { createClient } = require('@libsql/client');

const serviceAccountPath = path.join(__dirname, 'firebase-service-account.json');
if (fs.existsSync(serviceAccountPath)) {
  const serviceAccount = require(serviceAccountPath);
  if (admin.apps.length === 0) {
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount)
    });
  }
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

  console.log(`Sending RENDER payload to ${user.name}...`);
  
  const payload = {
    notification: {
      title: "Render Test",
      body: "If this arrives, the Render backend payload is perfect!",
    },
    data: {
      type: "TEST",
      click_action: "FLUTTER_NOTIFICATION_CLICK"
    },
    android: {
      priority: 'high'
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
