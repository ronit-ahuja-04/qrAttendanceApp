const isProduction = process.env.NODE_ENV === 'production' || process.env.DATABASE_URL;

let db;

if (isProduction) {
  const { Pool } = require('pg');
  
  const pool = new Pool({
    connectionString: process.env.DATABASE_URL,
    ssl: { rejectUnauthorized: false }
  });

  const keyMap = {
    facultyid: 'facultyId',
    timetableslotid: 'timetableSlotId',
    facultyname: 'facultyName',
    facultyemail: 'facultyEmail',
    batchtarget: 'batchTarget',
    starttime: 'startTime',
    endtime: 'endTime',
    coursecode: 'courseCode',
    qrcode: 'qrCode',
    qrissuedat: 'qrIssuedAt',
    qrexpiresat: 'qrExpiresAt',
    enrolledstudentids: 'enrolledStudentIds',
    createdat: 'createdAt',
    previousqrcode: 'previousQrCode',
    proxyfacultyid: 'proxyFacultyId',
    approvalstatus: 'approvalStatus',
    groupid: 'groupId',
    sessionid: 'sessionId',
    studentid: 'studentId',
    markedat: 'markedAt',
    userid: 'userId',
    tagcolor: 'tagColor',
    ontagcolor: 'onTagColor',
    byname: 'byName',
    byicon: 'byIcon',
    isread: 'isRead',
    rollno: 'rollNo',
    profilepictureurl: 'profilePictureUrl',
    corebatch: 'coreBatch',
    electivesubject: 'electiveSubject',
    electivebatch: 'electiveBatch',
    fcmtoken: 'fcmToken',
    notificationprefs: 'notificationPrefs',
    facultyname: 'facultyName',
    facultyemail: 'facultyEmail',
    proxyfacultyname: 'proxyFacultyName',
    studentname: 'studentName',
    studentrollno: 'studentRollNo'
  };

  function fixKeys(row) {
    if (!row) return row;
    const newRow = {};
    for (const key in row) {
      newRow[keyMap[key] || key] = row[key];
    }
    return newRow;
  }

  db = {
    serialize: (cb) => cb(),
    _convertSql: (sql) => {
      let i = 1;
      return sql.replace(/\?/g, () => `$${i++}`);
    },
    run: function (sql, params, callback) {
      if (typeof params === 'function') { callback = params; params = []; }
      params = params || [];
      pool.query(this._convertSql(sql), params, (err, res) => {
        if (callback) callback.call({ changes: res ? res.rowCount : 0, lastID: null }, err);
      });
      return this;
    },
    get: function (sql, params, callback) {
      if (typeof params === 'function') { callback = params; params = []; }
      params = params || [];
      pool.query(this._convertSql(sql), params, (err, res) => {
        if (callback) callback(err, res && res.rows && res.rows.length > 0 ? fixKeys(res.rows[0]) : null);
      });
      return this;
    },
    all: function (sql, params, callback) {
      if (typeof params === 'function') { callback = params; params = []; }
      params = params || [];
      pool.query(this._convertSql(sql), params, (err, res) => {
        if (callback) callback(err, res && res.rows ? res.rows.map(fixKeys) : []);
      });
      return this;
    },
    prepare: function (sql) {
      const convertedSql = this._convertSql(sql);
      const pendingQueries = [];
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
          const promise = pool.query(convertedSql, params).then(res => {
            if (callback) callback.call({ changes: res ? res.rowCount : 0 }, null);
          }).catch(err => {
            if (callback) callback.call({ changes: 0 }, err);
            else console.error('Prepared statement error:', err);
          });
          pendingQueries.push(promise);
          return this;
        },
        finalize: function (cb) {
          Promise.allSettled(pendingQueries).then(() => {
            if (cb) cb(null);
          });
        }
      };
    }
  };
  
  console.log("Using PostgreSQL Database wrapper.");
} else if (process.env.NODE_ENV === 'test') {
  const sqlite3 = require('sqlite3').verbose();
  db = new sqlite3.Database(':memory:', (err) => {
    if (!err) {
      db.run('PRAGMA busy_timeout = 5000;');
    }
  });
  console.log("Using SQLite In-Memory Database for testing.");
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
    notificationPrefs TEXT
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
  } else {
    db.run(`ALTER TABLE sessions ADD COLUMN slotId TEXT`, (err) => {});
    db.run(`ALTER TABLE sessions ADD COLUMN metadata TEXT`, (err) => {});
    db.run(`ALTER TABLE sessions ADD COLUMN batchTarget TEXT`, (err) => {});
    db.run(`ALTER TABLE sessions ADD COLUMN groupId TEXT`, (err) => {});
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
});

module.exports = db;
