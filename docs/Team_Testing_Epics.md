# BMAD Epics & User Stories: QA & Testing Assignments

This document outlines the testing assignments for the 9-person QA team.

> [!IMPORTANT]
> **Before starting your Epic**, please read the [Local QA Setup Guide](file:///Users/ronitahuja/Downloads/qrAttendanceApp/docs/Local_QA_Setup_Guide.md) to learn how to run the project locally and understand the limitations of Android Studio Emulators.

---

## EPIC 1: iOS Ecosystem End-to-End Validation
**Assigned to:** Ronit & Vanshika Wadhwani  
**Platform:** iOS Only (iPhone & iPad)

**Objective:** Apple iOS has strict background execution, camera permission, and push notification constraints. This Epic ensures the Flutter application runs flawlessly when compiled to an iOS `.ipa`.

**User Stories (Testing Tasks):**
- [ ] **STORY-1.1:** Test camera permission denial and recovery on iOS 16+.
- [ ] **STORY-1.2:** Test Firebase Cloud Messaging (FCM) push notifications when the app is in the background and fully killed on iOS.
- [ ] **STORY-1.3:** Complete a full Student Attendance flow (Dashboard -> Camera -> Success Screen) on a physical iPhone to check for UI rendering issues (Notches, Dynamic Island overlaps).
- [ ] **STORY-1.4:** Test the Faculty QR generation screen to ensure the dynamic 1-second refresh rate does not cause memory leaks or battery drain on iOS.

---

## EPIC 2: Heavy Logical Modules (Core System)
**Assigned to:** Jai, Bhoomi, Vanshika Ahuja 
**Platform:** Android & Web

**Objective:** Test the most technically complex, mathematically demanding, and backend-coupled features of the application.

**User Stories (Testing Tasks):**
- [ ] **STORY-2.1 (Dynamic QR):** Attempt to bypass the system by scanning a QR code photo that is 5 seconds old. Ensure the app strictly rejects it due to timestamp expiry.
- [ ] **STORY-2.2 (Timetable Engine):** As a faculty, create overlapping timetable slots. Ensure the backend (`/api/timetable`) throws a logical collision error.
- [ ] **STORY-2.3 (Proxy Approvals):** Send a proxy request to another faculty. Have the second faculty decline it. Verify the original faculty receives the declined notification and the session is NOT transferred.
- [ ] **STORY-2.4 (Attendance Finalization):** Start a session, have exactly 3 students scan, and end the session. Ensure the manual Verification screen shows exactly those 3 students. Finalize the list and verify the database locks the records.

---

## EPIC 3: Mid-Level Features (Data & Reporting)
**Assigned to:** Hiten, Gaurang(3rd Year) 
**Platform:** Android & Web

**Objective:** Test data aggregation, UI visualizations of data, and file generation services.

**User Stories (Testing Tasks):**
- [ ] **STORY-3.1 (Excel Generation):** Generate a bulk Excel report (`/api/report/bulk-excel`) for a full month. Open the `.xlsx` file and verify the columns (Name, Roll No, Present/Absent) align correctly.
- [ ] **STORY-3.2 (Session Calendar):** Navigate to the Session Calendar. Click on a historical date where a session occurred. Verify the correct batch details and absent list load.
- [ ] **STORY-3.3 (Student Stats):** Log in as a student. Verify the attendance percentage circle accurately reflects the ratio of attended sessions vs total sessions held for their enrolled batches.
- [ ] **STORY-3.4 (Manual Verification UI):** During an active session, use the manual search bar to add a student who forgot their phone. Verify they are instantly appended to the present list.

---

## EPIC 4: UI/UX and Account Modules
**Assigned to:** Manish, Sachin(2nd Year)  
**Platform:** Android & Web

**Objective:** Test the application's front door, profile management, and basic visual user experience. Ensure forms validate correctly and error messages are helpful.

**User Stories (Testing Tasks):**
- [ ] **STORY-4.1 (Login & Validation):** Attempt to log in with missing fields, invalid email formats, and incorrect passwords. Verify red error text appears gracefully without crashing the app.
- [ ] **STORY-4.2 (Profile Pictures):** Upload a new profile picture. Ensure the image crops nicely into a circle on the dashboard and doesn't stretch. Try uploading a PDF instead of an image and verify it blocks the upload.
- [ ] **STORY-4.3 (Password Reset):** Use the "Forgot Password" flow. Wait for the email, click the link, and change the password. Log out and try logging in with the new password.
- [ ] **STORY-4.4 (Notification Center):** Open the notification bell icon. Ensure unread notifications have a distinct color (e.g., bolded or blue dot) compared to read ones. Click "Mark all as read" and verify the UI updates immediately.
