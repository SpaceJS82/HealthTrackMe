const express = require('express');
const router = express.Router();
const db = require('../db');

// 1. Top events by number of reactions (leaderboard)
router.get('/top-events', async (req, res) => {
  try {
    const result = await db('event_reaction')
      .select('event_idevent')
      .count('* as reaction_count')
      .groupBy('event_idevent')
      .orderBy('reaction_count', 'desc')
      .limit(10);
    res.json(result);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// 2. Reaction types (counts)
router.get('/reaction-types', async (req, res) => {
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
router.get('/most-common', async (req, res) => {
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