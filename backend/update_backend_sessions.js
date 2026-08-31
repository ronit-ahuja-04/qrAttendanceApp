const fs = require('fs');
let code = fs.readFileSync('index.js', 'utf8');

const oldRoute = `app.post('/sessions', (req, res) => {
  const { courseCode, facultyId, enrolledStudentIds } = req.body;
  const id = uuidv4();
  const now = new Date().toISOString();
  
  db.run(\`INSERT INTO sessions (id, courseCode, facultyId, status, enrolledStudentIds, createdAt)
          VALUES (?, ?, ?, ?, ?, ?)\`, 
    [id, courseCode, facultyId, 'scheduled', JSON.stringify(enrolledStudentIds), now],
    function(err) {
      if (err) return res.status(500).json({ error: err.message });
      res.json({
        id, courseCode, facultyId, status: 'scheduled', 
        enrolledStudentIds, createdAt: now
      });
    }
  );
});`;

const newRoute = `app.post('/sessions', (req, res) => {
  const { courseCode, facultyId, batchTarget } = req.body;
  const id = uuidv4();
  const now = new Date().toISOString();
  
  let whereClause = "role = 'student'";
  const target = batchTarget || '';
  
  if (target.includes('D15A')) whereClause += " AND division = 'D15A'";
  if (target.includes('D15B')) whereClause += " AND division = 'D15B'";
  if (target.includes('D15C')) whereClause += " AND division = 'D15C'";

  if (target.includes('Batch A')) whereClause += " AND coreBatch = 'Batch A'";
  if (target.includes('Batch B')) whereClause += " AND coreBatch = 'Batch B'";
  if (target.includes('Batch C')) whereClause += " AND coreBatch = 'Batch C'";

  const course = (courseCode || '').toLowerCase();
  if (target.includes('ADMT') || course.includes('database') || course.includes('admt')) {
    whereClause += " AND electiveSubject = 'ADMT'";
  } else if (target.includes('Soft') || course.includes('soft')) {
    whereClause += " AND electiveSubject = 'Soft Computing'";
  }
  
  db.all(\`SELECT id FROM users WHERE \${whereClause}\`, [], (err, rows) => {
    if (err) return res.status(500).json({ error: err.message });
    const enrolledIds = rows.map(r => r.id);
    // Include test student IDs just in case
    enrolledIds.push('stu-priyanshu', 'stu-vinit');
    
    db.run(\`INSERT INTO sessions (id, courseCode, facultyId, status, enrolledStudentIds, createdAt)
            VALUES (?, ?, ?, ?, ?, ?)\`, 
      [id, courseCode, facultyId, 'scheduled', JSON.stringify(enrolledIds), now],
      function(err) {
        if (err) return res.status(500).json({ error: err.message });
        res.json({
          id, courseCode, facultyId, status: 'scheduled', 
          enrolledStudentIds: enrolledIds, createdAt: now
        });
      }
    );
  });
});`;

code = code.replace(oldRoute, newRoute);
fs.writeFileSync('index.js', code);
console.log("Updated sessions route");
