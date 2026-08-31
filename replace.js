const fs = require('fs');
const path = require('path');

const replacements = [
  ['OtpVerificationScreen', 'QrScannerScreen'],
  ['otp_verification_screen.dart', 'qr_scanner_screen.dart'],
  ['ConfigureOtpScreen', 'ConfigureSessionScreen'],
  ['configure_otp_screen.dart', 'configure_session_screen.dart'],
  ['FacultyAttendanceOtpGeneratorScreen', 'FacultyAttendanceQrGeneratorScreen'],
  ['faculty_attendance_otp_generator_screen.dart', 'faculty_attendance_qr_generator_screen.dart'],
  ['rotateOtp', 'rotateQrCode'],
  ['otpCode', 'qrCode'],
  ['otpIssuedAt', 'qrIssuedAt'],
  ['otpExpiresAt', 'qrExpiresAt'],
  ['previousOtpCode', 'previousQrCode'],
  ['generateOtp', 'generateQrCode'],
  ["'invalidOtp'", "'invalidQrCode'"],
  ["'otpExpired'", "'qrExpired'"],
  ["'otp'", "'qr'"]
];

function processDir(dir) {
  const files = fs.readdirSync(dir);
  for (const file of files) {
    if (file === 'node_modules' || file === '.git' || file === 'replace.js' || file.endsWith('.png') || file.endsWith('.jpg') || file.endsWith('.jpeg')) continue;
    const fullPath = path.join(dir, file);
    if (fs.statSync(fullPath).isDirectory()) {
      processDir(fullPath);
    } else {
      let content = fs.readFileSync(fullPath, 'utf8');
      let changed = false;
      for (const [oldStr, newStr] of replacements) {
        if (content.includes(oldStr)) {
          // simple replace all
          content = content.split(oldStr).join(newStr);
          changed = true;
        }
      }
      if (changed) {
        fs.writeFileSync(fullPath, content);
        console.log('Updated', fullPath);
      }
    }
  }
}

processDir('./app/lib');
processDir('./backend');
