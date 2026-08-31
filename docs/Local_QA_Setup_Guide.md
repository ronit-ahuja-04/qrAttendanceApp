# Local QA Setup & Runnability Guide

This guide is for all QA team members. Before you start executing your testing Epics, you must set up the project locally on your machine.

---

## 1. Git Setup (Getting the Code)
1. **Clone the repository:**
   ```bash
   git clone https://github.com/your-org/qrAttendanceApp.git
   cd qrAttendanceApp
   ```
2. **Branching Strategy:**
   - **Never test directly on `main`** unless you are running a final regression test.
   - Always pull the latest changes from the `develop` or `qa-testing` branch:
     ```bash
     git checkout develop
     git pull origin develop
     ```

---

## 2. Backend Setup (Node.js)
The Flutter mobile app needs the backend server running locally to function.

1. **Install Dependencies:**
   Open a terminal in the project root:
   ```bash
   cd backend
   npm install
   ```
2. **🚨 Secure the Firebase Credentials 🚨**
   The backend relies on Google Cloud Firebase Cloud Messaging (FCM) to send Push Notifications. For security reasons, the credentials file is **not** on GitHub.
   *   **Action:** Contact the project lead (Ronit) to receive the `firebase-service-account.json` file via a secure channel (Slack/Password Manager).
   *   **Placement:** Place the downloaded file directly inside the `backend/` folder on your local machine.

3. **Start the Server:**
   ```bash
   node index.js
   ```
   *Note: Ensure the backend is running on `http://localhost:3000` before opening the Flutter app.*

---

## 3. Flutter & Android Studio Setup
1. **Install Android Studio & Flutter:** Ensure you have the Flutter SDK installed and the Flutter plugin added to Android Studio.
2. **Open the Project:** Open Android Studio -> "Open" -> Select the `app/` folder inside `qrAttendanceApp`.
3. **Fetch Packages:**
   ```bash
   flutter pub get
   ```

---

## 4. 🚨 CRITICAL CAVEAT: Emulators vs. Physical Devices 🚨

### The QR Scanner Limitation
**Android Studio Emulators CANNOT scan QR codes natively.** The virtual camera on emulators does not have the fidelity or the software pipeline to rapidly process the 1-second Dynamic QR codes.

**If your Epic requires scanning a QR code (Epic 1 & Epic 2):**
*   **You MUST use a physical device.** 
*   **Android Users:** Enable "Developer Options" and "USB Debugging" on your phone. Plug it into your laptop via USB. In Android Studio, select your physical phone from the device dropdown and click "Run".
*   **iOS Users (Ronit & Vanshika W):** Plug your iPhone into your Mac. Open `app/ios/Runner.xcworkspace` in Xcode. Select your physical iPhone and hit "Run". Ensure you have trusted your developer certificate in iOS Settings.

### What CAN be tested on Emulators?
If you are testing **Epic 3** (Reports, Excel, Stats) or **Epic 4** (UI/UX, Logins, Profile Pics), you **can** use the Android Studio Emulator or iOS Simulator, as these features do not require the physical camera hardware.

---

## 5. Troubleshooting Local Runs
*   **"Connection Refused" / App won't log in:** Your Flutter app is trying to hit `localhost`, but an Android physical device or emulator cannot reach your laptop's `localhost` directly. 
    *   *Fix:* Change the API Base URL in the Flutter code (e.g., in `globals.dart` or `api_services.dart`) to your laptop's local IP address (e.g., `192.168.1.5`).
*   **iOS Build Failures:** (For Epic 1) Ensure you have run `cd ios && pod install` before building the app.
