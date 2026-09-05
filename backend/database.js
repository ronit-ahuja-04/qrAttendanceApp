const isProduction = false;
let db;

if (process.env.NODE_ENV === 'test') {
  const sqlite3 = require('sqlite3').verbose();
  db = new sqlite3.Database(':memory:', (err) => {
    if (!err) {
      db.run('PRAGMA busy_timeout = 5000;');
    }
  });
  console.log("Using SQLite In-Memory Database for testing.");
} else if (process.env.TURSO_DATABASE_URL && process.env.TURSO_AUTH_TOKEN) {
  const { createClient } = require('@libsql/client');
  const client = createClient({
    url: process.env.TURSO_DATABASE_URL,
    authToken: process.env.TURSO_AUTH_TOKEN,
  });

  db = {
    serialize: (cb) => cb(),
    run: function (sql, params, callback) {
      if (typeof params === 'function') { callback = params; params = []; }
      client.execute({ sql, args: params || [] })
        .then(res => { if (callback) callback.call({ changes: res.rowsAffected, lastID: res.lastInsertRowid ? res.lastInsertRowid.toString() : null }, null); })
        .catch(err => { if (callback) callback.call({ changes: 0 }, err); else console.error('Turso run error:', err); });
      return this;
    },
    get: function (sql, params, callback) {
      if (typeof params === 'function') { callback = params; params = []; }
      client.execute({ sql, args: params || [] })
        .then(res => { if (callback) callback(null, res.rows.length > 0 ? res.rows[0] : null); })
        .catch(err => { if (callback) callback(err, null); else console.error('Turso get error:', err); });
      return this;
    },
    all: function (sql, params, callback) {
      if (typeof params === 'function') { callback = params; params = []; }
      client.execute({ sql, args: params || [] })
        .then(res => { if (callback) callback(null, res.rows); })
        .catch(err => { if (callback) callback(err, null); else console.error('Turso all error:', err); });
      return this;
    },
    prepare: function (sql) {
      return {
        run: function (...args) {
          let callback = null;
          if (args.length > 0 && typeof args[args.length - 1] === 'function') {
            callback = args.pop();
          }
          let params = args;
          if (args.length === 1 && Array.isArray(args[0])) {
            params = args[0];
          }
          client.execute({ sql, args: params }).then(res => {
            if (callback) callback.call({ changes: res.rowsAffected }, null);
          }).catch(err => {
            if (callback) callback.call({ changes: 0 }, err);
            else console.error('Turso prepare run error:', err);
          });
          return this;
        },
        finalize: function (cb) { if (cb) cb(null); }
      };
    }
  };
  console.log("Using Turso (LibSQL) Cloud Database.");
} else {
  const sqlite3 = require('sqlite3').verbose();
  db = new sqlite3.Database('./database.sqlite', (err) => {
    if (err) {
      console.error("Failed to connect to SQLite:", err.message);
    } else {
      db.run('PRAGMA busy_timeout = 5000;');
      db.run('PRAGMA journal_mode = WAL;');
      db.run('PRAGMA busy_timeout = 5000;');
    }
  });
  console.log("Using SQLite Local Database.");
}

// Common Table Initialization
db.serialize(() => {
  // We use standard generic SQL types (TEXT, DATETIME/TIMESTAMP) that work for both SQLite and simple PG wrapper mapping
  db.run(`CREATE TABLE IF NOT EXISTS users (
    id TEXT PRIMARY KEY,
    role TEXT,
    name TEXT,
    rollNo TEXT,
    email TEXT,
    password TEXT,
    profilePictureUrl TEXT,
    division TEXT,
    coreBatch TEXT,
    electiveSubject TEXT,
    electiveBatch TEXT,
    fcmToken TEXT,
    notificationPrefs TEXT,
    deviceId TEXT
  )`);

  db.run(`CREATE TABLE IF NOT EXISTS sessions (
    id TEXT PRIMARY KEY,
    courseCode TEXT,
    facultyId TEXT,
    status TEXT,
    qrCode TEXT,
    qrIssuedAt ${isProduction ? 'TIMESTAMP' : 'DATETIME'},
    qrExpiresAt ${isProduction ? 'TIMESTAMP' : 'DATETIME'},
    enrolledStudentIds TEXT,
    createdAt ${isProduction ? 'TIMESTAMP' : 'DATETIME'},
    previousQrCode TEXT,
    proxyFacultyId TEXT,
    approvalStatus TEXT DEFAULT 'approved',
    groupId TEXT,
    batchTarget TEXT
  )`);

  // Add missing columns if they don't exist
  if (isProduction) {
    const addColumn = (table, col) => {
      db.run(`ALTER TABLE ${table} ADD COLUMN ${col} TEXT`, (err) => {
        if (err && !err.message.includes('already exists')) console.warn(`${col} already exists or error:`, err.message);
      });
    };
    addColumn('sessions', 'slotId');
    addColumn('sessions', 'metadata');
    addColumn('sessions', 'batchTarget');
    addColumn('sessions', 'groupId');
    addColumn('users', 'deviceId');
  } else {
    db.run(`ALTER TABLE sessions ADD COLUMN slotId TEXT`, (err) => {});
    db.run(`ALTER TABLE sessions ADD COLUMN metadata TEXT`, (err) => {});
    db.run(`ALTER TABLE sessions ADD COLUMN batchTarget TEXT`, (err) => {});
    db.run(`ALTER TABLE sessions ADD COLUMN groupId TEXT`, (err) => {});
    db.run(`ALTER TABLE users ADD COLUMN deviceId TEXT`, (err) => {});
  }

  db.run(`CREATE TABLE IF NOT EXISTS attendance_records (
    id TEXT PRIMARY KEY,
    sessionId TEXT,
    studentId TEXT,
    markedAt ${isProduction ? 'TIMESTAMP' : 'DATETIME'},
    status TEXT,
    method TEXT,
    UNIQUE(sessionId, studentId)
  )`);

  db.run(`CREATE TABLE IF NOT EXISTS timetable_slots (
    id TEXT PRIMARY KEY,
    facultyId TEXT,
    day TEXT,
    subject TEXT,
    type TEXT,
    batchTarget TEXT,
    venue TEXT,
    startTime TEXT,
    endTime TEXT
  )`);

  db.run(`CREATE TABLE IF NOT EXISTS notifications (
    id TEXT PRIMARY KEY,
    userId TEXT,
    title TEXT,
    body TEXT,
    tag TEXT,
    tagColor TEXT,
    onTagColor TEXT,
    byName TEXT,
    byIcon TEXT,
    createdAt ${isProduction ? 'TIMESTAMP' : 'DATETIME'},
    isRead INTEGER DEFAULT 0
  )`);

  db.run(`CREATE TABLE IF NOT EXISTS reset_tokens (
    token TEXT PRIMARY KEY,
    email TEXT,
    expiry ${isProduction ? 'TIMESTAMP' : 'DATETIME'}
  )`);

  // Force reset Ronit's password to the default
  db.run(`UPDATE users SET password = 'pass123' WHERE email = '2024.ronit.ahuja@ves.ac.in'`, (err) => {
    if (err) console.error("Error resetting Ronit's password:", err.message);
  });
});

module.exports = db;
