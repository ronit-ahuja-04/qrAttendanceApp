# BMAD Epics & User Stories: QA & Testing Assignments

This document outlines the testing assignments for the 9-person QA team.

> [!IMPORTANT]
> **Before starting your Epic**, please read the [Local QA Setup Guide](file:///Users/ronitahuja/Downloads/qrAttendanceApp/docs/Local_QA_Setup_Guide.md) to learn how to run the project locally and understand the limitations of Android Studio Emulators.

---

## EPIC 1: iOS Ecosystem End-to-End Validation
**Assigned to:** Ronit & Vanshika Wadhwani  
**Platform:** iOS Only (iPhone & iPad)

**Objective:** Apple iOS has strict background execution, camera permission, and push notification constraints. This Epic ensures the Flutter application runs flawlessly when compiled to an iOS `.ipa`.

**User Stories (Testing Tasks) & Test Cases:**
- [ ] **STORY-1.1:** Test camera permission denial and recovery on iOS 16+.
  - *Test Case 1:* Deny camera permission on first prompt; verify the app shows a user-friendly error with a button to open Settings.
  - *Test Case 2:* Grant permission from Settings and return; verify the camera initializes immediately without restarting the app.
- [ ] **STORY-1.2:** Test Firebase Cloud Messaging (FCM) push notifications when the app is in the background and fully killed on iOS.
  - *Test Case 1:* Send a notification while the app is in the background; verify it appears in the iOS Notification Center.
  - *Test Case 2:* Force kill the app and send a notification; verify it is received.
  - *Test Case 3:* Tap a notification from a killed state; verify it routes to the correct screen.
- [ ] **STORY-1.3:** Complete a full Student Attendance flow (Dashboard -> Camera -> Success Screen) on a physical iPhone to check for UI rendering issues (Notches, Dynamic Island overlaps).
  - *Test Case 1:* Verify header and footer UI elements do not overlap with the Dynamic Island or Home Indicator.
  - *Test Case 2:* Complete a successful scan and verify the success animation plays smoothly on iOS devices.
- [ ] **STORY-1.4:** Test the Faculty QR generation screen to ensure the dynamic 1-second refresh rate does not cause memory leaks or battery drain on iOS.
  - *Test Case 1:* Leave the QR generator open for 15 minutes; monitor memory usage in Xcode to ensure it remains stable.
  - *Test Case 2:* Verify the phone does not overheat and battery drain is within acceptable limits during prolonged display.

---

## EPIC 2: Heavy Logical Modules
**Assigned to:** Jai, Bhoomi, Vanshika Ahuja 
**Platform:** Android & Web

**Objective:** Test the most technically complex, mathematically demanding, and backend-coupled features of the application.

**User Stories (Testing Tasks) & Test Cases:**
- [ ] **STORY-2.1 (Dynamic QR):** Attempt to bypass the system by scanning a QR code photo that is 5 seconds old. Ensure the app strictly rejects it due to timestamp expiry.
  - *Test Case 1:* Scan a QR code within 1 second of generation; verify success.
  - *Test Case 2:* Take a photo of the QR code and scan it after 5 seconds; verify the app shows an "Expired QR Code" error.
- [ ] **STORY-2.2 (Timetable Engine):** As a faculty, create overlapping timetable slots. Ensure the backend (`/api/timetable`) throws a logical collision error.
  - *Test Case 1:* Create a slot for 10:00 AM - 11:00 AM. Attempt to create another slot for 10:30 AM - 11:30 AM for the same faculty/class; verify the API returns a 409 Conflict.
  - *Test Case 2:* Verify the UI elegantly displays the collision error message to the user.
- [ ] **STORY-2.3 (Proxy Approvals):** Send a proxy request to another faculty. Have the second faculty decline it. Verify the original faculty receives the declined notification and the session is NOT transferred.
  - *Test Case 1:* Faculty A requests a proxy from Faculty B. Faculty B declines. Faculty A receives a push notification of the decline.
  - *Test Case 2:* Verify the session remains assigned to Faculty A in the database and timetable.
- [ ] **STORY-2.4 (Attendance Finalization):** Start a session, have exactly 3 students scan, and end the session. Ensure the manual Verification screen shows exactly those 3 students. Finalize the list and verify the database locks the records.
  - *Test Case 1:* After 3 scans, end the session; verify the verification list shows exactly 3 students marked as 'Present'.
  - *Test Case 2:* Submit the final list; attempt to add a student afterward; verify the system rejects edits to a finalized session.

---

## EPIC 3: Mid-Level Features (Data & Reporting)
**Assigned to:** Manish, Sachin(2nd Year) 
**Platform:** Android & Web

**Objective:** Test data aggregation, UI visualizations of data, and file generation services.

**User Stories (Testing Tasks) & Test Cases:**
- [ ] **STORY-3.1 (Excel Generation):** Generate a bulk Excel report (`/api/report/bulk-excel`) for a full month. Open the `.xlsx` file and verify the columns (Name, Roll No, Present/Absent) align correctly.
  - *Test Case 1:* Generate a report for a batch with 50 students; verify the downloaded file opens without corruption.
  - *Test Case 2:* Verify total present/absent counts in the Excel sheet match the dashboard statistics.
- [ ] **STORY-3.2 (Session Calendar):** Navigate to the Session Calendar. Click on a historical date where a session occurred. Verify the correct batch details and absent list load.
  - *Test Case 1:* Select a date with multiple sessions; verify all sessions for that day are listed.
  - *Test Case 2:* Click a specific session; verify it correctly shows the absent students for that exact session.
- [ ] **STORY-3.3 (Student Stats):** Log in as a student. Verify the attendance percentage circle accurately reflects the ratio of attended sessions vs total sessions held for their enrolled batches.
  - *Test Case 1:* Student with 8/10 sessions attended; verify the UI shows exactly 80%.
  - *Test Case 2:* Verify the breakdown by subject matches the overall aggregation.
- [ ] **STORY-3.4 (Manual Verification UI):** During an active session, use the manual search bar to add a student who forgot their phone. Verify they are instantly appended to the present list.
  - *Test Case 1:* Search for a student by roll number; verify the autocomplete works.
  - *Test Case 2:* Manually add the student; verify they appear in the live present list and the total count increments by 1.

---

## EPIC 4: UI/UX and Account Modules
**Assigned to:** Hiten, Gaurang(3rd Year)  
**Platform:** Android & Web

**Objective:** Test the application's front door, profile management, and basic visual user experience. Ensure forms validate correctly and error messages are helpful.

**User Stories (Testing Tasks) & Test Cases:**
- [ ] **STORY-4.1 (Login & Validation):** Attempt to log in with missing fields, invalid email formats, and incorrect passwords. Verify red error text appears gracefully without crashing the app.
  - *Test Case 1:* Submit an empty form; verify "Required field" errors appear under email and password inputs.
  - *Test Case 2:* Submit `user@` as email; verify "Invalid email format" error appears.
  - *Test Case 3:* Submit correct email but wrong password; verify a friendly "Incorrect credentials" snackbar appears.
- [ ] **STORY-4.2 (Profile Pictures):** Upload a new profile picture. Ensure the image crops nicely into a circle on the dashboard and doesn't stretch. Try uploading a PDF instead of an image and verify it blocks the upload.
  - *Test Case 1:* Upload a 1080x1920 image; verify it is cropped to a 1:1 circle without distortion.
  - *Test Case 2:* Attempt to select a `.pdf` file in the file picker; verify the app restricts selection to `.jpg/.png` or shows a format error.
- [ ] **STORY-4.3 (Password Reset):** Use the "Forgot Password" flow. Wait for the email, click the link, and change the password. Log out and try logging in with the new password.
  - *Test Case 1:* Request reset for an unregistered email; verify it handles it securely (e.g., "If an account exists, an email was sent").
  - *Test Case 2:* Follow the reset link and change password; verify login with the old password fails and new password succeeds.
- [ ] **STORY-4.4 (Notification Center):** Open the notification bell icon. Ensure unread notifications have a distinct color (e.g., bolded or blue dot) compared to read ones. Click "Mark all as read" and verify the UI updates immediately.
  - *Test Case 1:* Receive a new notification; verify the bell icon shows a red badge counter.
  - *Test Case 2:* Click "Mark all as read"; verify the badge disappears and all list items change to read state without needing a page refresh.
