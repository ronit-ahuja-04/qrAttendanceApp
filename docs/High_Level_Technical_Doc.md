# High-Level Technical Architecture

## 1. System Overview
The QR Attendance App is a distributed client-server architecture consisting of cross-platform mobile clients for Android and iOS (and potentially Web), backed by a centralized Node.js API server and an SQLite relational database. 

## 2. Core Components

### 2.1 Mobile Application (Frontend)
- **Framework:** Flutter (Dart) allowing a single codebase to compile natively for Android and iOS.
- **Key Modules:** 
  - **Dynamic QR Generator:** Refreshes a UI widget every 1 second containing an encrypted payload.
  - **QR Scanner:** Integrates native camera access to rapidly decode payloads.
  - **FCM Listener:** A background service listening for push notifications to alert students/faculty.

### 2.2 API Server (Backend)
- **Runtime:** Node.js (Express.js or similar framework).
- **Responsibilities:** 
  - Exposes ~40 RESTful API endpoints for client consumption.
  - Handles authentication and session management.
  - Validates dynamic QR payloads by checking the decrypted timestamp against the server's clock (ensuring the code is not older than 5 seconds).
  - Handles complex business logic (timetable collision detection, proxy routing, merging seminar batches).
  - Facilitates bulk Excel file generation using server-side rendering/buffering.

### 2.3 Database Layer
- **Engine:** SQLite (Relational DB).
- **Core Entities:**
  - `Users` (Faculty, Students, Admins)
  - `Batches/Classes`
  - `Timetables` (Schedules linked to Faculty and Batches)
  - `Sessions` (An active instance of attendance taking)
  - `AttendanceRecords` (Individual student scans linked to a Session)
  - `ProxyRequests` (Tracking substitute approvals)

### 2.4 Third-Party Integrations
- **Firebase Cloud Messaging (FCM):** For robust, platform-native push notifications across iOS (APNs) and Android.
- **Email Provider (Nodemailer):** For transactional emails like Password Reset links.
- **Local File System (Multer):** For handling multipart form data, specifically profile picture uploads, securely storing and serving them statically.

## 3. High-Level Data Flow (The Scan Process)
1. **Initiation:** Faculty selects a batch and initiates a session. Backend creates a `Session` record and pings FCM to wake up student apps.
2. **Generation:** Faculty app generates QR codes (encrypted OTP + Timestamp) at 1Hz.
3. **Scan:** Student app scans code, decrypts locally (or sends raw payload to server), and fires an API request.
4. **Validation:** Backend verifies the student's enrollment, checks the timestamp (Must be < 5 seconds old), and ensures no duplicate scans.
5. **Persistence:** Backend writes to `AttendanceRecords` and returns a 200 OK. Student app shows a Success Screen.
6. **Finalization:** Faculty reviews the list and locks the session, marking any unscanned students as absent.
