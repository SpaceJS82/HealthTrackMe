const express = require('express');
const router = express.Router();
const db = require('../db');
const { authenticateToken } = require('../auth');

// Helper to check admin status
async function isAdmin(userId) {
  const admin = await db('isAdmin').where({ user_iduser: userId }).first();
  return !!admin;
}

// Middleware for admin check
async function requireAdmin(req, res, next) {
  if (!(await isAdmin(req.user.id))) {
    return res.status(403).json({ error: 'Admin access required' });
  }
  next();
}

// 1. Friendships per day (network growth)
router.get('/per-day', authenticateToken, requireAdmin, async (req, res) => {
  try {
    const result = await db('friendship')
        .select(db.raw('DATE(created_at) as date'))
        .count('* as count')
        .groupByRaw('DATE(created_at)')
        .orderBy('date', 'desc');
    res.json(result);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// 2. Invite conversion rate (invites to friendships)
router.get('/invite-conversion', authenticateToken, requireAdmin, async (req, res) => {
  try {
    const [{ invites_sent }] = await db('friend_invite').count('* as invites_sent');
    const [{ friendships_created }] = await db('friendship').count('* as friendships_created');
    const conversion_rate = invites_sent > 0 ? Math.round((friendships_created / invites_sent) * 100) : 0;
    res.json({
      invites_sent: Number(invites_sent),
      friendships_created: Number(friendships_created),
      conversion_rate
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// 3. Invites per day
router.get('/invites-per-day', authenticateToken, requireAdmin, async (req, res) => {
  try {
    const result = await db('friend_invite')
        .select(db.raw('DATE(date) as date'))
        .count('* as count')
        .groupByRaw('DATE(date)')
        .orderBy('date', 'desc');
    res.json(result);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;