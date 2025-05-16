// routes/friends.js
const express = require('express');
const router = express.Router();
const db = require('./db');
const { authenticateToken } = require('./auth');

// GET /friends/get-friends
router.get('/get-friends', authenticateToken, async (req, res) => {
  const userId = req.user.id;

  try {
    const friends = await db('friendship')
      .join('user', 'user.iduser', 'friendship.friend_iduser')
      .where('friendship.user_iduser', userId)
      .select(
        'user.iduser as id',
        'user.name',
        'user.username'
      );

    res.json({ friends, error: null });
  } catch (err) {
    console.error(err);
    res.status(500).json({ friends: [], error: 'Error fetching friends' });
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
