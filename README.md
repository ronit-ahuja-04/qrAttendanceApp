# qrAttendanceApp

Flutter frontend and Node.js backend for a dynamic QR attendance system.

## Structure
- `app/`: Flutter frontend (Android/iOS/Web/Desktop)
- `server/`: Node.js/Express backend (SQLite, TypeScript)

## Running Locally

### Backend
```bash
cd server
npm install
npm run start # Starts on http://0.0.0.0:3000
```

### Frontend
```bash
cd app
flutter pub get
adb reverse tcp:3000 tcp:3000 # Port-forward for connected Android devices
flutter run
```

## Mechanics
- **Payload**: `{"s": "<session_id>", "o": "<otp>", "t": <timestamp>}`, rotates every 1s.
- **Validation**: Local millisecond timestamp comparison instead of proximity checks.

## Documentation
- [High Definition Master Guide](docs/High_Definition_Master_Guide.md)
- [Local QA Setup Guide](docs/Local_QA_Setup_Guide.md)
- [Team Testing Epics](docs/Team_Testing_Epics.md)
