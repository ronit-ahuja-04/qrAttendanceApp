require('dotenv').config();
const express = require('express');
const nodemailer = require('nodemailer');

// Nodemailer transporter (Gmail + App Password)
const mailer = nodemailer.createTransport({
  host: 'smtp.gmail.com',
  port: 465,
  secure: true,
  auth: {
    user: process.env.MAIL_USER,
    pass: process.env.MAIL_PASS,
  },
  connectionTimeout: 5000,
  greetingTimeout: 5000,
  socketTimeout: 5000,
});
const cors = require('cors');
const { v4: uuidv4 } = require('uuid');
const db = require('./database');
const multer = require('multer');
const cron = require('node-cron');
const path = require('path');
const fs = require('fs');
const exceljs = require('exceljs');
const helmet = require('helmet');
const redis = require('redis');
const { authenticateToken, generateToken } = require('./middleware/auth');
const { apiLimiter, loginLimiter, attendanceLimiter } = require('./middleware/rateLimiter');
const app = express();

app.use(helmet());
app.use(apiLimiter);
const allowedOrigins = [
  'http://localhost:3000',
  'http://localhost:56086',
  'https://vesit-ams.vercel.app',
  'https://qr-attendance-app.vercel.app'
];

app.use(cors({
  origin: function(origin, callback) {
    if(!origin) return callback(null, true);
    
    // Allow any localhost port for development
    if (origin.startsWith('http://localhost:')) {
      return callback(null, true);
    }
    
    // Allow any vercel deployment and production domains
    if (origin.endsWith('.vercel.app') || allowedOrigins.includes(origin)) {
      return callback(null, true);
    }
    
    const msg = 'The CORS policy for this site does not allow access from the specified Origin.';
    return callback(new Error(msg), false);
  },
  credentials: true,
  allowedHeaders: ['Content-Type', 'Authorization', 'Bypass-Tunnel-Reminder', 'ngrok-skip-browser-warning', 'x-requested-with', 'Accept']
}));
app.use(express.json());

// Global logger
app.use((req, res, next) => {
  console.log(`[${new Date().toISOString()}] ${req.method} ${req.url}`);
  next();
});

// Global authentication middleware
app.use((req, res, next) => {
  // Allow CORS preflight requests
  if (req.method === 'OPTIONS') {
    return next();
  }

  const publicPaths = [
    '/login',
    '/forgot-password',
    '/reset-password',
    '/uploads',
    '/profile-images'
  ];
  
  if (publicPaths.some(p => req.path.startsWith(p))) {
    return next();
  }
  
  return authenticateToken(req, res, next);
});

// Initialize Firebase Admin
const admin = require('firebase-admin');
try {
  let serviceAccount;
  if (process.env.FIREBASE_SERVICE_ACCOUNT) {
    serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
  } else if (fs.existsSync('./firebase-service-account.json')) {
    serviceAccount = require('./firebase-service-account.json');
  }

  if (serviceAccount) {
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
      storageBucket: 'attendance-monitoring-sy-89218.firebasestorage.app'
    });
    console.log('Firebase Admin SDK initialized successfully.');
  } else {
    console.warn('Firebase Admin SDK NOT initialized. Missing credentials.');
  }
} catch (e) {
  console.error('Failed to initialize Firebase Admin SDK:', e.message);
}

// Push Notification Helper
function sendPushNotification(userId, title, body, payloadData = {}) {
  // 1. Fetch user's FCM token and prefs from DB
  db.get(`SELECT fcmToken, notificationPrefs FROM users WHERE id = ?`, [userId], (err, row) => {
    if (err) {
      console.error('Failed to fetch fcmToken:', err);
      return;
    }
    if (row && row.fcmToken) {
      // 2. Filter based on preferences
      let prefs = {};
      try {
        if (row.notificationPrefs) {
          prefs = JSON.parse(row.notificationPrefs);
        }
      } catch (e) {
        console.error('Error parsing notificationPrefs:', e);
      }
      
      const type = payloadData.type;
      if (type) {
        if (type.startsWith('PROXY_') && prefs.notif_proxy === false) return;
        if (type === 'ATTENDANCE_UPDATED' && prefs.notif_attendance === false) return;
        if (type === 'TIMETABLE_UPDATED' && prefs.notif_alerts === false) return;
      }
      
      const message = {
        notification: { title, body },
        data: payloadData,
        token: row.fcmToken
      };
      
      admin.messaging().send(message)
        .then((response) => console.log('Successfully sent FCM message:', response))
        .catch((error) => console.error('Error sending FCM message:', error));
    }
  });
}

// Update FCM Token Endpoint
app.post('/update-fcm-token', (req, res) => {
  const { userId, fcmToken } = req.body;
  if (!userId || !fcmToken && fcmToken !== '') return res.status(400).json({ error: 'Missing parameters' });
  
  db.run(`UPDATE users SET fcmToken = ? WHERE id = ?`, [fcmToken, userId], function(err) {
    if (err) return res.status(500).json({ error: err.message });
    res.json({ message: 'FCM Token updated successfully' });
  });
});

// Update Notification Preferences
app.post('/update-notification-prefs', (req, res) => {
  const { userId, prefs } = req.body; // prefs is an object
  if (!userId || !prefs) return res.status(400).json({ error: 'Missing parameters' });
  
  db.run(`UPDATE users SET notificationPrefs = ? WHERE id = ?`, [JSON.stringify(prefs), userId], function(err) {
    if (err) return res.status(500).json({ error: err.message });
    res.json({ message: 'Notification preferences updated successfully' });
  });
});

// Setup EOD Cron Job for Proxy Approvals (11:59 PM)
cron.schedule('59 23 * * *', () => {
  console.log('Running EOD Auto-Approval for pending proxy sessions...');
  db.run(`UPDATE sessions SET approvalStatus = 'approved' WHERE approvalStatus = 'pending'`, function(err) {
    if (err) console.error('EOD Auto-Approval failed:', err.message);
    else console.log(`Auto-approved ${this.changes} sessions.`);
  });
}, {
  scheduled: true,
  timezone: "Asia/Kolkata"
});

// Setup Automated Lecture Reminder (runs every minute)
cron.schedule('* * * * *', () => {
  const now = new Date();
  
  // Convert now to Asia/Kolkata timezone to match the local schedule
  const options = { timeZone: 'Asia/Kolkata', hour: '2-digit', minute: '2-digit', hour12: false };
  const target = new Date(now.getTime() + 10 * 60000); // 10 minutes in the future
  
  const formatter = new Intl.DateTimeFormat('en-US', options);
  const parts = formatter.formatToParts(target);
  let hours = parts.find(p => p.type === 'hour').value;
  if (hours === '24') hours = '00';
  const minutes = parts.find(p => p.type === 'minute').value;
  const timeStr = `${hours}:${minutes}`;
  
  // We need to get the day in Asia/Kolkata timezone
  const localDayParts = new Intl.DateTimeFormat('en-US', { timeZone: 'Asia/Kolkata', weekday: 'short' }).formatToParts(target);
  const dayStr = localDayParts.find(p => p.type === 'weekday').value;
  
  db.all('SELECT * FROM timetable_slots WHERE day = ? AND startTime = ?', [dayStr, timeStr], (err, rows) => {
    if (err) return console.error('Cron timetable error:', err);
    if (!rows || rows.length === 0) return;

    rows.forEach(slot => {
      // 1. Notify Faculty
      const facultyTitle = 'Upcoming Lecture';
      const facultyBody = `Your ${slot.type} for ${slot.subject} starts in 10 minutes at ${slot.venue}.`;
      db.run('INSERT INTO notifications (id, userId, title, body, tag, tagColor, onTagColor, byName, byIcon, createdAt) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
        [uuidv4(), slot.facultyId, facultyTitle, facultyBody, 'Reminder', 'primaryContainer', 'onPrimaryContainer', 'System', 'alarm', new Date().toISOString()]);
      sendPushNotification(slot.facultyId, facultyTitle, facultyBody, { type: 'TIMETABLE_UPDATED' }); // using TIMETABLE_UPDATED type to respect 'notif_alerts'

      // 2. Notify Students
      db.all('SELECT id, division, coreBatch, electiveBatch FROM users WHERE role = \'student\'', [], (err, students) => {
        if (err || !students) return;
        
        const targetStudents = students.filter(s => {
           // Ensure division matches
           if (!s.division || !slot.batchTarget.includes(s.division)) return false;
           
           if (slot.batchTarget.includes('All')) return true;
           
           if (s.coreBatch && slot.batchTarget.includes(s.coreBatch)) return true;
           if (s.electiveBatch && slot.batchTarget.includes(s.electiveBatch)) return true;
           
           return false;
        });

        targetStudents.forEach(student => {
          const studentTitle = 'Upcoming Class';
          const studentBody = `${slot.subject} starts in 10 minutes at ${slot.venue}.`;
          db.run('INSERT INTO notifications (id, userId, title, body, tag, tagColor, onTagColor, byName, byIcon, createdAt) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
            [uuidv4(), student.id, studentTitle, studentBody, 'Reminder', 'secondaryContainer', 'onSecondaryContainer', 'System', 'alarm', new Date().toISOString()]);
          sendPushNotification(student.id, studentTitle, studentBody, { type: 'TIMETABLE_UPDATED' });
        });
      });
    });
  });
});

// Ensure uploads dir exists
const uploadsDir = path.join(__dirname, 'uploads');
if (!fs.existsSync(uploadsDir)) {
  fs.mkdirSync(uploadsDir);
}
app.use('/uploads', express.static(uploadsDir));

// Multer config
const isProduction = process.env.NODE_ENV === 'production' || process.env.DATABASE_URL;

const storage = isProduction ? multer.memoryStorage() : multer.diskStorage({
  destination: (req, file, cb) => cb(null, 'uploads/'),
  filename: (req, file, cb) => {
    const ext = path.extname(file.originalname);
    cb(null, uuidv4() + ext);
  }
});
const upload = multer({
  storage,
  limits: { fileSize: 5 * 1024 * 1024 }, // 5MB
  fileFilter: (req, file, cb) => {
    const allowed = ['.jpg', '.jpeg', '.png', '.webp'];
    const ext = path.extname(file.originalname).toLowerCase();
    if (allowed.includes(ext)) {
      cb(null, true);
    } else {
      cb(new Error('Invalid file type'));
    }
  }
});

let sseClients = [];

let pubClient = null;
let subClient = null;

