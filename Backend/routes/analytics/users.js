const express = require('express');
const router = express.Router();
const db = require('../db');

// 1. New users per day
router.get('/new-users/daily', async (req, res) => {
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
router.get('/new-users/weekly', async (req, res) => {
  try {
    const result = await db('user')
      .select(db.raw('YEARWEEK(date_joined, 1) as week'))
      .count('* as count')
      .groupByRaw('YEARWEEK(date_joined, 1)')
      .orderBy('week', 'desc');
    res.json(result);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// 3. New users per month
router.get('/new-users/monthly', async (req, res) => {
  try {
    const result = await db('user')
      .select(db.raw('DATE_FORMAT(date_joined, "%Y-%m") as month'))
      .count('* as count')
      .groupByRaw('DATE_FORMAT(date_joined, "%Y-%m")')
      .orderBy('month', 'desc');
    res.json(result);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// 4. Average number of friends per user
router.get('/avg-friends', async (req, res) => {
  try {
    // Count total friendships (each friendship is stored once)
    const [{ total_friendships }] = await db('friendship').count('* as total_friendships');
    // Count total users
    const [{ total_users }] = await db('user').count('* as total_users');
    // Each friendship is between two users, so multiply by 2
    const avg = total_users > 0 ? (total_friendships * 2) / total_users : 0;
    res.json({ average: avg });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;