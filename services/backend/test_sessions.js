const { createClient } = require('@libsql/client');
require('dotenv').config();

const db = createClient({
  url: process.env.TURSO_DATABASE_URL,
  authToken: process.env.TURSO_AUTH_TOKEN
});

async function run() {
  const res = await db.execute("SELECT id, facultyId, proxyFacultyId, courseCode, batchTarget, createdAt FROM sessions ORDER BY createdAt DESC LIMIT 20;");
  console.log("Recent Sessions:");
  console.table(res.rows);
  const users = await db.execute("SELECT id, name, email FROM users WHERE role = 'faculty';");
  console.log("Faculty:");
  console.table(users.rows);
}

run().catch(console.error);
