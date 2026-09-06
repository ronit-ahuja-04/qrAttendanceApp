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
  console.error("firebase-service-account.json not found!");
  process.exit(1);
}

// Initialize DB
let dbClient;
if (process.env.TURSO_DATABASE_URL && process.env.TURSO_AUTH_TOKEN) {
  dbClient = createClient({
    url: process.env.TURSO_DATABASE_URL,
    authToken: process.env.TURSO_AUTH_TOKEN,
  });
} else {
  // Try local fallback
  const sqlite3 = require('sqlite3').verbose();
  dbClient = {
    execute: (query) => {
      return new Promise((resolve, reject) => {
        const db = new sqlite3.Database(path.join(__dirname, 'database.sqlite'));
        db.all(query, (err, rows) => {
          if (err) reject(err);
          else resolve({ rows });
        });
      });
    }
  };
}

async function run() {
  try {
    const res = await dbClient.execute("SELECT id, name, fcmToken FROM users WHERE fcmToken IS NOT NULL AND fcmToken != '' LIMIT 5");
    const users = res.rows;
    if (users.length === 0) {
      console.log("No users with FCM tokens found.");
      return;
    }

    console.log(`Found ${users.length} users with tokens. Sending test message...`);

    for (const user of users) {
      console.log(`Sending to ${user.name} (${user.id}) - Token: ${user.fcmToken.substring(0, 20)}...`);
      
      const payload = {
        notification: {
          title: "Test Notification",
          body: "This is a test notification to check FCM delivery.",
        },
        data: {
          type: "TEST",
          click_action: "FLUTTER_NOTIFICATION_CLICK"
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

      try {
        const response = await admin.messaging().send(payload);
        console.log(`Successfully sent to ${user.name}:`, response);
      } catch (e) {
        console.error(`Failed to send to ${user.name}:`, e);
      }
    }
  } catch (e) {
    console.error("DB Error:", e);
  }
}

run();
