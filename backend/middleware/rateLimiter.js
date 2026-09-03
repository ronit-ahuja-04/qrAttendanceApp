const rateLimit = require('express-rate-limit');

// Standard API Rate Limiter
// Max 1000 requests per 15 minutes per IP
const apiLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, 
  max: 1000, 
  message: { error: 'tooManyRequests', message: 'Too many requests from this IP, please try again after 15 minutes.' },
  standardHeaders: true, 
  legacyHeaders: false, 
});

// Strict Login Rate Limiter
// Max 5 attempts per 15 minutes to prevent brute force credential stuffing
const loginLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 5,
  message: { error: 'tooManyLoginAttempts', message: 'Too many login attempts from this IP, please try again after 15 minutes.' },
  standardHeaders: true,
  legacyHeaders: false,
});

// Strict Attendance Rate Limiter
// Max 10 attempts per minute to prevent brute forcing QR codes
const attendanceLimiter = rateLimit({
  windowMs: 1 * 60 * 1000,
  max: 10,
  message: { error: 'tooManyAttendanceAttempts', message: 'Too many attendance attempts from this IP, please try again after 1 minute.' },
  standardHeaders: true,
  legacyHeaders: false,
});

module.exports = {
  apiLimiter,
  loginLimiter,
  attendanceLimiter
};
