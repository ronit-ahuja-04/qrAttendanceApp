const jwt = require('jsonwebtoken');

// Use a secure secret in production (e.g. process.env.JWT_SECRET)
const JWT_SECRET = process.env.JWT_SECRET || 'fallback_secret_for_development_only_12345';

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
    
    // Attach the decoded payload to the request object
    req.user = user;
    next();
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
    branch: user.branch
  };
  
  // Token expires in 7 days
  return jwt.sign(payload, JWT_SECRET, { expiresIn: '7d' });
}

module.exports = {
  authenticateToken,
  generateToken,
  JWT_SECRET
};
