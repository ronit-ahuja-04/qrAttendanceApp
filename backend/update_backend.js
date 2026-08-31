const fs = require('fs');

let content = fs.readFileSync('index.js', 'utf8');

const helperFunc = `
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
`;

// Insert the helper function above app.post('/sessions')
content = content.replace("app.post('/sessions', (req, res) => {", helperFunc + "\napp.post('/sessions', (req, res) => {");

// Now rewrite the /sessions route to use it
const oldSessionsRoute = `    let whereClause = "role = 'student'";
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
    }`;

content = content.replace(oldSessionsRoute, `    let whereClause = getSessionTargetStudents(courseCode, batchTarget);`);

// Now add the /sessions/seminar endpoint
const seminarEndpoint = `
app.post('/sessions/seminar', async (req, res) => {
  const { targets, proxyFacultyId } = req.body;
  if (!targets || !Array.isArray(targets) || targets.length === 0) {
    return res.status(400).json({ error: 'Missing targets' });
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
        db.run('INSERT INTO sessions (id, courseCode, facultyId, proxyFacultyId, status, enrolledStudentIds, createdAt, approvalStatus, groupId) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)',
          [id, t.courseCode, scopeFacultyId, proxyFacultyId, 'scheduled', JSON.stringify(enrolledIds), now, 'pending', groupId],
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
`;

content = content.replace("app.post('/sessions', (req, res) => {", seminarEndpoint + "\napp.post('/sessions', (req, res) => {");

fs.writeFileSync('index.js', content);
console.log('Backend index.js updated');
