const express = require('express');
const router = express.Router();
const db = require('../db/db');
const { authenticateToken } = require('./auth');

router.post('/upload-health-metric', authenticateToken, async (req, res) => {
  const userId = req.user.id;
  const { type, value, date } = req.body;

  if (!type || value === undefined || value === null || !date) {
    return res.status(400).json({ error: 'Missing fields: type, value, or date' });
  }

  if (!['sleep', 'fitness', 'stress'].includes(type)) {
    return res.status(400).json({ error: 'Invalid type. Must be sleep, fitness or stress' });
  }

  const inputDate = new Date(date);
  const isoDate = inputDate.toISOString().split('T')[0];

  try {
    await db('health_metric')
        .whereRaw('DATE(`date`) = ? AND `type` = ? AND `user_iduser` = ?', [isoDate, type, userId])
        .del();

    await db('health_metric').insert({
      date: inputDate,
      value,
      type,
      user_iduser: userId
    });

    res.status(201).json({ message: 'Health metric uploaded' });

  } catch (err) {
    console.error('❌ Error uploading health metric:', err);
    res.status(500).json({ error: 'Server error during health metric upload' });
  }
});

router.get('/health-metric/:date', authenticateToken, async (req, res) => {
  const userId = req.user.id;
  const { date } = req.params;

  if (!date) {
    return res.status(400).send('Date is required (YYYY-MM-DD)');
  }

  try {
    const metrics = await db('health_metric')
      .whereRaw('DATE(`date`) = ? AND `user_iduser` = ?', [date, userId]);

    res.json(metrics);
  } catch (err) {
    console.error(err);
    res.status(500).send('Error fetching health metrics');
  }
});

router.delete('/delete/health-metric/:date', authenticateToken, async (req, res) => {
  const userId = req.user.id;
  const { date } = req.params;

  if (!date) {
    return res.status(400).send('Date is required (YYYY-MM-DD)');
  }

  try {
    await db('health_metric')
      .whereRaw('DATE(`date`) = ? AND `user_iduser` = ?', [date, userId])
      .delete();

    res.send('Health metric deleted');
  } catch (err) {
    console.error(err);
    res.status(500).send('Error deleting health metric');
  }
});

router.get('/health-metrics', authenticateToken, async (req, res) => {
  const userId = req.user.id;
  const { type } = req.query;
  const validTypes = ['sleep', 'fitness'];

  if (type && !validTypes.includes(type)) {
    return res.status(400).send('Invalid type. Must be sleep or fitness');
  }

  try {
    const metrics = await db('health_metric')
      .where({ user_iduser: userId })
      .modify((queryBuilder) => {
        if (type) {
          queryBuilder.where({ type });
        }
      })
      .orderBy('date', 'desc');

    res.json(metrics);
  } catch (err) {
    console.error(err);
    res.status(500).send('Error fetching health metrics');
  }
});

// GET /friend-sleep-scores?username=friendUsername&type=sleep
router.get('/friend-sleep-scores', authenticateToken, async (req, res) => {
  const { username, type } = req.query;
  const userId = req.user.id;

  if (!username || !type) {
    return res.status(400).send('Username and type are required');
  }

  if (type !== 'sleep') {
    return res.status(400).send('Type must be sleep');
  }

  try {
    const friend = await db('user').where({ username }).first();
    if (!friend) {
      return res.status(404).send('User not found');
    }

    if (friend.iduser !== userId) {
      const isFriend = await db('friendship')
          .where(function () {
            this.where({ user_iduser: userId, friend_iduser: friend.iduser })
                .orWhere({ user_iduser: friend.iduser, friend_iduser: userId });
          })
          .first();

      if (!isFriend) {
        return res.status(403).send('You are not friends with this user');
      }
    }

    const today = new Date();
    const startDate = new Date();
    startDate.setHours(0, 0, 0, 0);
    today.setHours(23, 59, 59, 999);
    startDate.setDate(today.getDate() - 6); // last 7 days including today

    const scoresRaw = await db('health_metric')
        .select(
            db.raw('DATE(date) as day'),
            db.raw('MAX(value) as value')
        )
        .where('user_iduser', friend.iduser)
        .andWhere('type', 'sleep')
        .andWhere('date', '>=', startDate)
        .andWhere('date', '<=', today)
        .groupByRaw('DATE(date)')
        .orderBy('day', 'asc');

    const scoreMap = {};
    for (const entry of scoresRaw) {
      const dateKey = new Date(entry.day).toISOString().split('T')[0];
      scoreMap[dateKey] = {
        value: entry.value,
        date: new Date(entry.day)
      };
    }

    const { password, ...friendData } = friend;

    const scores = [];
    for (let i = 0; i < 7; i++) {
      const date = new Date(startDate);
      date.setDate(startDate.getDate() + i);
      const iso = date.toISOString().split('T')[0];

      scores.push({
        date: date.toISOString(),
        value: scoreMap[iso]?.value ?? 0,
        type: 'sleep',
        user: friendData
      });
    }

    res.json({ scores });
  } catch (err) {
    console.error('Error in /friend-sleep-scores:', err);
    res.status(500).send('Error fetching friend sleep scores');
  }
});

module.exports = router;