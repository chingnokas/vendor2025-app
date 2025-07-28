const jwt = require('jsonwebtoken');
require('dotenv').config();

const verifyToken = (req, res, next) => {
    const authHeader = req.headers.authorization;
    if (!authHeader) {
        return res.status(401).json({ message: 'No token provided' });
    }

    const token = authHeader.split(' ')[1];
    if (!token) {
        return res.status(401).json({ message: 'Invalid token format' });
    }

    jwt.verify(token, process.env.JWT_SECRET, (err, decoded) => {
        if (err) {
            return res.status(401).json({ message: 'Invalid or expired token' });
        }
        req.userId = decoded.userId;
        req.role = decoded.role;
        next();
    });
};

const checkRole = (roles) => {
    return (req, res, next) => {
        if (!roles.includes(req.role)) {
            return res.status(403).json({ 
                message: `User role ${req.role} is not authorized to access this resource` 
            });
        }
        next();
    };
};

module.exports = { verifyToken, checkRole };
