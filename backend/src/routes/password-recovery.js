const express = require('express');
const bcrypt = require('bcryptjs');
const User = require('../models/User');
const { verifyToken } = require('../middleware/auth');
const pool = require('../config/database');
require('dotenv').config();

const router = express.Router();

// Generate password reset token
router.post('/request-reset', async (req, res) => {
    try {
        const { email } = req.body;
        const user = await User.findByEmail(email);

        if (!user) {
            return res.status(404).json({ message: 'User not found' });
        }

        // Generate reset token
        const resetToken = Math.random().toString(36).substring(2) + Math.random().toString(36).substring(2);
        const resetTokenExpiration = Date.now() + 3600000; // 1 hour

        // Update user with reset token
        const conn = await pool.getConnection();
        try {
            await conn.query(
                'UPDATE users SET reset_token = ?, reset_token_expires = ? WHERE id = ?',
                [resetToken, resetTokenExpiration, user.id]
            );

            // Send email
            const transporter = nodemailer.createTransport({
                service: 'gmail',
                auth: {
                    user: process.env.EMAIL_USER,
                    pass: process.env.EMAIL_PASS
                }
            });

            const mailOptions = {
                from: process.env.EMAIL_USER,
                to: email,
                subject: 'Password Reset Request',
                html: `
                    <h2>Password Reset</h2>
                    <p>Click the following link to reset your password:</p>
                    <a href="http://localhost:4200/reset-password/${resetToken}">
                        Reset Password
                    </a>
                    <p>This link will expire in 1 hour.</p>
                `
            };

            await transporter.sendMail(mailOptions);

            res.json({ message: 'Password reset email sent' });
        } finally {
            conn.release();
        }
    } catch (error) {
        console.error('Password reset error:', error);
        res.status(500).json({ message: 'Failed to send password reset email' });
    }
});

// Verify reset token
router.get('/verify-reset/:token', async (req, res) => {
    try {
        const { token } = req.params;
        const conn = await pool.getConnection();
        try {
            const [rows] = await conn.query(
                'SELECT * FROM users WHERE reset_token = ? AND reset_token_expires > ?',
                [token, Date.now()]
            );

            if (rows.length === 0) {
                return res.status(400).json({ message: 'Invalid or expired reset token' });
            }

            res.json({ message: 'Valid reset token' });
        } finally {
            conn.release();
        }
    } catch (error) {
        console.error('Verify reset token error:', error);
        res.status(500).json({ message: 'Failed to verify reset token' });
    }
});

// Reset password
router.post('/reset-password', async (req, res) => {
    try {
        const { token, newPassword } = req.body;
        const conn = await pool.getConnection();
        try {
            const [rows] = await conn.query(
                'SELECT * FROM users WHERE reset_token = ? AND reset_token_expires > ?',
                [token, Date.now()]
            );

            if (rows.length === 0) {
                return res.status(400).json({ message: 'Invalid or expired reset token' });
            }

            const hashedPassword = await bcrypt.hash(newPassword, 10);
            await conn.query(
                'UPDATE users SET password = ?, reset_token = NULL, reset_token_expires = NULL WHERE id = ?',
                [hashedPassword, rows[0].id]
            );

            res.json({ message: 'Password reset successfully' });
        } finally {
            conn.release();
        }
    } catch (error) {
        console.error('Password reset error:', error);
        res.status(500).json({ message: 'Failed to reset password' });
    }
});

module.exports = router;
