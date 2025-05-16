const express = require('express');
const router = express.Router();
const db = require('./db');
const { authenticateToken } = require('./auth');

router.post('/upload-health-metric', authenticateToken, async (req, res) => {
  const userId = req.user.id;
  const { type, value, date } = req.body;

  if (!type || !value || !date) {
    return res.status(400).send('Missing fields: type, value, or date');
  }

  if (!['sleep', 'fitness'].includes(type)) {
    return res.status(400).send('Invalid type. Must be sleep or fitness');
  }

  const inputDate = new Date(date);
  const isoDate = inputDate.toISOString().split('T')[0]; // YYYY-MM-DD

  try {
    const existing = await db('health_metric')
      .whereRaw('DATE(`date`) = ? AND `type` = ? AND `user_iduser` = ?', [isoDate, type, userId])
      .first();

    if (existing) {
      await db('health_metric')
        .where({ idmetric: existing.idmetric })
        .update({ value, date: inputDate });
      res.send('Health metric updated');
    } else {
      await db('health_metric').insert({
        date: inputDate,
        value,
        type,
        user_iduser: userId
      });
      res.status(201).send('Health metric uploaded');
    }
  } catch (err) {
    console.error(err);
    res.status(500).send('Error uploading or updating health metric');
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



module.exports = router;
