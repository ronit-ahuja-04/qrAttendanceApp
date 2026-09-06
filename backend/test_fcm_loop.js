require('dotenv').config();
const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');
const { createClient } = require('@libsql/client');

// Initialize Firebase Admin
const serviceAccountPath = path.join(__dirname, 'firebase-service-account.json');
if (fs.existsSync(serviceAccountPath)) {
  const serviceAccount = require(serviceAccountPath);
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
  });
} else {
  process.exit(1);
}

// Initialize DB
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

  console.log(`Will send notifications to ${user.name}...`);
  let count = 0;
  
  const interval = setInterval(async () => {
    count++;
    if (count > 12) {
      clearInterval(interval);
      console.log("Done.");
      return;
    }
    
    const payload = {
      notification: {
        title: `Foreground Test ${count}`,
        body: "If you see this, the token works!",
      },
      data: {
        type: "TEST",
        click_action: "FLUTTER_NOTIFICATION_CLICK"
      },
      android: {
        priority: 'high',
      },
      token: user.fcmToken
    };

    try {
      await admin.messaging().send(payload);
      console.log(`Sent message ${count} successfully.`);
    } catch (e) {
      console.error(`Failed on message ${count}:`, e.message);
    }
  }, 5000);
}

run();
