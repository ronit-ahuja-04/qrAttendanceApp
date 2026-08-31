const fs = require('fs');
let code = fs.readFileSync('index.js', 'utf8');

const targetReplacement = `  if (target.includes('Batch A')) whereClause += " AND coreBatch = 'Batch A'";
  if (target.includes('Batch B')) whereClause += " AND coreBatch = 'Batch B'";
  if (target.includes('Batch C')) whereClause += " AND coreBatch = 'Batch C'";

  const course = (courseCode || '').toLowerCase();
  if (target.includes('ADMT') || course.includes('database') || course.includes('admt')) {
    whereClause += " AND electiveSubject = 'ADMT'";
    // HARDCODED FACULTY SEPARATION FOR ADMT
    if (facultyId === 'fac-cn') {
      whereClause += " AND division = 'D15A'";
    } else if (facultyId === 'fac-vp') {
      whereClause += " AND division IN ('D15B', 'D15C')";
    }
  } else if (target.includes('Soft') || course.includes('soft')) {
    whereClause += " AND electiveSubject = 'Soft Computing'";
  }`;

code = code.replace(
  /if \(target\.includes\('Batch A'\)\)[\s\S]*?whereClause \+= " AND electiveSubject = 'Soft Computing'";\n  \}/,
  targetReplacement
);

fs.writeFileSync('index.js', code);
console.log("Patched faculty separation!");
