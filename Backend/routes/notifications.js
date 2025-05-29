const express = require('express');
const router = express.Router();
const db = require('../db/db');
const { authenticateToken } = require('./auth');

// Save/Update device token
router.post('/register-device-token', authenticateToken, async (req, res) => {
    const { token } = req.body;
    const userId = req.user.id;

    if (!token) return res.status(400).json({ error: "Token is required" });

    try {
        await db('device_token')
            .insert({ user_iduser: userId, token })
            .onConflict(['user_iduser', 'token'])
            .ignore();

        res.status(200).json({ message: 'Device token saved' });
    } catch (err) {
        console.error('❌ Error saving device token:', err);
        res.status(500).json({ error: 'Server error' });
    }
});

// Delete a specific device token for the current user (e.g., on logout)
router.post('/remove-device-token', authenticateToken, async (req, res) => {
    const userId = req.user.id;
    const { token } = req.body;

    if (!token) return res.status(400).json({ error: "Token is required" });

    try {
        await db('device_token')
            .where({ user_iduser: userId, token })
            .del();

        res.status(200).json({ message: 'Device token removed' });
    } catch (err) {
        console.error('❌ Error removing device token:', err);
        res.status(500).json({ error: 'Server error' });
    }
});

module.exports = router;