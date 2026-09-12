const jwt = require('jsonwebtoken');

// Use a secure secret in production (e.g. process.env.JWT_SECRET)
const JWT_SECRET = process.env.JWT_SECRET || 'fallback_secret_for_development_only_12345';

const db = require('../database');

/**
 * Middleware to verify JWT tokens
 */
function authenticateToken(req, res, next) {
  const authHeader = req.headers['authorization'];
  const token = (authHeader && authHeader.split(' ')[1]) || req.query.token;

  if (!token) {
    return res.status(401).json({ error: 'unauthorized', message: 'Authentication token is required.' });
  }

  jwt.verify(token, JWT_SECRET, (err, user) => {
    if (err) {
      return res.status(403).json({ error: 'forbidden', message: 'Invalid or expired token.' });
    }
    
    // For students, strictly enforce device binding on every request
    if (user.role === 'student') {
      db.get('SELECT deviceId FROM users WHERE id = ?', [user.id], (dbErr, row) => {
        if (dbErr || !row) {
          return res.status(401).json({ error: 'unauthorized', message: 'User not found.' });
        }
        
        // If DB deviceId does not match the token's embedded deviceId snapshot,
        // it means the binding was claimed by another device after this token was issued. Kill the session.
        // We implicitly allow requests if row.deviceId is null (unbound) to prevent aggressive data wipes on unbound accounts.
        if (row.deviceId && row.deviceId !== user.deviceId) {
          return res.status(401).json({ error: 'unbound', message: 'Device binding has changed. Please log in again.' });
        }
        
        req.user = user;
        next();
      });
    } else {
      req.user = user;
      next();
    }
  });
}

/**
 * Helper to generate JWT token for a user
 */
function generateToken(user) {
  // We only store non-sensitive info in the payload
  const payload = {
    id: user.id,
    role: user.role,
    email: user.email,
    name: user.name,
    branch: user.branch,
    deviceId: user.deviceId // Inject bound device ID into token
  };
  
  // Token expires in 7 days
  return jwt.sign(payload, JWT_SECRET, { expiresIn: '7d' });
}

/**
 * Middleware to strictly enforce RBAC by checking req.user.role
 * @param {string[]} allowedRoles - Array of roles allowed to access the route
 */
function requireRole(allowedRoles) {
  return (req, res, next) => {
    if (!req.user || !req.user.role) {
      return res.status(401).json({ error: 'unauthorized', message: 'User role not found.' });
    }
    
    if (!allowedRoles.includes(req.user.role)) {
      return res.status(403).json({ error: 'forbidden', message: 'You do not have permission to access this resource.' });
    }
    
    next();
  };
}

module.exports = {
  authenticateToken,
  generateToken,
  requireRole,
  JWT_SECRET
};
