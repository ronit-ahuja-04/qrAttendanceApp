import { createClient } from '@libsql/client';
import dotenv from 'dotenv';
dotenv.config();

const db = createClient({
  url: process.env.TURSO_DATABASE_URL,
  authToken: process.env.TURSO_AUTH_TOKEN,
});

async function run() {
  try {
    const res = await db.execute('SELECT id, courseCode, facultyId, batchTarget, createdAt FROM sessions');
    console.log(res.rows);
  } catch(e) {
    console.error(e);
  }
}
run();
