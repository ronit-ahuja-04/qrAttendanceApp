require('dotenv').config();
const { createClient } = require('@libsql/client');

let dbClient = createClient({
  url: process.env.TURSO_DATABASE_URL,
  authToken: process.env.TURSO_AUTH_TOKEN,
});

async function run() {
  const res = await dbClient.execute("SELECT id, name, notificationPrefs FROM users WHERE name LIKE '%RONIT%'");
  res.rows.forEach(r => {
    console.log(`User: ${r.name}`);
    console.log(`Prefs: ${r.notificationPrefs}`);
    console.log('---');
  });
}

run();
