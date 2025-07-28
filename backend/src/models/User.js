const bcrypt = require('bcryptjs');
const pool = require('../config/database');

class User {
    static async register(userData) {
        const { email, password, name, role = 'user' } = userData;

        // Hash password
        const hashedPassword = await bcrypt.hash(password, 10);

        const conn = await pool.getConnection();
        try {
            const result = await conn.query(
                'INSERT INTO users (email, password, name, role) VALUES (?, ?, ?, ?)',
                [email, hashedPassword, name, role]
            );
            return result.insertId;
        } finally {
            conn.release();
        }
    }

    static async findByEmail(email) {
        const conn = await pool.getConnection();
        try {
            const rows = await conn.query(
                'SELECT * FROM users WHERE email = ?',
                [email]
            );
            return rows.length > 0 ? rows[0] : null;
        } finally {
            conn.release();
        }
    }

    static async findById(id) {
        const conn = await pool.getConnection();
        try {
            const rows = await conn.query(
                'SELECT * FROM users WHERE id = ?',
                [id]
            );
            return rows.length > 0 ? rows[0] : null;
        } finally {
            conn.release();
        }
    }

    static async updatePassword(userId, newPassword) {
        const hashedPassword = await bcrypt.hash(newPassword, 10);
        const conn = await pool.getConnection();
        try {
            await conn.query(
                'UPDATE users SET password = ? WHERE id = ?',
                [hashedPassword, userId]
            );
        } finally {
            conn.release();
        }
    }
}

module.exports = User;
