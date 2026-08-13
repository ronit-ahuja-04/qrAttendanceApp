# qrAttendanceApp Prototype

A modern, pitch-ready prototype for a highly secure, frictionless attendance system. qrAttendanceApp leverages a dynamically rotating QR payload synced to a local timestamp to prevent credential sharing and cheating.

This repository unifies the **Flutter Application** (Faculty and Student interfaces) and the **Node.js/Express Backend** into a single cohesive structure.

---

## 📁 Repository Structure
*Absolute Path:* `/Users/ronitahuja/Downloads/qrAttendanceApp`

- `/Users/ronitahuja/Downloads/qrAttendanceApp/app/`: The Flutter frontend (Android, iOS, Web, Desktop).
- `/Users/ronitahuja/Downloads/qrAttendanceApp/server/`: The Node.js/Express backend (SQLite, TypeScript).

---

## 🚀 Quick Start

### 1. Start the Backend (`server/`)

The backend is completely self-contained with an in-memory SQLite database, making it perfect for rapid prototyping and demonstrations.

```bash
cd /Users/ronitahuja/Downloads/qrAttendanceApp/server
npm install
npm run start
```
*The server will start on `http://0.0.0.0:3000`.*

### 2. Start the Frontend (`app/`)

The frontend is built with Flutter. For local device testing, ensure that you reverse port 3000 to your connected device using `adb` so it can reach the local Node.js server.

```bash
cd /Users/ronitahuja/Downloads/qrAttendanceApp/app
flutter pub get

# (Optional) Port-forward for connected Android devices
adb reverse tcp:3000 tcp:3000

# Run the app
flutter run
```

---

## 🏗 Architecture Highlights

1. **Dynamic QR Payload:** The Faculty app generates a QR Code that morphs every 1 second. It embeds `{"s": "<session_id>", "o": "<otp>", "t": <timestamp>}`.
2. **Local Processing:** By relying on local millisecond timestamps, we avoid massive API overhead, ensuring smooth scaling.
3. **No Legacy Bloat:** All complex, unreliable Bluetooth/BLE proximity logic has been stripped out in favor of the lightweight, deterministic dynamic QR architecture.

---

*Prepared for prototyping and pitch deck demonstrations.*
