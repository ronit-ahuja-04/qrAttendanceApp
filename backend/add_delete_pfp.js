const fs = require('fs');
let code = fs.readFileSync('index.js', 'utf8');

const target = `app.post('/users/:id/profile-picture', upload.single('profilePicture'), async (req, res) => {`;

const newCode = `app.delete('/users/:id/profile-picture', async (req, res) => {
  const userId = req.params.id;
  db.run(\`UPDATE users SET profilePictureUrl = NULL WHERE id = ?\`, [userId], function (err) {
    if (err) return res.status(500).json({ error: err.message });
    res.json({ message: "Profile picture removed successfully", profilePictureUrl: null });
  });
});

app.post('/users/:id/profile-picture', upload.single('profilePicture'), async (req, res) => {`;

code = code.replace(target, newCode);
fs.writeFileSync('index.js', code);
console.log('Added DELETE /users/:id/profile-picture route');
