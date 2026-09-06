require('dotenv').config();
const { createClient } = require('@libsql/client');

let dbClient = createClient({
  url: process.env.TURSO_DATABASE_URL,
  authToken: process.env.TURSO_AUTH_TOKEN,
});

async function run() {
  const res = await dbClient.execute("SELECT id, name, role, batch, division FROM users WHERE name LIKE '%RONIT%'");
  res.rows.forEach(r => {
    console.log(`User: ${r.name}`);
    console.log(`Role: ${r.role}`);
    console.log(`Batch: ${r.batch}`);
    console.log(`Division: ${r.division}`);
    console.log('---');
  });
}

run();
