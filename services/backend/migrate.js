const sqlite3 = require('sqlite3').verbose();
const { Pool } = require('pg');

const RENDER_DB_URL = 'postgresql://qr_attendance_db_y16j_user:U47qOicOOq7kvCZLuKos0bHFvcEtfD8R@dpg-dabj93rm8hqs73e1pkk0-a.oregon-postgres.render.com/qr_attendance_db_y16j';

const pool = new Pool({
  connectionString: RENDER_DB_URL,
  ssl: { rejectUnauthorized: false }
});

const localDb = new sqlite3.Database('./backend/database.sqlite');

const tables = [
  'users',
  'sessions',
  'attendance_records',
  'timetable_slots',
  'notifications'
];

const getLocalData = (tableName) => {
  return new Promise((resolve, reject) => {
    localDb.all(`SELECT * FROM ${tableName}`, [], (err, rows) => {
      if (err) reject(err);
      else resolve(rows);
    });
  });
};

async function migrate() {
  console.log("Starting Migration...");

  for (const table of tables) {
    console.log(`\n--- Migrating table: ${table} ---`);
    const rows = await getLocalData(table);
    
    if (rows.length === 0) {
      console.log(`No data found in local ${table}, skipping.`);
      continue;
    }

    // Fetch valid columns from PG to avoid schema mismatch errors
    const pgColsRes = await pool.query(`
      SELECT column_name 
      FROM information_schema.columns 
      WHERE table_name = $1
    `, [table]);
    
    const validPgColumns = pgColsRes.rows.map(r => r.column_name.toLowerCase());
    
    if (validPgColumns.length === 0) {
      console.log(`Table ${table} does not exist on PostgreSQL yet! Skipping.`);
      continue;
    }

    // Filter columns from local rows that actually exist in PG
    const localColumns = Object.keys(rows[0]);
    const columnsToInsert = localColumns.filter(col => validPgColumns.includes(col.toLowerCase()));
    
    const valuesPlaceholders = columnsToInsert.map((_, i) => `$${i + 1}`).join(', ');
    const insertQuery = `INSERT INTO ${table} (${columnsToInsert.join(', ')}) VALUES (${valuesPlaceholders}) ON CONFLICT DO NOTHING`;

    let successCount = 0;
    
    // Process in chunks of 50
    for (let i = 0; i < rows.length; i += 50) {
      const chunk = rows.slice(i, i + 50);
      const promises = chunk.map(async (row) => {
        const values = columnsToInsert.map(col => row[col]);
        try {
          await pool.query(insertQuery, values);
          successCount++;
        } catch (err) {
          console.error(`Error inserting row into ${table}:`, err.message);
        }
      });
      await Promise.all(promises);
    }
    
    console.log(`Successfully migrated ${successCount}/${rows.length} rows to remote ${table}.`);
  }

  console.log("\nMigration Complete! Closing connections.");
  localDb.close();
  await pool.end();
}

migrate().catch(err => {
  console.error("Migration failed:", err);
});
