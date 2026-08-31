# High-Definition Master Application Guide

Welcome to the QR Attendance Application Master Guide. This document is written in **plain English** for the entire team (QA, Developers, and Management) to understand exactly what this application does, how it works under the hood, and what every screen and button is supposed to do.

## What is this App?
This is a full-fledged Enterprise Attendance & University Management system. 
It has two main users: **Faculty (Teachers)** and **Students**. 

Instead of teachers calling out roll numbers, the app generates a highly secure, rapidly-changing QR code on the teacher's screen. Students scan this QR code with their phones, and their attendance is instantly registered.

---

## Part 1: Core Technologies (How it works behind the scenes)

### 1. The "Dynamic" QR Code
Most QR codes are static (like a restaurant menu). If we used a static QR code, a student could take a photo of it and send it to their friends at home, who could scan it and fake their attendance.

To prevent this, our QR code is **Dynamic**. 
- It changes every single second.
- It contains a secret timestamp and a one-time password (OTP).
- When a student scans it, their phone checks if the QR code was generated in the last few seconds. If it's too old (e.g., it was a photo sent over WhatsApp), the app rejects it.

### 2. Push Notifications (FCM)
We use Google Firebase Cloud Messaging (FCM) to send invisible alerts to phones. 
For example, when a teacher clicks "Start Attendance", FCM instantly wakes up the students' phones so they know a session has begun.

### 3. The Backend Database
Our backend uses Node.js and SQLite. It handles almost 40 different types of requests (API endpoints) from the mobile app, ranging from saving a profile picture to generating a complex Excel sheet of attendance records.

---

## Part 2: Feature Breakdown (The 4 Main Pillars)

### Pillar A: Heavy Logic (The Hard Stuff)
*These are the most mathematically and technically complex parts of the app.*

*   **Smart Seminars & Bulk Sessions:** Sometimes, multiple classes combine for a big seminar. The app can merge multiple class batches (e.g., Computer Science Section A and Section B) into one giant QR session.
*   **Proxy Approvals (Substitute Teachers):** If a teacher is sick, they can use the app to request a substitute (Proxy). The substitute receives a notification, and they can tap "Approve" or "Decline". If approved, the substitute can start the attendance session on behalf of the sick teacher.
*   **The Timetable Engine:** The app contains a full scheduling engine. Teachers can create, read, update, and delete (CRUD) their class timings. Students can view their daily timetable which tells them exactly which class to go to next.
*   **Attendance Finalization:** After a scanning session is over, the teacher gets a list of everyone who scanned. The teacher must manually review this list and click "Finalize" to officially lock the attendance into the database.

### Pillar B: Data, Timelines, & Reporting (Mid-Level)
*This is where we turn raw data into useful information for the users.*

*   **Bulk Excel Reports:** At the end of the month, a teacher or HOD can click a button to download a massive Excel spreadsheet containing the attendance records of hundreds of students.
*   **Session Calendar:** A visual calendar where teachers can see all past sessions. Clicking on a date shows exactly who was present and absent on that specific day.
*   **Student Statistics:** Students have a dashboard showing a pie chart (or timeline) of their attendance percentage. It warns them if they are falling below the required 75% threshold.
*   **Manual Verification:** Sometimes a student's phone dies, and they can't scan. The teacher has a specific screen where they can manually type in a student's name and verify them.

### Pillar C: UI/UX and User Accounts (Basic Flows)
*This is the face of the application—the menus, buttons, and user profiles.*

*   **Login & Registration:** The front door of the app. It handles errors gracefully (e.g., typing the wrong password).
*   **Profile Pictures & Account Management:** Users can upload profile photos (handled via a system called `multer` on the backend). They can also update their names and contact info.
*   **Password Security:** The "Forgot Password" flow sends an email (via Nodemailer) with a reset link. Users can also change their passwords inside the app settings.
*   **Notification Center:** A UI screen (like Facebook's bell icon) where users can see a history of all notifications they received (e.g., "Your attendance was marked successfully").

### Pillar D: Platform Nuances (iOS vs Android)
*   **Android/Web:** Standard material design. Uses standard camera permissions.
*   **iOS (iPhones/iPads):** Apple has very strict rules. The iOS app must ask for Camera permissions gracefully, handle FaceID/TouchID if needed, and process Apple's specific Push Notification service seamlessly.

---

## Part 3: The 32 UI Screens (Quick Map)

**Faculty Screens (Teachers):**
1. Dashboard (`faculty_dashboard_screen.dart`)
2. Timetable Manager (`faculty_timetable_manager_screen.dart`)
3. QR Generator (`faculty_attendance_qr_generator_screen.dart`)
4. Proxy Approvals (`proxy_approvals_screen.dart`)
5. Session History (`faculty_session_history_screen.dart`)
6. Manual Verification (`verify_attendance_screen.dart`)
7. Generate Excel Report (`generate_report_screen.dart`)

**Student Screens:**
8. Dashboard (`student_dashboard_screen.dart`)
9. QR Scanner (`qr_scanner_screen.dart`)
10. Timetable (`student_timetable_screen.dart`)
11. Success Screen (`student_attendance_success_screen.dart`)
12. Already Marked Error (`student_already_marked_screen.dart`)
13. Not Enrolled Error (`student_not_enrolled_screen.dart`)

**Shared Screens (Both):**
14. Login / Register (`login_screen.dart`, `registration_screen.dart`)
15. Profile & Settings (`faculty_profile_screen.dart`, `student_profile_screen.dart`)
16. Forgot / Change Password (`forgot_password_screen.dart`, `change_password_screen.dart`)
17. Notifications Center (`notifications_screen.dart`)

*(Note: There are 15 more utility/layout screens not listed here for brevity, but they support the flows above).*
