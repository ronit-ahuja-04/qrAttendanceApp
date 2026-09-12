const fs = require('fs');
let code = fs.readFileSync('index.js', 'utf8');

if (!code.includes('/timetable/:facultyId')) {
  const newRoute = `
// GET timetable slots for a faculty
app.get('/timetable/:facultyId', (req, res) => {
  const facultyId = req.params.facultyId;
  db.all(\`SELECT * FROM timetable_slots WHERE facultyId = ?\`, [facultyId], (err, rows) => {
    if (err) return res.status(500).json({ error: err.message });
    res.json(rows);
  });
});
`;
  code = code.replace("app.listen(port", newRoute + "\napp.listen(port");
  fs.writeFileSync('index.js', code);
  console.log("Patched index.js");
}
