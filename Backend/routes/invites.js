const express = require('express');
const router = express.Router();
const db = require('../db/db');
const { authenticateToken } = require('./auth');

// Pošlji povabilo
router.post('/', authenticateToken, async (req, res) => {
  const sender = req.user;
  const { username } = req.body;
  console.log("🔔 Invite endpoint HIT");

  if (!username) {
    return res.status(400).json({ error: "Missing username" });
  }

  try {
    const receiver = await db('user').where({ username }).first();

    if (!receiver) {
      return res.status(404).json({ error: "Receiver not found" });
    }

    const receiverId = receiver.iduser;

    if (sender.id === receiverId) {
      return res.status(400).json({ error: "Cannot invite yourself" });
    }

    const existingInvite = await db('friend_invite')
        .where({ sender_iduser: sender.id, receiver_iduser: receiverId })
        .first();

    if (existingInvite) {
      console.log("🔁 Invite already exists");
      return res.status(200).json({
        message: "Invite already exists",
        success: true,
        alreadyExists: true
      });
    }

    await db('friend_invite').insert({
      sender_iduser: sender.id,
      receiver_iduser: receiverId,
      date: new Date()
    });

    res.status(201).json({ message: "Invite sent", success: true });
  } catch (err) {
    console.error("❌ Error sending invite:", err);
    res.status(500).json({ error: "Internal server error" });
  }
});

// Pridobi prejeta povabila
router.get('/received', authenticateToken, async (req, res) => {
  const userId = req.user.id;

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

// Sprejmi povabilo (in ga izbrisi, ter ustvari prijateljstvo)
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

// Zavrni (izbrisi) povabilo
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