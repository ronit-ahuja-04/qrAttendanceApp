const { Pool } = require('pg');
require('dotenv').config();

const pool = new Pool({
  connectionString: 'postgresql://qr_attendance_db_user:O6L3nEavbZ7V2d0qBqRTRfJ78sUfVwKj@dpg-cr0ov5t6l47c73a21vug-a.oregon-postgres.render.com/qr_attendance_db',
  ssl: { rejectUnauthorized: false }
});

pool.query("SELECT column_name FROM information_schema.columns WHERE table_name='sessions'", (err, res) => {
  if (err) console.error(err);
  else console.log('Columns:', res.rows.map(r => r.column_name));
  pool.end();
});