if (process.env.REDIS_URL) {
  pubClient = redis.createClient({ url: process.env.REDIS_URL });
  subClient = pubClient.duplicate();

  pubClient.on('error', (err) => console.error('Redis Pub Error:', err));
  subClient.on('error', (err) => console.error('Redis Sub Error:', err));

  Promise.all([pubClient.connect(), subClient.connect()]).then(() => {
    console.log('Redis connected for SSE Pub/Sub');
    
    subClient.subscribe('sse-events', (message) => {
      try {
        const { userId, event } = JSON.parse(message);
        const data = `data: ${JSON.stringify(event)}\n\n`;
        sseClients.forEach(client => {
          if (!userId || client.userId === userId) {
            client.res.write(data);
          }
        });
      } catch (e) {
        console.error('Error processing Redis message:', e);
      }
    });
  }).catch(e => console.error('Failed to connect to Redis:', e));
}

function notifyClients(userId, event) {
  if (pubClient && pubClient.isOpen) {
    pubClient.publish('sse-events', JSON.stringify({ userId, event }));
  } else {
    const data = `data: ${JSON.stringify(event)}\n\n`;
    sseClients.forEach(client => {
      if (!userId || client.userId === userId) {
        client.res.write(data);
      }
    });
  }
}

// Utilities
function generateQrCode() {
  return Math.floor(100000 + Math.random() * 900000).toString();
}

function formatProfilePictureUrl(url, userId) {
  if (!url) return url;
  
  const baseUrl = process.env.BASE_URL || 'https://qr-attendance-api-wvvs.onrender.com';
  
  if (url.startsWith('data:')) {
    return `${baseUrl}/profile-images/${userId}`;
  } else if (url.startsWith('/uploads')) {
    return `${baseUrl}${url}`;
  }
  return url;
}

app.get('/profile-images/:id', (req, res) => {
  const userId = req.params.id;
  db.get('SELECT profilePictureUrl FROM users WHERE id = ?', [userId], (err, row) => {
    if (err) return res.status(500).send(err.message);
    if (!row || !row.profilePictureUrl) {
      return res.redirect('https://ui-avatars.com/api/?name=User&background=random');
    }
    const url = row.profilePictureUrl;
    if (url.startsWith('data:')) {
      const matches = url.match(/^data:([A-Za-z-+\/]+);base64,(.+)$/);
      if (!matches || matches.length !== 3) return res.status(500).send('Invalid base64 string');
      res.set('Content-Type', matches[1]);
      res.send(Buffer.from(matches[2], 'base64'));
    } else if (url.startsWith('http') || url.startsWith('/uploads')) {
      res.redirect(url);
    } else {
      res.redirect('https://ui-avatars.com/api/?name=User&background=random');
    }
  });
});

app.post('/login', loginLimiter, (req, res) => {
  const { email, password } = req.body;
  console.log('Login attempt:', email, password);
  db.get(`SELECT id, role, name, rollNo, email, profilePictureUrl, division FROM users WHERE email = ? AND password = ?`, [email, password], (err, row) => {
    if (err) return res.status(500).json({ error: err.message });
    if (!row) return res.status(401).json({ error: 'Invalid credentials' });
    
    row.branch = 'INFT'; // Hardcode branch for now as per user request
    row.profilePictureUrl = formatProfilePictureUrl(row.profilePictureUrl, row.id);

    if (row.role === 'faculty') {
      db.all(`SELECT DISTINCT subject, batchTarget, type FROM timetable_slots WHERE facultyId = ?`, [row.id], (err, scopes) => {
        if (err) {
          console.error("Error fetching scopes:", err);
          row.scopes = [];
        } else {
          row.scopes = scopes;
        }
        row.token = generateToken(row);
        res.json(row);
      });
    } else {
      row.token = generateToken(row);
      res.json(row);
    }
  });
});

app.delete('/users/:id/profile-picture', async (req, res) => {
  const userId = req.params.id;
  db.run(`UPDATE users SET profilePictureUrl = NULL WHERE id = ?`, [userId], function (err) {
    if (err) return res.status(500).json({ error: err.message });
    res.json({ message: "Profile picture removed successfully", profilePictureUrl: null });
  });
});

app.post('/users/:id/profile-picture', upload.single('profilePicture'), async (req, res) => {
  if (!req.file) return res.status(400).json({ error: 'No file provided or invalid format.' });

  const userId = req.params.id;
  let url;

  if (isProduction && admin.apps.length > 0) {
    try {
      const bucket = admin.storage().bucket();
      const ext = path.extname(req.file.originalname);
      const filename = `profiles/${uuidv4()}${ext}`;
      const file = bucket.file(filename);
      
      await file.save(req.file.buffer, {
        metadata: { contentType: req.file.mimetype },
      });
      
      url = `https://firebasestorage.googleapis.com/v0/b/${bucket.name}/o/${encodeURIComponent(filename)}?alt=media`;
    } catch (e) {
      console.error("Firebase Storage Upload Error:", e);
      return res.status(500).json({ error: "Cloud storage upload failed." });
    }
  } else {
    // Fallback: Use Base64 if memory storage was used to avoid ephemeral disk loss on Render
    if (!req.file.filename && req.file.buffer) {
      const base64Data = req.file.buffer.toString('base64');
      const dataUri = `data:${req.file.mimetype};base64,${base64Data}`;
      
      db.run(`UPDATE users SET profilePictureUrl = ? WHERE id = ?`, [dataUri, userId], function (err) {
        if (err) return res.status(500).json({ error: err.message });
        res.json({ profilePictureUrl: formatProfilePictureUrl(dataUri, userId) });
      });
      return;
    } else {
      url = `/uploads/${req.file.filename}`;
    }
  }

  db.run(`UPDATE users SET profilePictureUrl = ? WHERE id = ?`, [url, userId], function (err) {
    if (err) return res.status(500).json({ error: err.message });
    res.json({ profilePictureUrl: formatProfilePictureUrl(url, userId) });
  });
});

app.get('/notifications/stream', (req, res) => {
  const userId = req.query.userId;
  res.setHeader('Content-Type', 'text/event-stream');
  res.setHeader('Cache-Control', 'no-cache');
  res.setHeader('Connection', 'keep-alive');
  res.flushHeaders();

  const client = { userId, res };
  sseClients.push(client);

  req.on('close', () => {
    sseClients = sseClients.filter(c => c !== client);
  });
});

// Global Authentication Middleware
app.use((req, res, next) => {
  const publicPaths = [
    '/login',
    '/forgot-password',
    '/reset-password',
    '/change-password',
    '/timetable'
  ];
  if (publicPaths.includes(req.path) || req.path.startsWith('/users/') || req.path.startsWith('/notifications/stream')) {
    return next();
  }
  return authenticateToken(req, res, next);
});

function getSessionTargetStudents(courseCode, batchTarget) {
  let whereClause = "role = 'student'";
  const target = batchTarget || '';
  const course = (courseCode || '').toLowerCase();

  const isAdmt = target.includes('ADMT') || course.includes('database') || course.includes('admt') || course.includes('advance database');
  const isSoft = target.includes('Soft') || target.includes('soft') || course.includes('soft');
  const isCrossDivision = target.startsWith('TE -'); // e.g. "TE - ADMT (Batch A)"

  if (isAdmt) {
    whereClause += " AND electiveSubject = 'ADMT'";
    if (target.includes('Batch A')) whereClause += " AND electiveBatch = 'Batch A'";
    else if (target.includes('Batch B')) whereClause += " AND electiveBatch = 'Batch B'";
    else if (target.includes('Batch C')) whereClause += " AND electiveBatch = 'Batch C'";
    // If division-specific (lab), also filter by division
    if (!isCrossDivision) {
      if (target.includes('D15A')) whereClause += " AND division = 'D15A'";
      else if (target.includes('D15B')) whereClause += " AND division = 'D15B'";
      else if (target.includes('D15C')) whereClause += " AND division = 'D15C'";
    }
  } else if (isSoft) {
    whereClause += " AND electiveSubject = 'Soft Computing'";
    if (target.includes('Batch A')) whereClause += " AND electiveBatch = 'Batch A'";
    else if (target.includes('Batch B')) whereClause += " AND electiveBatch = 'Batch B'";
    else if (target.includes('Batch C')) whereClause += " AND electiveBatch = 'Batch C'";
    // If division-specific (lab), also filter by division
    if (!isCrossDivision) {
      if (target.includes('D15A')) whereClause += " AND division = 'D15A'";
      else if (target.includes('D15B')) whereClause += " AND division = 'D15B'";
      else if (target.includes('D15C')) whereClause += " AND division = 'D15C'";
    }
  } else {
    // Standard Lectures / Core Labs — Batch = coreBatch (roll-number based)
    if (target.includes('D15A')) whereClause += " AND division = 'D15A'";
    else if (target.includes('D15B')) whereClause += " AND division = 'D15B'";
    else if (target.includes('D15C')) whereClause += " AND division = 'D15C'";

    if (target.includes('Batch A')) whereClause += " AND coreBatch = 'Batch A'";
    else if (target.includes('Batch B')) whereClause += " AND coreBatch = 'Batch B'";
    else if (target.includes('Batch C')) whereClause += " AND coreBatch = 'Batch C'";
  }
  return whereClause;
}


// Create Smart Seminar Session
app.post('/sessions/smart-seminar', (req, res) => {
  const { proxyFacultyId, divisions, startTime, endTime, date } = req.body;

  const id = uuidv4();
  const now = new Date().toISOString();

  // We store the smart seminar in sessions but with a special courseCode
  // so the QR generator and mark-attendance logic can identify it.
  db.run(`INSERT INTO sessions (id, courseCode, facultyId, proxyFacultyId, status, enrolledStudentIds, createdAt, approvalStatus, metadata)
          VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`,
    [id, 'Smart Seminar', proxyFacultyId, proxyFacultyId, 'scheduled', JSON.stringify([]), now, 'approved', JSON.stringify({
      divisions,
      startTime,
      endTime,
      date
    })],
    function (err) {
      if (err) return res.status(500).json({ error: err.message });
      res.json({ id, courseCode: 'Smart Seminar', facultyId: proxyFacultyId, status: 'scheduled', createdAt: now });
    }
  );
});

