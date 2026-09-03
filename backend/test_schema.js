const { Pool } = require('pg');
require('dotenv').config();

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: { rejectUnauthorized: false }
});

pool.query("SELECT column_name FROM information_schema.columns WHERE table_name='sessions'", (err, res) => {
  if (err) console.error(err);
  else console.log('Columns:', res.rows.map(r => r.column_name));
  pool.end();
});
