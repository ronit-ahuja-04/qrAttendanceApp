const rateLimit = require('express-rate-limit');

// Standard API Rate Limiter
// Max 3000 requests per 15 minutes per IP
const apiLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, 
  max: 3000, 
  message: { error: 'tooManyRequests', message: 'Too many requests from this IP, please try again after 15 minutes.' },
  standardHeaders: true, 
  legacyHeaders: false, 
});

// Strict Login Rate Limiter
// Max 3000 attempts per 15 minutes to prevent lockouts on shared WiFi
const loginLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 3000,
  message: { error: 'tooManyLoginAttempts', message: 'Too many login attempts from this IP, please try again after 15 minutes.' },
  standardHeaders: true,
  legacyHeaders: false,
});

// Strict Attendance Rate Limiter
// Max 3000 attempts per minute to allow an entire class to scan simultaneously on shared WiFi
const attendanceLimiter = rateLimit({
  windowMs: 1 * 60 * 1000,
  max: 3000,
  message: { error: 'tooManyAttendanceAttempts', message: 'Too many attendance attempts from this IP, please try again after 1 minute.' },
  standardHeaders: true,
  legacyHeaders: false,
});

module.exports = {
  apiLimiter,
  loginLimiter,
  attendanceLimiter
};