app.post('/sessions/bulk', async (req, res) => {
  const { proxyFacultyId, targets } = req.body;
  if (!targets || !Array.isArray(targets) || targets.length === 0) {
    return res.status(400).json({ error: 'No targets provided' });
  }

  const groupId = uuidv4();
  const now = new Date().toISOString();

  try {
    const results = [];
    for (const t of targets) {
      const scopeFacultyId = t.originalFacultyId || t.facultyId;
      let baseSubject = t.courseCode;
      if (baseSubject.endsWith(' - Lab')) baseSubject = baseSubject.slice(0, -6);
      if (baseSubject.endsWith(' - Lecture')) baseSubject = baseSubject.slice(0, -10);

      // Verify scope
      const scope = await new Promise((resolve, reject) => {
        db.get('SELECT 1 FROM timetable_slots WHERE facultyId = ? AND subject = ? AND batchTarget = ?', [scopeFacultyId, baseSubject, t.batchTarget], (err, row) => {
          if (err) return reject(err);
          resolve(row);
        });
      });

      if (!scope) {
        return res.status(403).json({ error: 'Scope mismatch', message: 'One or more selected faculties are not assigned to their subjects.' });
      }

      const whereClause = getSessionTargetStudents(t.courseCode, t.batchTarget);
      const rows = await new Promise((resolve, reject) => {
        db.all('SELECT id FROM users WHERE ' + whereClause, [], (err, r) => {
          if (err) return reject(err);
          resolve(r);
        });
      });

      const enrolledIds = rows.map(r => r.id);
      const id = uuidv4();

      await new Promise((resolve, reject) => {
        db.run('INSERT INTO sessions (id, courseCode, facultyId, proxyFacultyId, status, enrolledStudentIds, createdAt, approvalStatus, groupId, batchTarget) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
          [id, t.courseCode, scopeFacultyId, proxyFacultyId, 'scheduled', JSON.stringify(enrolledIds), now, 'pending', groupId, t.batchTarget],
          function (err) {
            if (err) return reject(err);
            resolve();
          }
        );
      });
      results.push({ id, courseCode: t.courseCode, facultyId: scopeFacultyId });
    }
    res.json({ id: groupId, type: 'seminar', targets: results, createdAt: now });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.post('/sessions', (req, res) => {
  const { courseCode, facultyId, batchTarget, isProxy, originalFacultyId, creditToProxy, autoApprove, slotId, metadata } = req.body;

  // For scope checking, always use originalFacultyId if proxy
  const scopeFacultyId = (isProxy && originalFacultyId) ? originalFacultyId : facultyId;
  const proxyFacultyId = isProxy ? facultyId : null;


  // Strip " - Lab" or " - Lecture" from courseCode to match timetable_slots
  let baseSubject = courseCode;
  if (baseSubject.endsWith(' - Lab')) baseSubject = baseSubject.slice(0, -6);
  if (baseSubject.endsWith(' - Lecture')) baseSubject = baseSubject.slice(0, -10);

  // Scope validation against timetable (using original faculty's scopes for proxy)
  db.get(`SELECT 1 FROM timetable_slots WHERE facultyId = ? AND subject = ? AND batchTarget = ?`, [scopeFacultyId, baseSubject, batchTarget], (err, scope) => {
    if (err) return res.status(500).json({ error: err.message });
    if (!scope) return res.status(403).json({ error: 'Scope mismatch', message: 'This faculty is not assigned to teach this subject to this batch.' });

    const createSession = () => {
      const id = uuidv4();
      const now = new Date().toISOString();

    let whereClause = getSessionTargetStudents(courseCode, batchTarget);

    db.all(`SELECT id FROM users WHERE ${whereClause}`, [], (err, rows) => {
      if (err) return res.status(500).json({ error: err.message });
      const enrolledIds = rows.map(r => r.id);
      
      let finalFacultyId = scopeFacultyId;
      let approvalStatus = isProxy ? 'pending' : 'approved';
      
      if (isProxy) {
        if (creditToProxy) {
          finalFacultyId = proxyFacultyId;
          approvalStatus = 'approved';
          insertSession();
        } else {
          // Check for Seminars or Labs
          const isSeminar = courseCode.toLowerCase().includes('seminar') || (batchTarget && batchTarget.includes(','));
          const isLab = courseCode.toLowerCase().endsWith(' - lab');
          
          if (isSeminar || isLab || autoApprove) {
            approvalStatus = 'approved';
            insertSession(isSeminar);
          } else {
            // Lecture Rule: Check if proxy faculty teaches any subject to this division
            let baseDivision = batchTarget || '';
            if (baseDivision.includes(' - ')) {
              baseDivision = baseDivision.split(' - ')[0]; // e.g. "D15A - Batch C" -> "D15A"
            }
            db.get(`SELECT 1 FROM timetable_slots WHERE facultyId = ? AND batchTarget LIKE ? LIMIT 1`, [proxyFacultyId, `%${baseDivision}%`], (err, teachesDiv) => {
              if (err) return res.status(500).json({ error: err.message });
              if (!teachesDiv) {
                approvalStatus = 'approved'; // They don't teach this division -> Auto Approve
              }
              insertSession(false);
            });
          }
        }
      } else {
        insertSession(false);
      }

      function insertSession(isSeminar = false) {
        db.run(`INSERT INTO sessions (id, courseCode, facultyId, proxyFacultyId, status, enrolledStudentIds, createdAt, approvalStatus, batchTarget, slotId, metadata)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
          [id, courseCode, finalFacultyId, proxyFacultyId, 'scheduled', JSON.stringify(enrolledIds), now, approvalStatus, batchTarget, slotId || null, metadata ? JSON.stringify(metadata) : null],
          function (err) {
            if (err) return res.status(500).json({ error: err.message });
            
            if (isProxy && creditToProxy) {
              const notifId = uuidv4();
              db.get('SELECT name FROM users WHERE id = ?', [proxyFacultyId], (err, row) => {
                 const proxyName = row ? row.name : proxyFacultyId;
                 const title = 'Slot Cancelled';
                 const body = `Your lecture for ${courseCode} at ${batchTarget} was taken over by ${proxyName}.`;
                 db.run('INSERT INTO notifications (id, userId, title, body, tag, tagColor, onTagColor, byName, byIcon, createdAt) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
                   [notifId, scopeFacultyId, title, body, 'Cancelled', 'errorContainer', 'onErrorContainer', proxyName, 'cancel', now]);
                 sendPushNotification(scopeFacultyId, title, body, { type: 'PROXY_SLOT_CANCELLED' });
              });
            }
            
            res.json({ id, courseCode, facultyId: finalFacultyId, proxyFacultyId, status: 'scheduled', enrolledStudentIds: enrolledIds, createdAt: now, approvalStatus });
          }
        );
      }
    }); // end db.all
  }; // end createSession

    if (slotId) {
      const todayStart = new Date();
      todayStart.setHours(0,0,0,0);
      const todayEnd = new Date();
      todayEnd.setHours(23,59,59,999);

      const checkQuery = isProduction
        ? `SELECT * FROM sessions WHERE slotId = $1 AND createdAt >= $2 AND createdAt <= $3 LIMIT 1`
        : `SELECT * FROM sessions WHERE slotId = ? AND createdAt >= ? AND createdAt <= ? LIMIT 1`;
        
      db.get(checkQuery, [slotId, todayStart.toISOString(), todayEnd.toISOString()], (err, existingSession) => {
        if (err) return res.status(500).json({ error: err.message });
        if (existingSession) {
          // Check if session is completed, active, scheduled
          return res.json(existingSession);
        }
        createSession();
      });
    } else {
      createSession();
    }
  });
});

// 4) Start Session (generates initial QR code)
app.post('/api/sessions/:id/start', (req, res) => {
  const { id } = req.params; console.log("PUT timetable id:", id, "body:", req.body);
  const { totalSessionSeconds } = req.body;
  const now = new Date();
  const issuedAt = now;
  const expiresAt = new Date(now.getTime() + (totalSessionSeconds * 1000));

  const qrCode = generateQrCode();

  db.run(`UPDATE sessions SET status = 'active', qrCode = ?, qrIssuedAt = ?, qrExpiresAt = ? WHERE id = ? OR groupId = ?`,
    [qrCode, issuedAt.toISOString(), expiresAt.toISOString(), id, id],
    function (err) {
      if (err) return res.status(500).json({ error: err.message });
      db.get(`SELECT * FROM sessions WHERE id = ? OR groupId = ? LIMIT 1`, [id, id], (err, row) => {
        if (err || !row) return res.status(500).json({ error: 'Not found' });
        row.qrCode = { code: row.qrCode, issuedAt: row.qrIssuedAt, expiresAt: row.qrExpiresAt };
        res.json(row);
      });
    }
  );
});

// 4.1) Approve Proxy Session
app.put('/api/sessions/:id/approve', (req, res) => {
  const { id } = req.params;
  db.run(`UPDATE sessions SET approvalStatus = 'approved' WHERE id = ?`, [id], function (err) {
    if (err) return res.status(500).json({ error: err.message });
    if (this.changes === 0) return res.status(404).json({ error: 'Session not found' });
    
    // Notify proxy faculty that their session was approved
    db.get('SELECT proxyFacultyId, courseCode, facultyId FROM sessions WHERE id = ?', [id], (err, row) => {
      if (row && row.proxyFacultyId) {
        db.get('SELECT name FROM users WHERE id = ?', [row.facultyId], (err, fac) => {
           const facName = fac ? fac.name : row.facultyId;
           const now = new Date().toISOString();
           const title = 'Proxy Approved';
           const body = `${facName} approved your proxy session for ${row.courseCode}.`;
           db.run('INSERT INTO notifications (id, userId, title, body, tag, tagColor, onTagColor, byName, byIcon, createdAt) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
             [uuidv4(), row.proxyFacultyId, title, body, 'Approved', 'primaryContainer', 'onPrimaryContainer', facName, 'check_circle', now]);
           sendPushNotification(row.proxyFacultyId, title, body, { type: 'PROXY_APPROVED' });
        });
      }
    });
    
    res.json({ success: true, message: 'Session approved successfully' });
  });
});

// 4.2) Decline Proxy Session
app.put('/api/sessions/:id/decline', (req, res) => {
  const { id } = req.params;
  // Revert credit to proxy faculty instead of just declining
  db.get('SELECT proxyFacultyId, facultyId, courseCode FROM sessions WHERE id = ?', [id], (err, sessionRow) => {
    if (err) return res.status(500).json({ error: err.message });
    if (!sessionRow) return res.status(404).json({ error: 'Session not found' });
    
    db.run(`UPDATE sessions SET facultyId = proxyFacultyId, approvalStatus = 'approved' WHERE id = ?`, [id], function (err) {
      if (err) return res.status(500).json({ error: err.message });
      
      const now = new Date().toISOString();
      db.get('SELECT name FROM users WHERE id = ?', [sessionRow.facultyId], (err, fac) => {
         const facName = fac ? fac.name : sessionRow.facultyId;
         const title = 'Proxy Declined (Credit Reverted)';
         const body = `${facName} declined the proxy. The credit for ${sessionRow.courseCode} has been reverted to you.`;
         db.run('INSERT INTO notifications (id, userId, title, body, tag, tagColor, onTagColor, byName, byIcon, createdAt) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
           [uuidv4(), sessionRow.proxyFacultyId, title, body, 'Reverted', 'tertiaryContainer', 'onTertiaryContainer', facName, 'undo', now]);
         sendPushNotification(sessionRow.proxyFacultyId, title, body, { type: 'PROXY_DECLINED' });
      });
      
      res.json({ success: true, message: 'Session declined and credit reverted to proxy successfully' });
    });
  });
});

// 4.3) Reject Proxy Session
app.put('/api/sessions/:id/reject', (req, res) => {
  const { id } = req.params;
  db.run(`UPDATE sessions SET approvalStatus = 'rejected' WHERE id = ?`, [id], function (err) {
    if (err) return res.status(500).json({ error: err.message });
    if (this.changes === 0) return res.status(404).json({ error: 'Session not found' });
    
    db.get('SELECT proxyFacultyId, courseCode, facultyId FROM sessions WHERE id = ?', [id], (err, row) => {
      if (row && row.proxyFacultyId) {
        db.get('SELECT name FROM users WHERE id = ?', [row.facultyId], (err, fac) => {
           const facName = fac ? fac.name : row.facultyId;
           const now = new Date().toISOString();
           const title = 'Proxy Rejected';
           const body = `${facName} rejected your proxy session for ${row.courseCode}.`;
           db.run('INSERT INTO notifications (id, userId, title, body, tag, tagColor, onTagColor, byName, byIcon, createdAt) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
             [uuidv4(), row.proxyFacultyId, title, body, 'Rejected', 'errorContainer', 'onErrorContainer', facName, 'cancel', now]);
           sendPushNotification(row.proxyFacultyId, title, body, { type: 'PROXY_REJECTED' });
        });
      }
    });
    
    res.json({ success: true, message: 'Session rejected successfully' });
  });
});

// 5) Rotate QR Code
app.post('/api/sessions/:id/rotate-qr', (req, res) => {
  const { id } = req.params; console.log("PUT timetable id:", id, "body:", req.body);
  const { validitySeconds = 4 } = req.body;

  const now = new Date();
  const issuedAt = now;
  const expiresAt = new Date(now.getTime() + (validitySeconds * 1000));
  const qrCode = generateQrCode();

  db.run(`UPDATE sessions SET previousQrCode = qrCode, qrCode = ?, qrIssuedAt = ?, qrExpiresAt = ? WHERE id = ? OR groupId = ?`,
    [qrCode, issuedAt.toISOString(), expiresAt.toISOString(), id, id],
    function (err) {
      if (err) return res.status(500).json({ error: err.message });
      db.get(`SELECT * FROM sessions WHERE id = ? OR groupId = ? LIMIT 1`, [id, id], (err, row) => {
        if (err || !row) return res.status(500).json({ error: 'Not found' });
        row.qrCode = { code: row.qrCode, issuedAt: row.qrIssuedAt, expiresAt: row.qrExpiresAt };
        res.json(row);
      });
    }
  );
});

// 6) Close Session
app.post('/api/sessions/:id/close', (req, res) => {
  const { id } = req.params; console.log("PUT timetable id:", id, "body:", req.body);
  
  db.get('SELECT * FROM sessions WHERE id = ?', [id], (err, session) => {
    if (err) return res.status(500).json({ error: err.message });
    if (!session) return res.status(404).json({ error: 'Not found' });

    db.run(`UPDATE sessions SET status = 'closed', qrCode = NULL, qrIssuedAt = NULL, qrExpiresAt = NULL WHERE id = ?`,
      [id],
      function (err) {
        if (err) return res.status(500).json({ error: err.message });
        res.json({ success: true });
      }
    );
  });
});

// 7) Get Active Session Info (poll for UI)
app.get('/api/sessions/:id', (req, res) => {
  const { id } = req.params; console.log("PUT timetable id:", id, "body:", req.body);
  db.get(`SELECT * FROM sessions WHERE id = ?`, [id], (err, row) => {
    if (err || !row) return res.status(404).json({ error: 'Not found' });
    if (row.qrCode) {
      row.qrCode = { code: row.qrCode, issuedAt: row.qrIssuedAt, expiresAt: row.qrExpiresAt };
    }
    res.json(row);
  });
});

app.get('/sessions/active/:courseCode', (req, res) => {
  const courseCode = req.params.courseCode;
  db.get(`SELECT * FROM sessions WHERE courseCode = ? AND status = 'active'`, [courseCode], (err, row) => {
    if (err || !row) return res.status(404).json({ message: 'No active session' });
    row.enrolledStudentIds = JSON.parse(row.enrolledStudentIds);
    if (row.otpCode) {
      row.otp = { code: row.otpCode, issuedAt: row.otpIssuedAt, expiresAt: row.otpExpiresAt };
    }
    res.json(row);
  });
});

// 8) Get My Sessions (Faculty)
app.get('/api/sessions/faculty/:facultyId', (req, res) => {
  const query = `
    SELECT sessions.*, users.name as proxyFacultyName 
    FROM sessions 
    LEFT JOIN users ON sessions.proxyFacultyId = users.id 
    WHERE facultyId = ? 
    ORDER BY createdAt DESC
  `;
  db.all(query, [req.params.facultyId], (err, rows) => {
    if (err) return res.status(500).json({ error: err.message });
    rows.forEach(row => {
      if (row.qrCode) {
        row.qrCode = { code: row.qrCode, issuedAt: row.qrIssuedAt, expiresAt: row.qrExpiresAt };
      }
    });
    res.json(rows);
  });
});




// 8.5) Get All Sessions Today (For Proxy Conflict Checking)
app.get('/api/sessions/today/all', (req, res) => {
  const startOfDay = new Date();
  startOfDay.setHours(0, 0, 0, 0);
  
  db.all(
    `SELECT courseCode, batchTarget, facultyId, proxyFacultyId, status, slotId FROM sessions WHERE createdAt >= ?`,
    [startOfDay.toISOString()],
    (err, rows) => {
      if (err) return res.status(500).json({ error: err.message });
      res.json(rows);
    }
  );
});


// 9) Mark Attendance
app.post('/api/attendance/mark', authenticateToken, attendanceLimiter, (req, res) => {
  const { sessionId, code } = req.body;
  const studentId = req.user.id; // SECURE: Extracted from verified JWT, cannot be spoofed!

  db.all('SELECT * FROM sessions WHERE id = ? OR groupId = ?', [sessionId, sessionId], (err, sessions) => {
    if (err) return res.status(500).json({ error: err.message });
    if (!sessions || sessions.length === 0) return res.status(404).json({ error: 'Session not found' });

    // Use the first session to validate the QR code (since they all share the same QR/timing logic if grouped)
    const baseSession = sessions[0];
    if (baseSession.status !== 'active') return res.status(400).json({ error: 'sessionClosed', message: 'Session is not currently active.' });
    if (baseSession.qrCode !== code && baseSession.previousQrCode !== code) return res.status(400).json({ error: 'invalidQrCode', message: 'QR Code is invalid or has expired.' });
    if (new Date() > new Date(baseSession.qrExpiresAt)) return res.status(400).json({ error: 'qrExpired', message: 'This QR code has expired.' });

    // Find all sessions in this group where the student is enrolled
    const matchedSessions = sessions.filter(s => {
      let enrolledIds = JSON.parse(s.enrolledStudentIds || '[]');
      return enrolledIds.includes(studentId);
    });

    if (matchedSessions.length === 0) {
      return res.status(400).json({ error: 'studentNotEnrolled', message: 'You are not enrolled in any class covered by this session.' });
    }

    const markedAt = new Date().toISOString();
    let insertCount = 0;
    let duplicateCount = 0;
    let anyError = null;

    // We can insert records for all matched sessions
    matchedSessions.forEach(session => {
      const aid = uuidv4();
      db.run('INSERT INTO attendance_records (id, sessionId, studentId, markedAt, status, method) VALUES (?, ?, ?, ?, ?, ?)',
        [aid, session.id, studentId, markedAt, 'pending', 'qr'],
        function (err) {
          if (err) {
            // Support both SQLite ('UNIQUE') and Postgres ('duplicate key' or 'unique') error formats
            if (err.message.includes('UNIQUE') || err.message.toLowerCase().includes('unique') || err.message.toLowerCase().includes('duplicate key')) {
              duplicateCount++;
            } else {
              anyError = err;
            }
          } else {
            insertCount++;
          }
          if (anyError && insertCount + duplicateCount === matchedSessions.length) {
             return res.status(500).json({ error: anyError.message });
          }
          
          if (insertCount + duplicateCount === matchedSessions.length) {
            if (insertCount === 0 && duplicateCount > 0) {
               return res.status(400).json({ error: 'duplicateAttendance', message: 'Attendance already marked.' });
            }
            res.json({
              success: true,
              message: 'Attendance marked successfully.',
              record: {
                id: aid,
                sessionId: session.id,
                studentId: studentId,
                markedAt: markedAt,
                status: 'pending',
                method: 'qr'
              }
            });
          }
        }
      );
    });
  });
});

// 9.5) Faculty Finalize Attendance
app.post('/api/sessions/:id/attendance/finalize', (req, res) => {
  const sessionId = req.params.id;
  const { updates } = req.body; // array of { studentId, status }

  if (!updates || !Array.isArray(updates)) {
    return res.status(400).json({ error: 'Invalid updates format' });
  }

  db.get('SELECT * FROM sessions WHERE id = ?', [sessionId], (err, session) => {
    if (err || !session) return res.status(404).json({ error: 'Session not found' });

    const timeString = new Date().toLocaleTimeString('en-US', { hour: 'numeric', minute: '2-digit', timeZone: 'Asia/Kolkata' });

    const stmt = db.prepare(`
      INSERT INTO attendance_records (id, sessionId, studentId, markedAt, status, method)
      VALUES (?, ?, ?, ?, ?, ?)
      ON CONFLICT(sessionId, studentId) DO UPDATE SET status = excluded.status
    `);

    db.serialize(() => {
      updates.forEach(u => {
        const aid = uuidv4();
        stmt.run(aid, sessionId, u.studentId, new Date().toISOString(), u.status, 'manual');
      });
      stmt.finalize((err) => {
        if (err) return res.status(500).json({ error: err.message });

        db.run(`UPDATE sessions SET status = 'completed' WHERE id = ?`, [sessionId]);

        const notifStmt = db.prepare('INSERT INTO notifications (id, userId, title, body, tag, tagColor, onTagColor, byName, byIcon, createdAt) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)');

        // Notify all students in this session that their attendance was updated
        updates.forEach(u => {
          const statusText = u.status.toUpperCase();
          const isPending = session.approvalStatus === 'pending';
          
          const title = isPending ? 'Attendance On Hold' : 'Attendance Verified';
          const body = isPending 
            ? `Your attendance for ${session.courseCode} is on hold pending original faculty approval.`
            : `Marked as ${statusText} for ${session.courseCode} at ${timeString}`;
            
          const tagColor = isPending ? 'tertiaryContainer' : (u.status === 'present' ? 'primaryContainer' : 'errorContainer');
          const onTagColor = isPending ? 'onTertiaryContainer' : (u.status === 'present' ? 'onPrimaryContainer' : 'onErrorContainer');
          
          const icon = isPending ? 'pending_actions' : 'check_circle';
          
          notifStmt.run(uuidv4(), u.studentId, title, body, isPending ? 'On Hold' : statusText, tagColor, onTagColor, 'System', icon, new Date().toISOString());
          sendPushNotification(u.studentId, title, body, { type: 'ATTENDANCE_MARKED', status: u.status, isPending: isPending.toString() });
          notifyClients(u.studentId, { type: 'ATTENDANCE_UPDATED', sessionId, title, body });
        });
        notifStmt.finalize();

        // If it was an auto-approved proxy, notify the original faculty NOW (upon submit)
        if (session.proxyFacultyId && session.approvalStatus === 'approved' && session.facultyId !== session.proxyFacultyId) {
           const now = new Date().toISOString();
           const isSeminar = session.courseCode.toLowerCase().includes('seminar') || (session.batchTarget && session.batchTarget.includes(','));
           db.get('SELECT name FROM users WHERE id = ?', [session.proxyFacultyId], (err, row) => {
               const proxyName = row ? row.name : session.proxyFacultyId;
               const title = 'Proxy Session Completed (Auto-Approved)';
               const body = `${proxyName} has submitted attendance for the proxy session of your ${session.courseCode} at ${session.batchTarget} and it was auto-approved${isSeminar ? ' (Seminar)' : ''}.`;
               db.run('INSERT INTO notifications (id, userId, title, body, tag, tagColor, onTagColor, byName, byIcon, createdAt) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
                 [uuidv4(), session.facultyId, title, body, 'Auto-Approved', 'successContainer', 'onSuccessContainer', proxyName, 'check_circle', now]);
               sendPushNotification(session.facultyId, title, body, { type: 'PROXY_AUTO_APPROVED' });
           });
        }
        
        // Notify the faculty who actually submitted the attendance
        const submitterId = session.proxyFacultyId || session.facultyId;
        const submitterTitle = 'Attendance Submitted';
        const submitterBody = `Attendance for ${session.courseCode} has been successfully submitted.`;
        db.run('INSERT INTO notifications (id, userId, title, body, tag, tagColor, onTagColor, byName, byIcon, createdAt) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
          [uuidv4(), submitterId, submitterTitle, submitterBody, 'Completed', 'successContainer', 'onSuccessContainer', 'System', 'check_circle', new Date().toISOString()]);
        sendPushNotification(submitterId, submitterTitle, submitterBody, { type: 'ATTENDANCE_SUBMITTED' });

        res.json({ success: true, message: 'Attendance finalized successfully.' });
      });
    });
  });
});

app.get('/sessions/:id/attendance', (req, res) => {
  db.all(`SELECT * FROM attendance_records WHERE sessionId = ?`, [req.params.id], (err, rows) => {
    if (err) return res.status(500).json({ error: err.message });
    res.json(rows);
  });
});

app.get('/sessions/:id/attendance/details', (req, res) => {
  const q = `
    SELECT a.*, u.name as studentName, u.rollNo as studentRollNo 
    FROM attendance_records a 
    JOIN users u ON a.studentId = u.id 
    WHERE a.sessionId = ?
  `;
  db.all(q, [req.params.id], (err, rows) => {
    if (err) return res.status(500).json({ error: err.message });
    res.json(rows);
  });
});

app.get('/sessions/:id/verification', (req, res) => {
  const sessionId = req.params.id;
  db.get('SELECT enrolledStudentIds FROM sessions WHERE id = ?', [sessionId], (err, session) => {
    if (err || !session) return res.status(404).json({ error: 'Session not found' });

    let enrolledIds = [];
    try {
      enrolledIds = JSON.parse(session.enrolledStudentIds);
    } catch (e) { }

    if (enrolledIds.length === 0) return res.json([]);

    const placeholders = enrolledIds.map(() => '?').join(',');
    const q = `
      SELECT u.id as studentId, u.name, u.email, u.rollNo, u.division, u.electiveBatch, a.status, a.method 
      FROM users u 
      LEFT JOIN attendance_records a ON u.id = a.studentId AND a.sessionId = ?
      WHERE u.id IN (${placeholders})
    `;

    db.all(q, [sessionId, ...enrolledIds], (err, rows) => {
      if (err) return res.status(500).json({ error: err.message });
      res.json(rows);
    });
  });
});

app.get('/api/report/excel/:id', (req, res) => {
  const sessionId = req.params.id;
  db.get('SELECT id, courseCode, batchTarget, facultyId, createdAt, enrolledStudentIds FROM sessions WHERE id = ?', [sessionId], (err, session) => {
    if (err || !session) return res.status(404).json({ error: 'Session not found' });

    let enrolledIds = [];
    try {
      enrolledIds = JSON.parse(session.enrolledStudentIds);
    } catch (e) { }

    if (enrolledIds.length === 0) return res.status(400).json({ error: 'No enrolled students' });

    // 1. Fetch all past & current sessions for this course, faculty, batchTarget to calculate totals
    const qSessions = `SELECT id FROM sessions WHERE courseCode = ? AND facultyId = ? AND batchTarget = ? AND createdAt <= ?`;
    db.all(qSessions, [session.courseCode, session.facultyId, session.batchTarget, session.createdAt], (err, pastSessions) => {
      if (err) return res.status(500).json({ error: err.message });
      
      const sessionIds = pastSessions.map(s => s.id);
      const totalLectures = sessionIds.length;

      // 2. Fetch attendance for ALL these sessions for these students
      const placeholders = enrolledIds.map(() => '?').join(',');
      const sPlaceholders = sessionIds.map(() => '?').join(',');
      
      db.all(`SELECT studentId, sessionId, status FROM attendance_records WHERE studentId IN (${placeholders}) AND sessionId IN (${sPlaceholders})`, [...enrolledIds, ...sessionIds], (err, allAttendance) => {
        if (err) return res.status(500).json({ error: err.message });

        // Map: studentId -> { currentStatus, totalPresent }
        const statsMap = {};
        enrolledIds.forEach(id => statsMap[id] = { currentStatus: 'A', totalPresent: 0 });

        allAttendance.forEach(a => {
          if (a.status === 'present') {
            statsMap[a.studentId].totalPresent++;
          }
          if (a.sessionId === sessionId) {
            statsMap[a.studentId].currentStatus = a.status === 'present' ? 'P' : 'A';
          }
        });

        // 3. Fetch Student details (Ordered by rollNo ascending numerically)
        db.all(`SELECT id, name, rollNo FROM users WHERE id IN (${placeholders}) ORDER BY rollNo ASC`, enrolledIds, async (err, students) => {
          if (err) return res.status(500).json({ error: err.message });

          const workbook = new exceljs.Workbook();
          const worksheet = workbook.addWorksheet('Report');

          worksheet.columns = [
            { header: 'Roll No', key: 'rollNo', width: 15 },
            { header: 'Name', key: 'name', width: 25 },
            { header: 'Date', key: 'date', width: 15 },
            { header: 'Type', key: 'type', width: 15 },
            { header: 'Status', key: 'status', width: 10 },
            { header: 'Total Sessions', key: 'totalSessions', width: 15 },
            { header: 'Total Present', key: 'totalPresent', width: 15 },
            { header: 'Attendance %', key: 'percentage', width: 15 }
          ];

          worksheet.columns.forEach(col => {
            col.protection = { locked: true };
          });

          const dateStr = new Date(session.createdAt).toLocaleDateString('en-GB');
          const typeStr = session.batchTarget.includes('All') ? 'Lecture' : 'Lab';

          students.forEach(student => {
            const stats = statsMap[student.id];
            const pct = totalLectures === 0 ? '0%' : `${Math.round((stats.totalPresent / totalLectures) * 100)}%`;
            worksheet.addRow({
              rollNo: student.rollNo || 'N/A',
              name: student.name || 'Unknown',
              date: dateStr,
              type: typeStr,
              status: stats.currentStatus,
              totalSessions: totalLectures,
              totalPresent: stats.totalPresent,
              percentage: pct
            });
          });

          await worksheet.protect('vesit123', {
            selectLockedCells: true,
            selectUnlockedCells: false,
            formatCells: false,
            formatColumns: false,
            formatRows: false,
            insertColumns: false,
            insertRows: false,
            insertHyperlinks: false,
            deleteColumns: false,
            deleteRows: false,
            sort: false,
            autoFilter: false
          });
          res.setHeader('Content-Type', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
          res.setHeader('Content-Disposition', `attachment; filename="Report_${session.courseCode}.xlsx"`);
          await workbook.xlsx.write(res);
          res.end();
        });
      });
    });
  });
});

app.get('/api/report/bulk-excel', (req, res) => {
  const { facultyId, subject, batchTarget, startDate, endDate } = req.query;
  
  if (!facultyId || !subject || !startDate || !endDate) {
    return res.status(400).json({ error: 'Missing required parameters' });
  }

  // 1. Get all sessions matching criteria
  let q = 'SELECT id, courseCode, batchTarget, createdAt, enrolledStudentIds FROM sessions WHERE facultyId = ? AND courseCode = ? AND createdAt >= ? AND createdAt <= ?';
  let params = [facultyId, subject, startDate, endDate];
  
  if (batchTarget && batchTarget !== 'All') {
    q += ' AND batchTarget = ?';
    params.push(batchTarget);
  }
  
  q += ' ORDER BY createdAt ASC';

  db.all(q, params, async (err, sessions) => {
    if (err) return res.status(500).json({ error: err.message });
    if (sessions.length === 0) return res.status(400).send('No sessions found in this date range');

    // 2. Gather all unique enrolled student IDs across these sessions
    let uniqueStudentIds = new Set();
    sessions.forEach(s => {
      try {
        const ids = JSON.parse(s.enrolledStudentIds);
        ids.forEach(id => uniqueStudentIds.add(id));
      } catch(e) {}
    });

    if (uniqueStudentIds.size === 0) return res.status(400).send('No students enrolled in these sessions');

    const studentIdsArr = Array.from(uniqueStudentIds);
    const placeholders = studentIdsArr.map(() => '?').join(',');

    // 3. Fetch student details (Ordered by rollNo ascending numerically)
    db.all(`SELECT id, name, rollNo FROM users WHERE id IN (${placeholders}) ORDER BY rollNo ASC`, studentIdsArr, (err, students) => {
      if (err) return res.status(500).json({ error: err.message });

      // 4. Fetch all attendance records for these sessions
      const sessionIds = sessions.map(s => s.id);
      const sessionPlaceholders = sessionIds.map(() => '?').join(',');
      db.all(`SELECT sessionId, studentId, status FROM attendance_records WHERE sessionId IN (${sessionPlaceholders})`, sessionIds, async (err, records) => {
        if (err) return res.status(500).json({ error: err.message });

        // Map records: map[studentId][sessionId] = status
        const attendanceMap = {};
        records.forEach(r => {
          if (!attendanceMap[r.studentId]) attendanceMap[r.studentId] = {};
          attendanceMap[r.studentId][r.sessionId] = r.status;
        });

        // 5. Generate Excel
        const workbook = new exceljs.Workbook();
        const worksheet = workbook.addWorksheet('Bulk Report');

        // Dynamic Columns
        const columns = [
          { header: 'Roll No', key: 'rollNo', width: 15 },
          { header: 'Name', key: 'name', width: 25 }
        ];

        sessions.forEach((s, index) => {
          const dateStr = new Date(s.createdAt).toLocaleDateString('en-GB');
          const typeStr = s.batchTarget && s.batchTarget.includes('All') ? 'Lec' : 'Lab';
          columns.push({ header: `${typeStr} ${index+1} (${dateStr})`, key: `session_${s.id}`, width: 18 });
        });

        columns.push({ header: 'Total Sessions', key: 'totalSessions', width: 15 });
        columns.push({ header: 'Total Present', key: 'totalPresent', width: 15 });
        columns.push({ header: 'Attendance %', key: 'percentage', width: 15 });

        worksheet.columns = columns;

        // Rows
        students.forEach(student => {
          const rowData = {
            rollNo: student.rollNo || 'N/A',
            name: student.name || 'Unknown'
          };

          let presentCount = 0;

          sessions.forEach(s => {
            const status = (attendanceMap[student.id] && attendanceMap[student.id][s.id]) || 'absent';
            rowData[`session_${s.id}`] = status === 'present' ? 'P' : 'A';
            if (status === 'present') presentCount++;
          });

          const totalSessions = sessions.length;
          rowData.totalSessions = totalSessions;
          rowData.totalPresent = presentCount;
          rowData.percentage = totalSessions === 0 ? '0%' : `${Math.round((presentCount / totalSessions) * 100)}%`;

          worksheet.addRow(rowData);
        });

        // Apply strict password protection
        worksheet.columns.forEach(col => {
          col.protection = { locked: true };
        });

        await worksheet.protect('vesit123', {
          selectLockedCells: true,
          selectUnlockedCells: false,
          formatCells: false,
          formatColumns: false,
          formatRows: false,
          insertColumns: false,
          insertRows: false,
          insertHyperlinks: false,
          deleteColumns: false,
          deleteRows: false,
          sort: false,
          autoFilter: false
        });

        res.setHeader('Content-Type', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
        res.setHeader('Content-Disposition', `attachment; filename="BulkReport_${subject}.xlsx"`);
        
        await workbook.xlsx.write(res);
        res.end();
      });
    });
  });
});




// Reset tokens are now stored in the database.
// POST /forgot-password — verifies email exists, returns a 6-digit reset code
app.post('/forgot-password', (req, res) => {
  const { email } = req.body;
  if (!email) return res.status(400).json({ error: 'Email is required' });

  db.get(`SELECT id, email FROM users WHERE LOWER(email) = LOWER(?)`, [email], (err, row) => {
    if (err) return res.status(500).json({ error: err.message });
    if (!row) return res.status(404).json({ error: 'No account found with this email' });

    // Generate a 6-digit OTP
    const token = Math.floor(100000 + Math.random() * 900000).toString();
    const isProduction = process.env.NODE_ENV === 'production' || process.env.DATABASE_URL;
    let expiryDate;
    
    if (isProduction) {
      // Postgres TIMESTAMP expects 'YYYY-MM-DD HH:MM:SS' or ISO string
      expiryDate = new Date(Date.now() + 10 * 60 * 1000).toISOString();
    } else {
      expiryDate = new Date(Date.now() + 10 * 60 * 1000).toISOString();
    }

    // First delete any existing token for this email to avoid duplicate primary key on retry
    db.run(`DELETE FROM reset_tokens WHERE LOWER(email) = LOWER(?)`, [row.email], (delErr) => {
      // Insert new token
      db.run(`INSERT INTO reset_tokens (token, email, expiry) VALUES (?, ?, ?)`, [token, row.email, expiryDate], (insertErr) => {
        if (insertErr) return res.status(500).json({ error: 'Failed to generate reset token' });

        // Send real OTP email
        const mailOptions = {
          from: `"AMS – Attendance System" <${process.env.MAIL_USER}>`,
          to: row.email,
          subject: 'Your AMS Password Reset Code',
          html: `
            <div style="font-family:sans-serif;max-width:480px;margin:auto;border:1px solid #e0e0e0;border-radius:12px;overflow:hidden">
              <div style="background:#002147;padding:24px;text-align:center">
                <h2 style="color:#FFD700;margin:0;font-size:22px;letter-spacing:2px">AMS – VESIT</h2>
                <p style="color:#fff;margin:4px 0 0;font-size:13px">Attendance Management System</p>
              </div>
              <div style="padding:28px">
                <p style="font-size:15px;color:#333">Hi there,</p>
                <p style="font-size:15px;color:#333">Use the code below to reset your password. It expires in <strong>10 minutes</strong>.</p>
                <div style="background:#f4f4f4;border-radius:10px;padding:20px;text-align:center;margin:24px 0">
                  <span style="font-size:40px;font-weight:bold;letter-spacing:12px;color:#002147">${token}</span>
                </div>
                <p style="font-size:13px;color:#888">If you didn't request this, you can safely ignore this email.</p>
              </div>
            </div>
          `,
        };

        mailer.sendMail(mailOptions, (mailErr) => {
          if (mailErr) {
            console.error('[MAIL ERROR]', mailErr);
            return res.status(500).json({ error: 'Failed to send reset email. Check server mail config.' });
          }
          console.log(`[RESET] OTP sent to ${email}`);
          res.json({ message: 'Reset code sent to your email' }); // token NOT returned in prod
        });
      });
    });
  });
});

// POST /reset-password — verifies token and sets new password
app.post('/reset-password', (req, res) => {
  const { token, newPassword } = req.body;
  if (!token || !newPassword) return res.status(400).json({ error: 'Token and new password are required' });

  db.get(`SELECT * FROM reset_tokens WHERE token = ?`, [token], (err, record) => {
    if (err) return res.status(500).json({ error: err.message });
    if (!record) return res.status(400).json({ error: 'Invalid or expired reset code' });
    
    if (new Date() > new Date(record.expiry)) {
      db.run(`DELETE FROM reset_tokens WHERE token = ?`, [token]);
      return res.status(400).json({ error: 'Reset code has expired. Please request a new one.' });
    }

    db.run(`UPDATE users SET password = ? WHERE LOWER(email) = LOWER(?)`, [newPassword, record.email], function (err) {
      if (err) return res.status(500).json({ error: err.message });
      
      db.run(`DELETE FROM reset_tokens WHERE token = ?`, [token]); // Single-use token
      res.json({ message: 'Password updated successfully' });
    });
  });
});

// POST /change-password — verifies current password and sets new password
app.post('/change-password', (req, res) => {
  const { userId, currentPassword, newPassword } = req.body;
  if (!userId || !currentPassword || !newPassword) return res.status(400).json({ error: 'Missing fields' });

  db.get(`SELECT id FROM users WHERE id = ? AND password = ?`, [userId, currentPassword], (err, row) => {
    if (err) return res.status(500).json({ error: err.message });
    if (!row) return res.status(401).json({ error: 'Incorrect current password' });

    db.run(`UPDATE users SET password = ? WHERE id = ?`, [newPassword, userId], function(err) {
      if (err) return res.status(500).json({ error: err.message });
      res.json({ message: 'Password updated successfully' });
    });
  });
});

// GET timetable slots for a student for a specific day
app.get('/api/timetable/student/:studentId', (req, res) => {
  const { studentId } = req.params;
  let { day } = req.query; // e.g., 'Mon', 'Tue'

  // Make day optional. If provided, filter by day.

  db.get('SELECT division, coreBatch, electiveSubject, electiveBatch FROM users WHERE id = ?', [studentId], (err, student) => {
    if (err) return res.status(500).json({ error: err.message });
    if (!student) return res.status(404).json({ error: 'Student not found' });

    const { division, coreBatch, electiveSubject, electiveBatch } = student;

    const validTargets = [
      `${division} - All`,
      `${division} - ${coreBatch}`,
      `${division} - ${electiveBatch} (${electiveSubject})`,
      `TE - ${electiveSubject} (All)`,
      `TE - ${electiveSubject} (${electiveBatch})`
    ];

    const placeholders = validTargets.map(() => '?').join(',');
    let query = `
      SELECT t.*, u.name as facultyName, u.email as facultyEmail
      FROM timetable_slots t
      JOIN users u ON t.facultyId = u.id
      WHERE t.batchTarget IN (${placeholders})
    `;

    let params = [...validTargets];

    if (day) {
      query += ` AND t.day = ?`;
      params.push(day);
    }

    query += ` ORDER BY t.startTime ASC`;

    db.all(query, params, (err, rows) => {
      if (err) return res.status(500).json({ error: err.message });
      res.json(rows);
    });
  });
});

// GET student attendance history (Hybrid Approach)
app.get('/api/attendance/student/:studentId/history', (req, res) => {
  const { studentId } = req.params;

  // 1. Fetch closed & approved sessions where student is enrolled
  const query = `
    SELECT s.id as sessionId, s.courseCode, s.createdAt, s.facultyId, 
           u.name as facultyName
    FROM sessions s
    LEFT JOIN users u ON s.facultyId = u.id
    WHERE s.status IN ('active', 'closed')
      AND s.approvalStatus = 'approved'
      AND s.enrolledStudentIds LIKE ?
    ORDER BY s.createdAt DESC
  `;
  
  db.all(query, [`%${studentId}%`], (err, sessions) => {
    if (err) return res.status(500).json({ error: err.message });
    if (sessions.length === 0) return res.json([]);

    // 2. For each session, fetch if student attended
    const sessionIds = sessions.map(s => s.sessionId);
    const placeholders = sessionIds.map(() => '?').join(',');
    
    db.all(`SELECT sessionId, status FROM attendance_records WHERE studentId = ? AND sessionId IN (${placeholders})`, [studentId, ...sessionIds], (err, records) => {
      if (err) return res.status(500).json({ error: err.message });

      const attendanceMap = {};
      records.forEach(r => attendanceMap[r.sessionId] = r.status); // usually 'present'

      // 3. Match with timetable to get venue and time
      db.get('SELECT division, coreBatch, electiveSubject, electiveBatch FROM users WHERE id = ?', [studentId], (err, student) => {
        if (err || !student) return res.json([]);
        
        const { division, coreBatch, electiveSubject, electiveBatch } = student;
        const validTargets = [
          `${division} - All`,
          `${division} - ${coreBatch}`,
          `${division} - ${electiveBatch} (${electiveSubject})`,
          `TE - ${electiveSubject} (All)`,
          `TE - ${electiveSubject} (${electiveBatch})`
        ];
        
        const tPlaceholders = validTargets.map(() => '?').join(',');
        const tQuery = `SELECT * FROM timetable_slots WHERE batchTarget IN (${tPlaceholders})`;
        
        db.all(tQuery, validTargets, (err, tSlots) => {
          if (err) tSlots = [];
          
          const history = sessions.map(s => {
            const date = new Date(s.createdAt);
            const days = ['Sun','Mon','Tue','Wed','Thu','Fri','Sat'];
            const dayStr = days[date.getDay()];
            
            let venue = 'Campus';
            let timeStr = date.toLocaleTimeString('en-US', { hour: '2-digit', minute: '2-digit' });
            
            const matchingSlot = tSlots.find(t => 
              t.facultyId === s.facultyId && 
              t.day === dayStr && 
              s.courseCode.includes(t.subject)
            );
            
            if (matchingSlot) {
              venue = matchingSlot.venue;
              timeStr = `${matchingSlot.startTime} - ${matchingSlot.endTime}`;
            } else if (s.courseCode.toLowerCase().includes('seminar')) {
              venue = 'Seminar Hall';
            }
            
            return {
              sessionId: s.sessionId,
              subject: s.courseCode,
              time: timeStr,
              location: venue,
              professor: s.facultyName || 'Unknown Faculty',
              status: attendanceMap[s.sessionId] === 'present' ? 'present' : 'missed',
              date: s.createdAt
            };
          });
          
          res.json(history);
        });
      });
    });
  });
});

function notifyTimetableUpdate(facultyId, subject, batchTarget) {
  setTimeout(() => {
    db.get('SELECT name FROM users WHERE id = ?', [facultyId], (err, faculty) => {
      if (err || !faculty) return;
    const facultyName = faculty.name;

    db.all('SELECT id, division, coreBatch, electiveSubject, electiveBatch FROM users WHERE role=\'student\'', [], (err, students) => {
      if (err) return;
      students.forEach(student => {
        const { id: studentId, division, coreBatch, electiveSubject, electiveBatch } = student;
        const validTargets = [
          `${division} - All`,
          `${division} - ${coreBatch}`,
          `${division} - ${electiveBatch} (${electiveSubject})`,
          `TE - ${electiveSubject} (All)`,
          `TE - ${electiveSubject} (${electiveBatch})`
        ];
        if (validTargets.includes(batchTarget)) {
          const notifId = uuidv4();
          const title = `Timetable updated for ${subject}`;
          const body = `Changes made by ${facultyName} for batch ${batchTarget}.`;

          db.run(
            'INSERT INTO notifications (id, userId, title, body, tag, tagColor, onTagColor, byName, byIcon, createdAt) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
            [notifId, studentId, title, body, 'Schedule Change', 'primaryContainer', 'onPrimaryContainer', facultyName, 'person', new Date().toISOString()],
            (err) => {
              if (!err) {
                notifyClients(studentId, {
                  type: 'TIMETABLE_UPDATED',
                  title: 'Schedule Change',
                  body: title
                });
                sendPushNotification(studentId, 'Schedule Change', title, { type: 'TIMETABLE_UPDATED' });
              }
            }
          );
        }
      });
    });
    });
  }, 1000);
}

function calculateEndTime(startTime, type) {
  if (!startTime || !startTime.includes(':')) return startTime;
  const parts = startTime.split(':');
  let h = parseInt(parts[0], 10);
  let m = parts[1];

  if (type === 'Lab') {
    h += 2;
  } else {
    h += 1; // Default for Lecture
  }

  if (h >= 24) h -= 24;

  return `${h.toString().padStart(2, '0')}:${m}`;
}


function parseTimeStr(tStr) {
  if (!tStr) return 0;
  const parts = tStr.trim().split(' ');
  const hm = parts[0].split(':').map(Number);
  let hr = hm[0] || 0;
  const min = hm[1] || 0;
  if (parts.length > 1) {
    const ampm = parts[1].toUpperCase();
    if (ampm === 'PM' && hr < 12) hr += 12;
    if (ampm === 'AM' && hr === 12) hr = 0;
  }
  return hr * 60 + min;
}

function checkTimetableOverlap(facultyId, day, batchTarget, startTime, endTime, excludeId, callback) {
  db.all('SELECT ts.*, u.name as facultyName FROM timetable_slots ts JOIN users u ON ts.facultyId = u.id WHERE ts.day = ?', [day], (err, slots) => {
    if (err) return callback(err, null);
    
    const newStart = parseTimeStr(startTime);
    const newEnd = parseTimeStr(endTime);

    for (const slot of slots) {
      if (excludeId && slot.id === excludeId) continue;
      
      const st = slot.startTime || '00:00';
      const et = slot.endTime || '00:00';
      const slotStart = parseTimeStr(st);
      const slotEnd = parseTimeStr(et);
      
      const overlaps = Math.max(newStart, slotStart) < Math.min(newEnd, slotEnd);
      
      if (overlaps) {
        if (slot.facultyId === facultyId) {
           return callback(null, `Conflict: You are already scheduled to teach '${slot.subject}' at ${st} (Venue: ${slot.venue}).`);
        }
        
        const bTarget = batchTarget || '';
        const sBatchTarget = slot.batchTarget || '';
        const parts1 = bTarget.split(' - ');
        const parts2 = sBatchTarget.split(' - ');
        if (parts1.length === 2 && parts2.length === 2) {
          const div1 = parts1[0]; const sub1 = parts1[1];
          const div2 = parts2[0]; const sub2 = parts2[1];
          if (div1 === div2 && (sub1 === 'All' || sub2 === 'All' || sub1 === sub2)) {
            const facName = slot.facultyName || slot.facultyId;
            return callback(null, `Conflict: ${slot.batchTarget} is already scheduled for '${slot.subject}' with Prof. ${facName} at ${slot.startTime} (Venue: ${slot.venue}).`);
          }
        }
      }
    }
    callback(null, null); // No overlap
  });
}

// GET all timetable slots (used by Timetable Manager)
app.get('/api/timetable', (req, res) => {
  db.all('SELECT * FROM timetable_slots', (err, rows) => {
    if (err) return res.status(500).json({ error: err.message });
    res.json(rows);
  });
});

// POST new timetable slot
app.post('/api/timetable', (req, res) => {
  const { facultyId, day, subject, type, batchTarget, venue, startTime } = req.body;
  const endTime = calculateEndTime(startTime, type);
  
  checkTimetableOverlap(facultyId, day, batchTarget, startTime, endTime, null, (err, conflictError) => {
    if (err) return res.status(500).json({ error: err.message });
    if (conflictError) return res.status(400).json({ error: conflictError });
    
    const id = uuidv4();
    db.run(
      'INSERT INTO timetable_slots (id, facultyId, day, subject, type, batchTarget, venue, startTime, endTime) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)',
      [id, facultyId, day, subject, type, batchTarget, venue, startTime, endTime],
      function (err) {
        if (err) return res.status(500).json({ error: err.message });
        notifyTimetableUpdate(facultyId, subject, batchTarget);
        res.json({ id });
      }
    );
  });
});

// PUT update timetable slot
app.put('/api/timetable/:id', (req, res) => {
  const { id } = req.params; console.log("PUT timetable id:", id, "body:", req.body);
  const { facultyId, day, subject, type, batchTarget, venue, startTime } = req.body;
  const endTime = calculateEndTime(startTime, type);
  
  checkTimetableOverlap(facultyId, day, batchTarget, startTime, endTime, id, (err, conflictError) => {
    if (err) return res.status(500).json({ error: err.message });
    if (conflictError) return res.status(400).json({ error: conflictError });

    db.run(
      'UPDATE timetable_slots SET day=?, subject=?, type=?, batchTarget=?, venue=?, startTime=?, endTime=? WHERE id=?',
      [day, subject, type, batchTarget, venue, startTime, endTime, id],
      function (err) {
        if (err) return res.status(500).json({ error: err.message });
        notifyTimetableUpdate(facultyId, subject, batchTarget);
        res.json({ success: true });
      }
    );
  });
});

// DELETE timetable slot
app.delete('/api/timetable/:id', (req, res) => {
  const { id } = req.params; console.log("PUT timetable id:", id, "body:", req.body);
  // We need facultyId, subject, batchTarget for notification before deleting
  db.get('SELECT facultyId, subject, batchTarget FROM timetable_slots WHERE id = ?', [id], (err, row) => {
    if (err) return res.status(500).json({ error: err.message });
    if (!row) return res.status(404).json({ error: 'Slot not found' });

    db.run('DELETE FROM timetable_slots WHERE id = ?', [id], function (err) {
      if (err) return res.status(500).json({ error: err.message });
      notifyTimetableUpdate(row.facultyId, row.subject, row.batchTarget);
      res.json({ success: true });
    });
  });
});

// GET timetable slots for a faculty
// GET all timetable slots globally (for proxy QR generation)
app.get('/timetable', (req, res) => {
  db.all(`
    SELECT t.*, u.name as facultyName
    FROM timetable_slots t
    JOIN users u ON u.id = t.facultyId
    ORDER BY t.subject, t.type, t.batchTarget
  `, (err, rows) => {
    if (err) return res.status(500).json({ error: err.message });
    res.json(rows);
  });
});

app.get('/timetable/:facultyId', (req, res) => {
  const facultyId = req.params.facultyId;
  const today = new Date().toISOString().split('T')[0];
  const todayStart = `${today} 00:00:00`;
  const todayEnd = `${today} 23:59:59`;

  db.all(`SELECT * FROM timetable_slots WHERE facultyId = ?`, [facultyId], (err, slots) => {
    if (err) return res.status(500).json({ error: err.message });

    // Fetch today's sessions for this faculty to prevent duplicate QR generation
    const checkQuery = isProduction
      ? `SELECT courseCode, batchTarget FROM sessions WHERE facultyId = $1 AND createdAt >= $2 AND createdAt <= $3`
      : `SELECT courseCode, batchTarget FROM sessions WHERE facultyId = ? AND createdAt >= ? AND createdAt <= ?`;

    db.all(checkQuery, [facultyId, todayStart, todayEnd], (err, sessions) => {
      if (err) return res.status(500).json({ error: err.message });
      
      const enrichedSlots = slots.map(slot => {
        // Find if there's any session today that matches this slot's subject and batchTarget
        // Note: when a session is created from a slot, courseCode = slot.subject, and batchTarget = slot.batchTarget
        const hasSessionToday = sessions.some(s => s.courseCode === slot.subject && s.batchTarget === slot.batchTarget);
        return {
          ...slot,
          hasSessionToday
        };
      });
      
      res.json(enrichedSlots);
    });
  });
});
// GET notifications for a student
app.get('/api/notifications/:userId', (req, res) => {
  db.all('SELECT * FROM notifications WHERE userId = ? ORDER BY createdAt DESC', [req.params.userId], (err, rows) => {
    if (err) return res.status(500).json({ error: err.message });
    res.json(rows);
  });
});

// PUT mark notification as read
app.put('/api/notifications/:id/read', (req, res) => {
  db.run('UPDATE notifications SET isRead = 1 WHERE id = ?', [req.params.id], function (err) {
    if (err) return res.status(500).json({ error: err.message });
    res.json({ success: true });
  });
});

// PUT mark all notifications as read for user
app.put('/api/notifications/user/:userId/read-all', (req, res) => {
  db.run('UPDATE notifications SET isRead = 1 WHERE userId = ?', [req.params.userId], function (err) {
    if (err) return res.status(500).json({ error: err.message });
    res.json({ success: true });
  });
});

// GET student attendance stats with predictive margin calculations
app.get('/api/attendance/student/:studentId/stats', (req, res) => {
  const rawId = req.params.studentId;

  // Resolve: if looks like an email, map to UUID via users table; otherwise use as-is
  const resolveId = (cb) => {
    if (rawId.includes('@')) {
      db.get(`SELECT id FROM users WHERE email = ?`, [rawId], (err, row) => {
        if (err || !row) return cb(null, rawId); // fallback
        cb(null, row.id);
      });
    } else {
      cb(null, rawId);
    }
  };

  resolveId((err, studentId) => {
    // 1. Get all APPROVED sessions for this student (UUIDs stored in JSON array)
    db.all(`SELECT id, courseCode FROM sessions WHERE enrolledStudentIds LIKE ? AND approvalStatus = 'approved'`, [`%"${studentId}"%`], (err, sessions) => {
      if (err) return res.status(500).json({ error: err.message });

      const stats = {};
      let overallTotal = 0;
      sessions.forEach(s => {
        let name = s.courseCode.trim();
        let key = name.toLowerCase();
        if (!key.endsWith(' - lab') && !key.endsWith(' - lecture')) {
          key += ' - lecture';
          name += ' - Lecture';
        }

        if (!stats[key]) stats[key] = { name: name, total: 0, attended: 0 };
        stats[key].total++;
        overallTotal++;
      });

      // 2. Get attended sessions
      db.all(`
        SELECT s.courseCode 
        FROM attendance_records a
        JOIN sessions s ON a.sessionId = s.id
        WHERE a.studentId = ? AND a.status = 'present' AND s.approvalStatus = 'approved'
      `, [studentId], (err, attendedRows) => {
        if (err) return res.status(500).json({ error: err.message });

        let overallAttended = 0;
        attendedRows.forEach(row => {
          let key = row.courseCode.trim().toLowerCase();
          if (!key.endsWith(' - lab') && !key.endsWith(' - lecture')) {
            key += ' - lecture';
          }

          if (stats[key]) {
            stats[key].attended++;
            overallAttended++;
          }
        });

        // Calculate margins and statuses
        let subjects = Object.keys(stats).map(key => {
          const s = stats[key];
          const subject = s.name;
          const t = s.total;
          const a = s.attended;
          const percentage = t > 0 ? (a / t) * 100 : 0;

          let status = 'CRITICAL';
          if (percentage >= 75.0) status = 'SAFE';
          else if (percentage >= 50.0) status = 'WARNING';

          let marginType = 'safe';
          let marginAmount = 0;

          // Target is 55%
          if (percentage < 55.0) {
            marginType = 'recover';
            // ceil((0.55*total - attended) / 0.45)
            marginAmount = Math.max(0, Math.ceil((0.55 * t - a) / 0.45));
          } else {
            marginType = 'safe';
            // floor((attended - 0.55*total) / 0.55)
            marginAmount = Math.max(0, Math.floor((a - 0.55 * t) / 0.55));
          }

          return {
            courseCode: subject,
            totalSessions: t,
            attendedSessions: a,
            totalClasses: t, // Add this for UI fallback
            attendedClasses: a, // Add this for UI fallback
            percentage: parseFloat(percentage.toFixed(2)),
            status,
            marginType,
            marginAmount
          };
        });

        let overallPercentage = overallTotal > 0 ? (overallAttended / overallTotal) * 100 : 0;

        res.json({
          overallPercentage: parseFloat(overallPercentage.toFixed(2)),
          thisWeekPercentage: parseFloat(overallPercentage.toFixed(2)),
          totalClasses: overallTotal, // Add root level classes
          attendedClasses: overallAttended, // Add root level attended
          subjects
        });
      });
    });
  });
});

if (require.main === module) {
  app.listen(3000, () => {
    console.log('Server running on port 3000');
  });
}
module.exports = app;

function handleSmartSeminarAttendance(req, res, session, userId, method) {
  const meta = JSON.parse(session.metadata || '{}');
  const { divisions, startTime, endTime } = meta;
  const now = new Date().toISOString();

  // Find the student's batches
  db.get('SELECT division, coreBatch, electiveBatch FROM users WHERE id = ?', [userId], (err, user) => {
    if (err) return res.status(500).json({ error: err.message });
    if (!user) return res.status(404).json({ error: 'User not found' });

    if (!divisions.includes(user.division)) {
      return res.status(403).json({ error: 'You are not in the division for this seminar.' });
    }

    // Parse times
    const startDt = new Date(startTime);
    const endDt = new Date(endTime);
    const dayNames = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    const todayStr = dayNames[startDt.getDay()];

    const startTotalMins = startDt.getHours() * 60 + startDt.getMinutes();
    const endTotalMins = endDt.getHours() * 60 + endDt.getMinutes();

    // Query timetable for matching slots
    db.all('SELECT * FROM timetable_slots WHERE day = ?', [todayStr], (err, slots) => {
       if (err) return res.status(500).json({ error: err.message });

       const matchingSlots = slots.filter(s => {
          // Check if batch matches (All, coreBatch, or electiveBatch)
          if (!s.batchTarget.includes(user.division)) return false;
          
          let matchesBatch = false;
          if (s.batchTarget.includes('All')) matchesBatch = true;
          if (user.coreBatch && s.batchTarget.includes(user.coreBatch)) matchesBatch = true;
          if (user.electiveBatch && s.batchTarget.includes(user.electiveBatch)) matchesBatch = true;
          if (!matchesBatch) return false;

          // Check time overlap
          const [sH, sM] = s.startTime.split(':').map(Number);
          const [eH, eM] = s.endTime.split(':').map(Number);
          const slotStart = sH * 60 + sM;
          const slotEnd = eH * 60 + eM;

          // Overlap if max(start1, start2) < min(end1, end2)
          return Math.max(startTotalMins, slotStart) < Math.min(endTotalMins, slotEnd);
       });

       if (matchingSlots.length === 0) {
          return res.status(400).json({ error: 'No scheduled lectures found for your batches in this time window.' });
       }

       // For each matching slot, generate a session if not exists, and mark attendance
       let completedCount = 0;
       
       matchingSlots.forEach(slot => {
          // Find or create session for this slot today
          // We can use a deterministic ID based on slot.id and date
          const subSessionId = `seminar_sub_${session.id}_${slot.id}`;
          
          db.run(`INSERT OR IGNORE INTO sessions (id, courseCode, facultyId, proxyFacultyId, status, createdAt, approvalStatus)
                  VALUES (?, ?, ?, ?, 'scheduled', ?, 'approved')`,
            [subSessionId, slot.subject, slot.facultyId, session.facultyId, now],
            (err) => {
               // Then insert attendance
               const attId = uuidv4();
               db.run(`INSERT OR IGNORE INTO attendance_records (id, sessionId, studentId, markedAt, status, method)
                       VALUES (?, ?, ?, ?, 'present', ?)`,
                 [attId, subSessionId, userId, now, method],
                 (err) => {
                    completedCount++;
                    if (completedCount === matchingSlots.length) {
                       res.json({ success: true, message: `Marked present for ${matchingSlots.length} overlapping classes.` });
                    }
                 }
               );
            }
          );
       });
    });
  });
}
