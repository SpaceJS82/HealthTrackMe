const express = require('express');
const router = express.Router();
const db = require('./db');
const { authenticateToken } = require('./auth');

// Pošlji povabilo
router.post('/', authenticateToken, async (req, res) => {
  const senderId = req.user.id; 
  const { receiverId } = req.body;

  if (senderId === receiverId) {
    return res.status(400).send("Cannot invite yourself");
  }

  try {
    await db('friend_invite').insert({
      sender_iduser: senderId,
      receiver_iduser: receiverId,
      date: new Date()
    });

    res.status(201).send('Invite sent');
  } catch (err) {
    console.error(err);
    res.status(500).send('Error sending invite');
  }
});

//Pridobi prejeta povabila
router.get('/received/:userId', authenticateToken, async (req, res) => {
  const userId = parseInt(req.params.userId);
  if (req.user.id !== userId) {
    return res.status(403).json({ data: null, error: 'Forbidden' });
  }

  try {
    const invites = await db('friend_invite as fi')
      .join('user as u', 'fi.sender_iduser', 'u.iduser')
      .select(
        'fi.idinvite as id',
        'fi.date',
        'u.iduser as senderId',
        'u.name',
        'u.username'
      )
      .where('fi.receiver_iduser', userId);

    const formatted = invites.map(invite => ({
      id: invite.id,
      date: invite.date,
      sender: {
        id: invite.senderId,
        name: invite.name,
        username: invite.username
      }
    }));

    res.json({ data: formatted, error: null });
  } catch (err) {
    console.error(err);
    res.status(500).json({ data: null, error: 'Error fetching invites' });
  }
});

// Sprejmi povabilo (in ga izbriši, ter ustvari prijateljstvo)
router.post('/:id/accept', authenticateToken, async (req, res) => {
  const inviteId = parseInt(req.params.id);

  try {
    const invite = await db('friend_invite').where({ idinvite: inviteId }).first();

    if (!invite) {
      return res.status(404).json({ error: 'Invite not found' });
    }

    if (invite.receiver_iduser !== req.user.id) {
      return res.status(403).json({ error: 'Not your invite' });
    }

    await db.transaction(async trx => {
      await trx('friendship').insert([
        { user_iduser: invite.sender_iduser, friend_iduser: invite.receiver_iduser },
        { user_iduser: invite.receiver_iduser, friend_iduser: invite.sender_iduser }
      ]);

      await trx('friend_invite').where({ idinvite: inviteId }).delete();
    });

    res.json({ error: null });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Error accepting invite' });
  }
});


// Zavrni (izbriši) povabilo
router.delete('/:id', authenticateToken, async (req, res) => {
  const inviteId = parseInt(req.params.id);

  try {
    const invite = await db('friend_invite').where({ idinvite: inviteId }).first();

    if (!invite) {
      return res.status(404).json({ error: 'Invite not found' });
    }

    if (invite.receiver_iduser !== req.user.id && invite.sender_iduser !== req.user.id) {
      return res.status(403).json({ error: 'Not authorized to delete this invite' });
    }

    await db('friend_invite').where({ idinvite: inviteId }).delete();

    res.json({ error: null });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Error deleting invite' });
  }
});


module.exports = router;
