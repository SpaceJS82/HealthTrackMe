// routes/friends.js
const express = require('express');
const router = express.Router();
const db = require('./db');
const { authenticateToken } = require('./auth');

// GET /friends/get-friends
const dayjs = require('dayjs');

router.get('/get-friends', authenticateToken, async (req, res) => {
  const userId = req.user.id;

  try {
    // Subquery to get max date per user for today
    const subquery = db('health_metric')
        .select('user_iduser')
        .max('date as max_date')
        .where('type', 'sleep')
        .andWhereRaw('DATE(date) = CURDATE()')
        .groupBy('user_iduser')
        .as('latest_date_per_user');

    // Join back to health_metric to get value for latest date
    const latestSleep = db('health_metric')
        .join(subquery, function () {
          this.on('health_metric.user_iduser', '=', 'latest_date_per_user.user_iduser')
              .andOn('health_metric.date', '=', 'latest_date_per_user.max_date');
        })
        .select('health_metric.user_iduser', 'health_metric.value')
        .as('latest_sleep');

    const friendsWithUser = await db('user')
        .leftJoin(latestSleep, 'user.iduser', 'latest_sleep.user_iduser')
        .where(function () {
          this.whereIn('user.iduser', function () {
            this.select('friend_iduser')
                .from('friendship')
                .where('user_iduser', userId);
          }).orWhere('user.iduser', userId); // include self
        })
        .select(
            'user.iduser as id',
            'user.name',
            'user.username',
            'latest_sleep.value as today_sleep_score'
        )
        .orderBy('today_sleep_score', 'desc');

    res.json({ friends: friendsWithUser, error: null });
  } catch (err) {
    console.error('❌ Error in /get-friends:', err);
    res.status(500).json({ friends: [], error: 'Error fetching friends and sleep scores' });
  }
});



// GET /friends/get-friend-data?friendId=123
router.get('/get-friend-data', authenticateToken, async (req, res) => {
  const userId = req.user.id;
  const friendId = parseInt(req.query.friendId);

  if (!friendId) {
    return res.status(400).send('Missing friendId');
  }

  try {
    const isFriend = await db('friendship')
      .where({
        user_iduser: userId,
        friend_iduser: friendId
      })
      .first();

    if (!isFriend) return res.status(403).send('Not your friend');

    const friendData = await db('user')
      .where({ iduser: friendId })
      .select('iduser', 'username') 
      .first();

    res.json(friendData);
  } catch (err) {
    console.error(err);
    res.status(500).send('Error fetching friend data');
  }
});

// DELETE /friends/delete-friendship
router.delete('/delete-friendship', authenticateToken, async (req, res) => {
  const userId = req.user.id;
  const friendId = parseInt(req.query.friendId);

  if (!friendId) {
    return res.status(400).json({ error: 'Missing friendId' });
  }

  try {
    await db.transaction(async trx => {
      await trx('friendship')
        .where({ user_iduser: userId, friend_iduser: friendId })
        .orWhere({ user_iduser: friendId, friend_iduser: userId })
        .del();
    });

    res.json({ error: null });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Error deleting friendship' });
  }
});



module.exports = router;
