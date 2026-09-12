const sqlite3 = require('sqlite3').verbose();
const path = require('path');
const crypto = require('crypto');

// Change this to match your deployed database URL/token if running remotely
const dbPath = path.join(__dirname, 'database.sqlite');

const db = new sqlite3.Database(dbPath, (err) => {
    if (err) {
        console.error('Error connecting to the database:', err.message);
        process.exit(1);
    }
});

const adminEmail = 'admin@ves.ac.in';
const adminPassword = 'AdminTest123!';
const adminName = 'System Admin';

db.serialize(() => {
    // 1. Ensure the users table exists (it should, but just in case)
    db.run(`CREATE TABLE IF NOT EXISTS users (
        id TEXT PRIMARY KEY,
        name TEXT,
        email TEXT UNIQUE,
        password TEXT,
        role TEXT,
        deviceId TEXT,
        rollNo TEXT
    )`);

    // 2. Check if admin already exists
    db.get(`SELECT id FROM users WHERE email = ?`, [adminEmail], (err, row) => {
        if (err) {
            console.error('Error querying users:', err);
            return db.close();
        }

        if (row) {
            // Update password just in case
            db.run(`UPDATE users SET password = ?, role = 'admin' WHERE id = ?`, [adminPassword, row.id], (updateErr) => {
                if (updateErr) console.error('Error updating admin:', updateErr);
                else console.log('Admin account updated successfully!');
                db.close();
            });
        } else {
            // Insert new admin
            const id = crypto.randomUUID();
            db.run(
                `INSERT INTO users (id, name, email, password, role) VALUES (?, ?, ?, ?, ?)`,
                [id, adminName, adminEmail, adminPassword, 'admin'],
                (insertErr) => {
                    if (insertErr) console.error('Error inserting admin:', insertErr);
                    else console.log('Admin account created successfully!');
                    db.close();
                }
            );
        }
    });
});
