const checkRole = (requiredRole) => {
    return (req, res, next) => {
        if (!req.role) {
            return res.status(401).json({ message: 'User not authenticated' });
        }

        if (req.role !== requiredRole) {
            return res.status(403).json({ 
                message: `User role ${req.role} is not authorized to access this resource` 
            });
        }

        next();
    };
};

module.exports = checkRole;
