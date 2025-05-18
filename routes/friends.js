// routes/friends.js
const express = require('express');
const router = express.Router();
const db = require('./db');
const { authenticateToken } = require('./auth');

// GET /friends/get-friends
const dayjs = require('dayjs');

router.get('/get-friends', authenticateToken, async (req, res) => {
  const userId = req.user.id;
  const todayStart = dayjs().startOf('day').format('YYYY-MM-DD HH:mm:ss');
  const todayEnd = dayjs().endOf('day').format('YYYY-MM-DD HH:mm:ss');

  try {
    const friendsWithUser = await db('user')
      .leftJoin('health_metric', function () {
        this.on('user.iduser', '=', 'health_metric.user_iduser')
          .andOn('health_metric.type', '=', db.raw('?', ['sleep']))
          .andOnBetween('health_metric.date', [todayStart, todayEnd]);
      })
      .where(function () {
        this.whereIn('user.iduser', function () {
          this.select('friend_iduser')
            .from('friendship')
            .where('user_iduser', userId);
        }).orWhere('user.iduser', userId); // include yourself
      })
      .select(
        'user.iduser as id',
        'user.name',
        'user.username',
        'health_metric.value as today_sleep_score'
      )
      .orderBy('today_sleep_score', 'desc');

    res.json({ friends: friendsWithUser, error: null });
  } catch (err) {
    console.error(err);
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
