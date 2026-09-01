# Low-Level Technical Specification

## 1. Directory Structure & App Screens
The mobile application contains ~32 screens divided by domain.

### 1.1 Faculty Flows
- `faculty_dashboard_screen.dart`: Main entry showing active batches and quick actions.
- `faculty_timetable_manager_screen.dart`: Interface for CRUD operations on `/api/timetable`.
- `faculty_attendance_qr_generator_screen.dart`: Houses the `Timer.periodic` running at 1-second intervals to redraw the QR widget.
- `proxy_approvals_screen.dart`: Fetches and updates `ProxyRequests` table.
- `faculty_session_history_screen.dart`: Fetches past sessions for the calendar view.
- `verify_attendance_screen.dart`: Provides search/autocomplete for manual student additions and finalizing the session payload.
- `generate_report_screen.dart`: Calls `/api/report/bulk-excel` and handles the file download stream.

### 1.2 Student Flows
- `student_dashboard_screen.dart`: Fetches aggregate stats (attendance %) and recent sessions.
- `qr_scanner_screen.dart`: Invokes the native camera controller. Decodes standard string payloads.
- `student_timetable_screen.dart`: Read-only view of `/api/timetable` filtered by enrolled batches.
- `student_attendance_success_screen.dart`, `student_already_marked_screen.dart`, `student_not_enrolled_screen.dart`: Terminal states based on API response codes (200, 409, 403 respectively).

### 1.3 Shared UI
- `login_screen.dart`, `registration_screen.dart`: Handles JWT exchange and initial routing.
- `faculty_profile_screen.dart`, `student_profile_screen.dart`: Uses multipart/form-data for `/api/profile/upload` via Multer.
- `forgot_password_screen.dart`, `change_password_screen.dart`: Triggers Nodemailer sequences.
- `notifications_screen.dart`: Polls or listens to a websocket/FCM datastore for read/unread state.

## 2. API Contract Guidelines

### 2.1 Dynamic QR Cryptography & Validation
- **Payload Format:** `<FacultyID>|<SessionID>|<Timestamp_MS>|<HMAC_Signature>`
- **Server Validation:**
  ```javascript
  const age = Date.now() - parseInt(payload.Timestamp_MS);
  if (age > 5000) return res.status(400).json({ error: "QR Expired" });
  if (!verifySignature(payload)) return res.status(401).json({ error: "Invalid Signature" });
  ```

### 2.2 Timetable Collision Logic
- Before inserting a new timetable slot, the server queries SQLite for any existing slot where:
  - `faculty_id = ? OR batch_id = ?`
  - AND `((new_start >= start AND new_start < end) OR (new_end > start AND new_end <= end))`
- Returns HTTP 409 Conflict if matched.

### 2.3 Attendance Finalization
- **Endpoint:** `POST /api/sessions/:id/finalize`
- **Logic:** 
  1. Retrieve all students enrolled in the batch linked to `:id`.
  2. Find the delta between enrolled students and `AttendanceRecords` for this session.
  3. Bulk insert `Absent` records for the delta.
  4. Update `Sessions` row to `locked = true`.

## 3. iOS Specific Constraints
- **Camera:** `Info.plist` must contain `NSCameraUsageDescription`. Re-prompt logic must direct users to iOS Settings if denied.
- **Background Execution:** QR Generation timer must be paused in `didEnterBackground` and resumed in `willEnterForeground` to prevent iOS from suspending the app and killing the socket/timer.
- **FCM:** Requires APNs certificates uploaded to Firebase Console. Payload must include `content-available: 1` for background processing.
