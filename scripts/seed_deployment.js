const sqlite3 = require('sqlite3').verbose();
const fs = require('fs');
const path = require('path');
const crypto = require('crypto');

const dbPath = path.join(__dirname, 'database.sqlite');
const db = new sqlite3.Database(dbPath);

const canvasDataStr = fs.readFileSync(path.join(__dirname, 'd15a_canvas.json'), 'utf-8');
const canvasJson = JSON.parse(canvasDataStr);

function parseCanvasTimetable(json) {
    const pages = json.pages[0];
    const elements = pages.children.filter(c => c.type === 'text');
    
    // Extract times
    const timeElements = elements.filter(e => e.text.includes('AM TO') || e.text.includes('PM TO') || e.text.includes('AM  TO') || e.text.includes('PM  TO'));
    const times = timeElements.map(e => {
        const parts = e.text.replace(/  /g, ' ').split(' TO ');
        return {
            y: e.y,
            startTime: parseTime(parts[0]),
            endTime: parseTime(parts[1])
        };
    }).sort((a, b) => a.y - b.y);

    // Extract days
    const dayNames = ['MONDAY', 'TUESDAY', 'WEDNESDAY', 'THRUSDAY', 'THURSDAY', 'FRIDAY'];
    const dayElements = elements.filter(e => dayNames.includes(e.text.toUpperCase()));
    const days = dayElements.map(e => ({
        x: e.x,
        day: e.text.toUpperCase() === 'THRUSDAY' ? 'Thursday' : e.text.charAt(0).toUpperCase() + e.text.slice(1).toLowerCase()
    })).sort((a, b) => a.x - b.x);

    // Extract subjects
    const slotElements = elements.filter(e => {
        return !timeElements.includes(e) && !dayElements.includes(e) && 
               !e.text.includes('VIVEKANAND') && !e.text.includes('INFORMATION TECHNOLOGY') &&
               !e.text.includes('CLASS TIME TABLE') && !e.text.includes('CLASS:D15A') &&
               !e.text.includes('TIME/DAY') && !e.text.includes('BREAK') &&
               !e.text.includes('CLASS TEACHER') && !e.text.includes('CLASS COUNSELLOR') &&
               !e.text.includes('Pooja N') && !e.text.includes('Manoj S');
    });

    const slots = [];
    
    for (const slot of slotElements) {
        // Find matching day
        let matchedDay = days[0];
        let minDx = Math.abs(slot.x - days[0].x);
        for (const d of days) {
            const dx = Math.abs(slot.x - d.x);
            if (dx < minDx) {
                minDx = dx;
                matchedDay = d;
            }
        }
        
        // Find matching time
        let matchedTime = times[0];
        let minDy = Math.abs(slot.y - times[0].y);
        for (const t of times) {
            // Adjust for practicals spanning multiple slots based on height
            const dy = Math.abs(slot.y - t.y);
            if (dy < minDy) {
                minDy = dy;
                matchedTime = t;
            }
        }

        let endTime = matchedTime.endTime;
        if (slot.height > 30) {
            // Likely a 2-hour practical slot
            const currentIndex = times.indexOf(matchedTime);
            if (currentIndex + 1 < times.length && times[currentIndex+1].startTime === matchedTime.endTime) {
                endTime = times[currentIndex+1].endTime;
            }
        }

        const rawText = slot.text.replace(/<[^>]*>?/gm, '').trim(); // Remove HTML tags like <span>
        const lines = rawText.split('\n').filter(l => l.trim().length > 0);
        
        for (const line of lines) {
            let subject = line;
            let batchTarget = 'All';
            let type = 'Lec';
            let venue = 'Room';
            let facultyId = 'fac-auto';

            // Heuristics for subject parsing
            if (line.includes('/')) {
                // e.g. FS/510/C/PS
                const parts = line.split('/');
                subject = parts[0];
                venue = parts[1] || venue;
                batchTarget = 'D15A-' + (parts[2] || 'All');
                type = 'Prac';
            } else if (line.includes('(')) {
                // e.g. DMBI(DK) B51
                type = 'Lec';
                const match = line.match(/([A-Z]+)\(([^)]+)\)\s*(.*)/);
                if (match) {
                    subject = match[1];
                    venue = match[3] || venue;
                }
                batchTarget = 'D15A-All';
            }

            slots.push({
                id: crypto.randomUUID(),
                facultyId,
                day: matchedDay.day,
                subject,
                type,
                batchTarget,
                venue,
                startTime: matchedTime.startTime,
                endTime: endTime
            });
        }
    }
    
    return slots;
}

