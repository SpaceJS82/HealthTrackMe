const express = require('express');
const path = require('path');
const router = express.Router();
const db = require('../db/db');
const apn = require('apn');
const { Provider } = apn;
const { authenticateToken } = require('./auth');

// APNs Provider Setup
const apnProvider = new Provider({
    token: {
        key: path.join(__dirname, 'SECRET'),
        keyId: "SECRET",
        teamId: "SECRET"
    },
    production: true // true in production
});

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

// Send "poke" notification
router.post('/poke', authenticateToken, async (req, res) => {
    const sender = req.user;
    const { toUserId, message } = req.body;

    if (!toUserId || !message) {
        return res.status(400).json({ error: "Target user ID and message are required" });
    }

    try {
        // 1. Get receiver info
        const receiver = await db('user').where('iduser', toUserId).first();
        if (!receiver) {
            return res.status(404).json({ error: "Target user not found" });
        }

        // 2. Check if they are friends
        const isFriend = await db('friendship')
            .where(function () {
                this.where({ user1_id: sender.id, user2_id: toUserId })
                    .orWhere({ user1_id: toUserId, user2_id: sender.id });
            })
            .first();

        if (!isFriend) {
            return res.status(403).json({ error: "You can only poke friends" });
        }

        // 3. Fetch target user's device tokens
        const tokens = await db('device_token').where('user_iduser', toUserId);
        if (tokens.length === 0) {
            return res.status(404).json({ error: "Target user has no device token" });
        }

        // 4. Clean message: remove receiver name if present
        const regex = new RegExp(`^${receiver.name}:\\s*`, 'i');
        const cleanMessage = message.replace(regex, '').trim();

        // 5. Create and send APNs notification
        const notification = new apn.Notification({
            alert: {
                title: sender.name,
                body: cleanMessage
            },
            payload: {
                fromUserId: sender.id,
                customMessage: cleanMessage
            },
            topic: "SECRET"
        });

        const result = await apnProvider.send(notification, tokens.map(t => t.token));
        console.log("🔔 Notification sent:", result.sent.length, "success");

        res.status(200).json({ message: 'Poke sent' });

    } catch (err) {
        console.error('❌ Error sending poke:', err);
        res.status(500).json({ error: 'Server error' });
    }
});

module.exports = router;