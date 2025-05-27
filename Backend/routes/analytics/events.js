const express = require('express');
const router = express.Router();
const db = require('../db');
const { authenticateToken } = require('../auth');

// Helper to check if user is admin
async function isAdmin(userId) {
  const admin = await db('isAdmin').where({ user_iduser: userId }).first();
  return !!admin;
}

// Middleware to require admin
async function requireAdmin(req, res, next) {
  if (!(await isAdmin(req.user.id))) {
    return res.status(403).json({ error: 'Admin access required' });
  }
  next();
}

// 1. Events per day (by type)
router.get('/per-day', authenticateToken, requireAdmin, async (req, res) => {
  try {
    const result = await db('event')
        .select(db.raw('type, DATE(date) as date'))
        .count('* as count')
        .groupByRaw('type, DATE(date)')
        .orderBy(['date', 'type']);
    res.json(result);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// 2. Events per week (by type)
router.get('/per-week', authenticateToken, requireAdmin, async (req, res) => {
  try {
    const result = await db('event')
        .select(db.raw('type, YEARWEEK(date, 1) as week'))
        .count('* as count')
        .groupByRaw('type, YEARWEEK(date, 1)')
        .orderBy(['week', 'type']);
    res.json(result);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// 3. Events per month (by type)
router.get('/per-month', authenticateToken, requireAdmin, async (req, res) => {
  try {
    const result = await db('event')
        .select(db.raw('type, DATE_FORMAT(date, "%Y-%m") as month'))
        .count('* as count')
        .groupByRaw('type, DATE_FORMAT(date, "%Y-%m")')
        .orderBy(['month', 'type']);
    res.json(result);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// 4. Top users by number of events
router.get('/top-users', authenticateToken, requireAdmin, async (req, res) => {
  try {
    const result = await db('event')
        .select('user_iduser')
        .count('* as event_count')
        .groupBy('user_iduser')
        .orderBy('event_count', 'desc')
        .limit(10);

    const users = await db('user')
        .whereIn('iduser', result.map(r => r.user_iduser))
        .select('iduser', 'username', 'name');

    const enriched = result.map(r => ({
      ...r,
      user: users.find(u => u.iduser === r.user_iduser) || null
    }));

    res.json(enriched);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// 5. Average time between events per user (in hours)
router.get('/avg-time-between', authenticateToken, requireAdmin, async (req, res) => {
  try {
    const users = await db('user').select('iduser', 'username');
    const results = [];

    for (const user of users) {
      const events = await db('event')
          .where('user_iduser', user.iduser)
          .orderBy('date', 'asc')
          .select('date');

      if (events.length < 2) {
        results.push({ user_id: user.iduser, username: user.username, avg_hours: null });
        continue;
      }

      let totalDiff = 0;
      for (let i = 1; i < events.length; i++) {
        const prev = new Date(events[i - 1].date);
        const curr = new Date(events[i].date);
        totalDiff += (curr - prev) / (1000 * 60 * 60); // ms → hours
      }

      const avg = totalDiff / (events.length - 1);
      results.push({ user_id: user.iduser, username: user.username, avg_hours: avg });
    }

    res.json(results);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// 6. Event type distribution per user (percentages)
router.get('/type-distribution', authenticateToken, requireAdmin, async (req, res) => {
  try {
    const users = await db('user').select('iduser', 'username');
    const results = [];

    for (const user of users) {
      const events = await db('event')
          .where('user_iduser', user.iduser)
          .select('type');

      const total = events.length;
      if (total === 0) {
        results.push({ user_id: user.iduser, username: user.username });
        continue;
      }

      const counts = {};
      for (const e of events) {
        counts[e.type] = (counts[e.type] || 0) + 1;
      }

      const distribution = {};
      for (const [type, count] of Object.entries(counts)) {
        distribution[`${type}_pct`] = Math.round((count / total) * 100);
      }

      results.push({ user_id: user.iduser, username: user.username, ...distribution });
    }

    res.json(results);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;