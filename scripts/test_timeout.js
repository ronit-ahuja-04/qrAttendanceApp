const express = require('express');
const app = express();
app.get('/test', (req, res) => {
  setTimeout(() => {
    console.log("Background task finished");
  }, 1000);
  res.json({ success: true });
});
app.listen(3001, () => {
  console.log("Server running");
  const start = Date.now();
  require('http').get('http://localhost:3001/test', (res) => {
    let data = '';
    res.on('data', d => data += d);
    res.on('end', () => {
      console.log("Response time:", Date.now() - start, "ms", "Data:", data);
      process.exit(0);
    });
  });
});
