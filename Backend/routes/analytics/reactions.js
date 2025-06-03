const express = require('express');
const router = express.Router();
const db = require('../../db/db');
const { authenticateToken } = require('./analyticsAuth');

// Helper to check if user is an admin
async function isAdmin(userId) {
  const admin = await db('isAdmin').where({ user_iduser: userId }).first();
  return !!admin;
}

// 1. Top events by number of reactions (leaderboard)
router.get('/top-events', authenticateToken, async (req, res) => {
  if (!(await isAdmin(req.user.id))) {
    return res.status(403).json({ error: 'Admin access required' });
  }

  try {
    const result = await db('event_reaction as er')
      .join('event as e', 'er.event_idevent', 'e.idevent')
      .join('user as creator', 'e.user_iduser', 'creator.iduser')
      .select(
        'e.idevent as event_idevent',
        'e.type as event_name',
        'creator.name as creator_name',
        db.raw('COUNT(er.idreaction) as reaction_count')
      )
      .groupBy('e.idevent', 'e.type', 'creator.name')
      .orderBy('reaction_count', 'desc')
      .limit(10);

    res.json(result);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// 2. Reaction types (counts)
router.get('/reaction-types', authenticateToken, async (req, res) => {
  if (!(await isAdmin(req.user.id))) return res.status(403).json({ error: 'Admin access required' });

  try {
    const result = await db('event_reaction')
        .select('reaction')
        .count('* as count')
        .groupBy('reaction')
        .orderBy('count', 'desc');
    res.json(result);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// 3. Most common reaction
router.get('/most-common', authenticateToken, async (req, res) => {
  if (!(await isAdmin(req.user.id))) return res.status(403).json({ error: 'Admin access required' });

  try {
    const [result] = await db('event_reaction')
        .select('reaction')
        .count('* as count')
        .groupBy('reaction')
        .orderBy('count', 'desc')
        .limit(1);
    res.json(result || {});
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;