import re

filepath = 'attendance.test.js'
with open(filepath, 'r') as f:
    content = f.read()

# Insert token generation inside beforeAll
insert_tokens = """
  // Generate mock tokens
  studentToken = generateToken({ id: 'stud1', role: 'student', email: 'stud1@test.com' });
  otherStudentToken = generateToken({ id: 'stud2', role: 'student', email: 'stud2@test.com' });
"""
content = content.replace("await seedTestDb();", "await seedTestDb();" + insert_tokens)

# Add .set('Authorization', `Bearer ${studentToken}`) before .send
content = re.sub(r"\.post\('/api/attendance/mark'\)\s*\.send", ".post('/api/attendance/mark')\n      .set('Authorization', `Bearer ${studentToken}`)\n      .send", content)

# Remove studentId from payloads
content = re.sub(r"studentId:\s*'stud1',\s*", "", content)
content = re.sub(r"studentId:\s*'stud2',\s*", "", content)

with open(filepath, 'w') as f:
    f.write(content)
