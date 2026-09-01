# Project Initiation Document & Business Use Case

## 1. Project Title
QR Attendance Application (Enterprise Attendance & University Management System)

## 2. Business Use Case (The Problem)
Traditional university and enterprise attendance taking is time-consuming, prone to errors, and highly susceptible to proxy attendance (where students fake attendance for others). Teachers waste valuable teaching time calling out roll numbers, and manual record-keeping makes it difficult to aggregate data or track student attendance percentages accurately in real time. 

## 3. The Solution
A full-fledged attendance and management system featuring a dynamic, rapidly-changing QR code. 
- Teachers generate a secure, 1-second refreshing QR code on their device. 
- Students scan this code with their smartphones to instantly register attendance.
- The dynamic nature (which includes an encrypted timestamp and OTP) prevents proxy attendance by ensuring photos of the QR code sent over WhatsApp or similar platforms are immediately rejected as expired.

## 4. Key Stakeholders
- **Faculty (Teachers):** Need an easy way to start sessions, manage timetables, handle proxy (substitute) teachers, manually verify students without phones, and generate bulk Excel reports.
- **Students:** Need to scan QR codes for attendance, check their timetables, and monitor their attendance percentages to stay above minimum thresholds (e.g., 75%).
- **Management / Administrators:** Need accurate, instantly available, unforgeable data in bulk Excel formats to track overall university or enterprise compliance.

## 5. High-Level Requirements (Scope)
- **Authentication & Profiles:** Secure login, registration, password resets via email, and profile picture management.
- **Dynamic QR Engine:** A core module generating QR codes that refresh every 1 second, rejecting scans older than a few seconds.
- **Timetable Engine:** A CRUD scheduling system for class timings and smart seminars (merging multiple batches).
- **Session Finalization & Verification:** Manual verification by teachers and permanent locking of attendance records post-session.
- **Proxy Management:** Ability for a teacher to request a substitute, with push notification approval flows.
- **Reporting & Notifications:** Push notifications (via FCM) to alert students of sessions, bulk `.xlsx` report generation, and session calendar history.

## 6. Success Metrics
- **Time Saved:** Reduction in time spent taking attendance per class (target: < 2 minutes).
- **Proxy Reduction:** Significant drop in fake attendance due to the dynamic 1-second timeout.
- **User Adoption:** High daily active usage among both faculty and enrolled students.
- **System Stability:** Flawless operation of the iOS/Android apps and backend during peak load times (e.g., beginning of classes).
