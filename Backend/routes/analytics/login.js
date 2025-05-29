const express = require('express');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const router = express.Router();
const db = require('../../db/db');

const JWT_SECRET = process.env.JWT_SECRET || 'your_secret_key';

router.post('/login', async (req, res) => {
    const { username, password } = req.body;

    try {
        const users = await db('user').where({ username });

        if (users.length === 0) {
            return res.status(404).send('User not found');
        }

        const user = users[0];

        const isMatch = await bcrypt.compare(password, user.password);
        if (!isMatch) {
            return res.status(401).send('Incorrect password');
        }

        // Check if user is admin
        const isAdmin = await db('isAdmin').where({ user_iduser: user.iduser }).first();
        if (!isAdmin) {
            return res.status(403).send('Admin access required');
        }

        // Generate JWT
        const token = jwt.sign(
            {
                id: user.iduser,
                username: user.username,
                name: user.name
            },
            JWT_SECRET,
            { expiresIn: '15m' }
        );

        res.status(200).json({
            token,
            user: {
                id: user.iduser,
                username: user.username,
                name: user.name
            }
        });
    } catch (error) {
        console.error('Login error:', error);
        res.status(500).send('Error logging in');
    }
});

module.exports = router;