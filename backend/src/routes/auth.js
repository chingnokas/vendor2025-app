const express = require('express');
const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const { verifyToken, checkRole } = require('../middleware/auth');
const User = require('../models/User');

const router = express.Router();
require('dotenv').config();

// Register new user
router.post('/register', async (req, res) => {
    try {
        const { email, password, name, role } = req.body;
        
        // Check if user exists
        const existingUser = await User.findByEmail(email);
        if (existingUser) {
            return res.status(400).json({ message: 'User already exists' });
        }

        const userId = await User.register({
            email,
            password,
            name,
            role: role || 'user'
        });

        const token = jwt.sign(
            { userId: Number(userId), role: role || 'user' },
            process.env.JWT_SECRET,
            { expiresIn: '1h' }
        );

        res.status(201).json({
            message: 'User registered successfully',
            token,
            userId: Number(userId)
        });
    } catch (error) {
        console.error('Registration error:', error);
        res.status(500).json({ message: 'Registration failed' });
    }
});

// Login
router.post('/login', async (req, res) => {
    try {
        const { email, password } = req.body;
        
        const user = await User.findByEmail(email);
        if (!user) {
            return res.status(401).json({ message: 'Invalid credentials' });
        }

        const isValidPassword = await bcrypt.compare(password, user.password);
        if (!isValidPassword) {
            return res.status(401).json({ message: 'Invalid credentials' });
        }

        const token = jwt.sign(
            { userId: user.id, role: user.role },
            process.env.JWT_SECRET,
            { expiresIn: '1h' }
        );

        res.json({
            message: 'Login successful',
            token,
            userId: user.id,
            role: user.role
        });
    } catch (error) {
        console.error('Login error:', error);
        res.status(500).json({ message: 'Login failed' });
    }
});

// Refresh token (for future implementation)
router.post('/refresh-token', verifyToken, async (req, res) => {
    try {
        const newToken = jwt.sign(
            { userId: req.userId, role: req.role },
            process.env.JWT_SECRET,
            { expiresIn: '1h' }
        );
        res.json({ token: newToken });
    } catch (error) {
        console.error('Refresh token error:', error);
        res.status(500).json({ message: 'Failed to refresh token' });
    }
});

module.exports = router;
