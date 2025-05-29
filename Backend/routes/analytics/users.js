const express = require('express');
const router = express.Router();
const db = require('../../db/db');
const { authenticateToken } = require('../auth');

// Helper to check if user is admin
async function isAdmin(userId) {
  const admin = await db('isAdmin').where({ user_iduser: userId }).first();
  return !!admin;
}

// Middleware to check for admin access
async function requireAdmin(req, res, next) {
  if (!(await isAdmin(req.user.id))) {
    return res.status(403).json({ error: 'Admin access required' });
  }
  next();
}

// 1. New users per day
router.get('/new-users/daily', authenticateToken, requireAdmin, async (req, res) => {
  try {
    const result = await db('user')
        .select(db.raw('DATE(date_joined) as date'))
        .count('* as count')
        .groupByRaw('DATE(date_joined)')
        .orderBy('date', 'desc');
    res.json(result);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// 2. New users per week
router.get('/new-users/weekly', authenticateToken, requireAdmin, async (req, res) => {
  try {
    const result = await db('user')
        .select(db.raw('CONCAT(YEAR(date_joined), "-W", LPAD(WEEK(date_joined, 1), 2, "0")) as date'))
        .count('* as count')
        .groupByRaw('CONCAT(YEAR(date_joined), "-W", LPAD(WEEK(date_joined, 1), 2, "0"))')
        .orderBy('date', 'desc');
    res.json(result);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// 3. New users per month
router.get('/new-users/monthly', authenticateToken, requireAdmin, async (req, res) => {
  try {
    const result = await db('user')
        .select(db.raw('DATE_FORMAT(date_joined, "%Y-%m") as date'))
        .count('* as count')
        .groupByRaw('DATE_FORMAT(date_joined, "%Y-%m")')
        .orderBy('date', 'desc');
    res.json(result);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// 4. Average number of friends per user
router.get('/avg-friends', authenticateToken, requireAdmin, async (req, res) => {
  try {
    const [{ total_friendships }] = await db('friendship').count('* as total_friendships');
    const [{ total_users }] = await db('user').count('* as total_users');
    const avg = total_users > 0 ? (total_friendships * 2) / total_users : 0;
    res.json({ average: avg });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;