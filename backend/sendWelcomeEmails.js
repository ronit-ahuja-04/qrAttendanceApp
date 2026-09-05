require('dotenv').config();
const db = require('./database');
const axios = require('axios');

async function main() {
  if (!process.env.APPS_SCRIPT_URL) {
    console.error("❌ Missing APPS_SCRIPT_URL in your .env file!");
    console.error("Please add it to your local .env file before running this script.");
    process.exit(1);
  }

  db.all('SELECT id, role, name, rollNo, email FROM users', async (err, users) => {
    if (err) {
      console.error(err);
      process.exit(1);
    }

    console.log(`Found ${users.length} users. Starting email broadcast...\n`);

    for (const user of users) {
      // 1. Generate password based on role
      const firstName = user.name.split(' ')[0]; // Gets the first name
      let newPassword = '';
      
      if (user.role === 'student') {
        newPassword = `${firstName}@${user.rollNo}`;
      } else if (user.role === 'faculty' || user.role === 'admin') {
        newPassword = `Fac${firstName}@vesit`;
      } else {
        continue;
      }

      // 2. Update Password in Database
      await new Promise((resolve, reject) => {
        db.run('UPDATE users SET password = ? WHERE id = ?', [newPassword, user.id], (err) => {
          if (err) reject(err);
          else resolve();
        });
      });

      // 3. Send Email
      const htmlBody = `
        <div style="font-family:sans-serif;max-width:480px;margin:auto;border:1px solid #e0e0e0;border-radius:12px;overflow:hidden">
          <div style="background:#002147;padding:24px;text-align:center">
            <h2 style="color:#FFD700;margin:0;font-size:22px;letter-spacing:2px">Welcome to AMS</h2>
            <p style="color:#fff;margin:4px 0 0;font-size:13px">VESIT Attendance Management System</p>
          </div>
          <div style="padding:28px">
            <p style="font-size:15px;color:#333">Hi ${firstName},</p>
            <p style="font-size:15px;color:#333">Your account for the new Attendance Management System has been created.</p>
            <p style="font-size:15px;color:#333">You can log in using your college email and the default password below:</p>
            <div style="background:#f4f4f4;border-radius:10px;padding:20px;text-align:center;margin:24px 0">
              <span style="font-size:24px;font-weight:bold;letter-spacing:2px;color:#002147">${newPassword}</span>
            </div>
            <p style="font-size:13px;color:#888">Please log in and go to your profile to change your password as soon as possible.</p>
            <div style="text-align:center;margin-top:20px">
              <a href="https://qr-attendance-app.vercel.app" style="background:#002147;color:#fff;padding:12px 24px;text-decoration:none;border-radius:6px;font-weight:bold;display:inline-block;">Go to App</a>
            </div>
          </div>
        </div>
      `;

      try {
        const response = await axios.post(process.env.APPS_SCRIPT_URL, {
          to: user.email,
          subject: 'Welcome to VESIT AMS - Your Login Details',
          html: htmlBody
        });
        
        if (response.data.status === 'success') {
          console.log(`✅ Sent to ${user.email} (Password: ${newPassword})`);
        } else {
          console.error(`❌ Failed for ${user.email}:`, response.data.message);
        }
      } catch (e) {
         console.error(`❌ Crash for ${user.email}:`, e.message);
      }
      
      // Wait 1 second between emails to prevent Google from blocking us for spamming too fast
      await new Promise(r => setTimeout(r, 1000));
    }
    
    console.log("\n🎉 Finished sending all welcome emails!");
    process.exit(0);
  });
}

main();