function parseTime(tStr) {
    tStr = tStr.trim().toUpperCase();
    const match = tStr.match(/(\d+):?(\d+)?\s*(AM|PM)/);
    if (!match) return tStr;
    let h = parseInt(match[1]);
    let m = match[2] || '00';
    const ampm = match[3];
    if (ampm === 'PM' && h < 12) h += 12;
    if (ampm === 'AM' && h === 12) h = 0;
    return `${h.toString().padStart(2, '0')}:${m}`;
}

async function run() {
    console.log("Starting deployment chores...");

    // 1. Reset History
    await new Promise((res, rej) => db.run('DELETE FROM sessions', err => err ? rej(err) : res()));
    await new Promise((res, rej) => db.run('DELETE FROM attendance_records', err => err ? rej(err) : res()));
    console.log("Cleared sessions and attendance_records.");

    // 2. Reset Counters (Columns don't exist in schema, so skipping)
    // await new Promise((res, rej) => db.run('UPDATE users SET totalLecturesAttended = 0, totalLecturesConducted = 0', err => err ? rej(err) : res()));
    // console.log("Reset attendance counters to 0.");

    // 3. Reset Profile Pictures
    await new Promise((res, rej) => db.run('UPDATE users SET profilePictureUrl = NULL', err => err ? rej(err) : res()));
    console.log("Reset profile pictures.");

    // 4. Reset Passwords
    const users = await new Promise((res, rej) => db.all('SELECT id, role, name, rollNo FROM users', (err, rows) => err ? rej(err) : res(rows)));
    
    let updatedCount = 0;
    for (const u of users) {
        if (!u.name) continue;
        
        // Parse SURNAME FIRSTNAME ...
        const parts = u.name.split(' ').filter(p => p.length > 0);
        let first = parts.length > 1 ? parts[1] : parts[0];
        let last = parts.length > 1 ? parts[0] : '';
        
        // Convert to PascalCase
        first = first.charAt(0).toUpperCase() + first.slice(1).toLowerCase();
        last = last ? (last.charAt(0).toUpperCase() + last.slice(1).toLowerCase()) : '';
        
        const roll = u.rollNo ? String(u.rollNo).trim() : '00';
        
        let newPassword = '';
        if (u.role === 'student') {
            newPassword = `${first}${last}@${roll}`;
        } else {
            newPassword = `${first}${last}@Vesit`;
        }

        await new Promise((res, rej) => db.run('UPDATE users SET password = ? WHERE id = ?', [newPassword, u.id], err => err ? rej(err) : res()));
        updatedCount++;
    }
    console.log(`Reset passwords for ${updatedCount} users.`);

    // 5. Timetable Seeding
    await new Promise((res, rej) => db.run('DELETE FROM timetable_slots', err => err ? rej(err) : res()));
    
    try {
        const newSlots = parseCanvasTimetable(canvasJson);
        console.log(`Parsed ${newSlots.length} timetable slots for D15A.`);
        
        const stmt = db.prepare('INSERT INTO timetable_slots (id, facultyId, day, subject, type, batchTarget, venue, startTime, endTime) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)');
        for (const s of newSlots) {
            await new Promise((res, rej) => stmt.run([s.id, s.facultyId, s.day, s.subject, s.type, s.batchTarget, s.venue, s.startTime, s.endTime], err => err ? rej(err) : res()));
        }
        stmt.finalize();
        console.log("Inserted new timetable slots.");
    } catch (e) {
        console.error("Error parsing/inserting timetable:", e);
    }

    console.log("Deployment chores completed successfully.");
}

run().catch(console.error);
