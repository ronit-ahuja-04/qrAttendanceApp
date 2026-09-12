const fs = require('fs');
let code = fs.readFileSync('index.js', 'utf8');

// Remove the new endpoints at the end
const marker = "// GET student attendance stats";
const endIndex = code.indexOf(marker);
if (endIndex !== -1) {
    code = code.substring(0, endIndex) + "app.listen(3000, '0.0.0.0', () => {\n  console.log('Backend listening on port 3000 (0.0.0.0)');\n});\n";
}

// Re-insert the dummy endpoint
const dummyEndpoint = `
app.get('/students/:id/stats', (req, res) => {
  res.json({
    overallPercentage: 89.0,
    thisWeekPercentage: 92.0,
    subjects: [
      { courseCode: 'CS-302', overallPercentage: 92.0, thisWeekPercentage: 100.0 },
      { courseCode: 'CS-201', overallPercentage: 70.0, thisWeekPercentage: 50.0 },
      { courseCode: 'CS-305', overallPercentage: 88.0, thisWeekPercentage: 100.0 },
    ]
  });
});
`;

// Insert after the GET /api/attendance/session/:id endpoint
const insertAfterStr = "    res.json(rows);\n  });\n});";
const insertPos = code.indexOf(insertAfterStr);
if (insertPos !== -1) {
    code = code.substring(0, insertPos + insertAfterStr.length) + "\n" + dummyEndpoint + code.substring(insertPos + insertAfterStr.length);
}

fs.writeFileSync('index.js', code);
console.log("Backend reverted.");
