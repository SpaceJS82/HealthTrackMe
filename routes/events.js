// routes/events.js
const express = require('express');
const jwt = require('jsonwebtoken');
const router = express.Router();
const dayjs = require('dayjs');
const { authenticateToken } = require('./auth');
const db = require('./db');


router.get('/get-events', authenticateToken, async (req, res) => {
  const userId = req.user.id;

  // Define date 2 days ago from today
  const threeDaysAgo = dayjs().subtract(2, 'day').startOf('day').toISOString();
  const today = dayjs().endOf('day').toISOString();


  try {
    // Get friend IDs
    const friendsIdsRaw = await db('friendship')
      .where({ user_iduser: userId })
      .pluck('friend_iduser');

    const friendIds = [...new Set(friendsIdsRaw)];

    if (friendIds.length === 0) {
      return res.json({ data: [], error: null });
    }

    // Get recent events from friends
    const events = await db('event')
      .whereIn('user_iduser', friendIds)
      .andWhere('event.date', '>=', threeDaysAgo)
      .join('user', 'user.iduser', '=', 'event.user_iduser')
      .select(
        'event.idevent as id',
        'event.date',
        'event.type',
        'event.metadata',
        'user.iduser as userId',
        'user.name as userName',
        'user.username as userUsername'
      );

    // Get reactions
    const reactions = await db('event_reaction')
      .join('user', 'user.iduser', '=', 'event_reaction.user_iduser')
      .select(
        'event_reaction.idreaction as id',
        'event_reaction.reaction as content',
        'event_reaction.event_idevent as eventId',
        'user.iduser as userId',
        'user.name',
        'user.username'
      );

    // Get sleep scores and workout counts for all users
    const healthStats = await db('user')
      .leftJoin('health_metric', function () {
        this.on('user.iduser', '=', 'health_metric.user_iduser')
          .andOn('health_metric.type', '=', db.raw('?', ['sleep']))
          .andOn('health_metric.date', '>=', db.raw('?', [threeDaysAgo]))
          .andOn('health_metric.date', '<=', db.raw('?', [today]));
      })
      .leftJoin('event', function () {
        this.on('user.iduser', '=', 'event.user_iduser')
          .andOn('event.type', '=', db.raw('?', ['workout']))
          .andOn('event.date', '>=', db.raw('?', [threeDaysAgo]))
          .andOn('event.date', '<=', db.raw('?', [today]));
      })
      .groupBy('user.iduser')
      .select(
        'user.iduser',
        db.raw('MAX(health_metric.value) as sleepScore'),
        db.raw('COUNT(DISTINCT event.idevent) as numberOfWorkout')
      );

    const userStatsMap = {};
    healthStats.forEach(stat => {
      userStatsMap[stat.iduser] = {
        sleepScore: stat.sleepScore ? Number(stat.sleepScore) : null,
        numberOfWorkout: Number(stat.numberOfWorkout) || 0
      };
    });

    // Build event objects
    const result = events.map(ev => {
      const userStats = userStatsMap[ev.userId] || {};

      const eventReactions = reactions
        .filter(r => r.eventId === ev.id)
        .map(r => ({
          id: r.id,
          content: r.content,
          user: {
            id: r.userId,
            name: r.name,
            username: r.username,
            ...userStatsMap[r.userId]
          }
        }));

      return {
        id: ev.id,
        date: ev.date,
        type: ev.type,
        metaData: JSON.parse(ev.metadata),
        user: {
          id: ev.userId,
          name: ev.userName,
          username: ev.userUsername,
          ...userStats
        },
        reactions: eventReactions
      };
    });

    res.json({ data: result, error: null });

  } catch (err) {
    console.error(err);
    res.status(500).json({ data: [], error: 'Error fetching events' });
  }
});

// POST /upload-event
router.post('/upload-event', authenticateToken, async (req, res) => {
  const userId = req.user.id;
  const { metadata, type } = req.body;

  if (!metadata || !type) {
    return res.status(400).json({ error: 'Missing metadata or type' });
  }

  try {
    // Insert the event
      const [eventId] = await db('event')
      .insert({
        user_iduser: userId,
        metadata: JSON.stringify(metadata),
        type,
        date: new Date() 
      });


    const insertedEvent = await db('event')
      .where({ idevent: eventId })
      .first();



    // Return the inserted event, parsing the JSON again
    const result = {
      ...insertedEvent,
      metadata: JSON.parse(insertedEvent.metadata)
    };

    res.status(201).json({ event: result, error: null });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Error uploading event' });
  }
});


router.get('/get-event-reactions', authenticateToken, async (req, res) => {
  const eventId = req.query.eventId;

  if (!eventId) {
    return res.status(400).json({ error: 'Missing eventId' });
  }

  try {
    const reactions = await db('event_reaction')
      .where('event_idevent', eventId)
      .join('user', 'user.iduser', '=', 'event_reaction.user_iduser')
      .select(
        'event_reaction.idreaction as id',
        'event_reaction.reaction as content',
        'user.iduser as userId',
        'user.name',
        'user.username'
      );

    res.json({ data: reactions, error: null });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Error fetching reactions' });
  }
});



// POST /react-to-event
router.post('/react-to-event', authenticateToken, async (req, res) => {
  const reactingUserId = req.user.id;
  const { eventId, reaction } = req.body;

  if (!eventId || !reaction) {
    return res.status(400).json({ error: 'Missing eventId or reaction' });
  }

  try {
    // Get event and its creator
    const event = await db('event').where({ idevent: eventId }).first();

    if (!event) {
      return res.status(404).json({ error: 'Event not found' });
    }

    const eventOwnerId = event.user_iduser;

    // Prevent self-reaction if needed
    if (reactingUserId === eventOwnerId) {
      return res.status(400).json({ error: "You can't react to your own event" });
    }

    // Check if users are mutual friends (bidirectional friendship)
    const areFriends = await db('friendship')
      .where(function () {
        this.where({ user_iduser: reactingUserId, friend_iduser: eventOwnerId });
      })
      .orWhere(function () {
        this.where({ user_iduser: eventOwnerId, friend_iduser: reactingUserId });
      })
      .first();

    if (!areFriends) {
      return res.status(403).json({ error: 'You can only react to your friends\' events' });
    }

    // Add the reaction to the event
    const [reactionId] = await db('event_reaction').insert({
      reaction,
      event_idevent: eventId,
      user_iduser: reactingUserId
    });

    // Fetch the full reaction data with user info
    const newReaction = await db('event_reaction')
      .join('user', 'user.iduser', '=', 'event_reaction.user_iduser')
      .where('event_reaction.idreaction', reactionId)
      .select(
        'event_reaction.idreaction as id',
        'event_reaction.reaction as content',
        'event_reaction.event_idevent as eventId',
        'user.iduser as userId',
        'user.name',
        'user.username'
      )
      .first();

    res.status(201).json({ reaction: newReaction });

  } catch (err) {
    console.error('Error reacting to event:', err);
    res.status(500).json({ error: 'Server error while reacting to event' });
  }
});



// GET /get-event-reactions?eventId=123
router.get('/get-event-reactions', authenticateToken, async (req, res) => {
  const { eventId } = req.query;

  if (!eventId) {
    return res.status(400).json({ error: 'Missing eventId' });
  }

  try {
    const reactions = await db('event_reaction')
      .where('event_idevent', eventId)
      .join('user', 'user.iduser', '=', 'event_reaction.user_iduser')
      .select(
        'event_reaction.idreaction as id',
        'event_reaction.reaction as content',
        'user.iduser as userId',
        'user.name',
        'user.username'
      );

    res.json({ reactions, error: null });
  } catch (err) {
    console.error(err);
    res.status(500).json({ reactions: [], error: 'Error fetching reactions' });
  }
});

// DELETE /event-reaction/:id
router.delete('/event-reaction/:id', authenticateToken, async (req, res) => {
  const userId = req.user.id;
  const reactionId = req.params.id;

  try {
    // Find the reaction and check if it exists
    const reaction = await db('event_reaction').where({ idreaction: reactionId }).first();

    if (!reaction) {
      return res.status(404).json({ error: 'Reaction not found' });
    }

    // Check if the authenticated user is the one who created the reaction
    if (reaction.user_iduser !== userId) {
      return res.status(403).json({ error: 'You can only delete your own reactions' });
    }

    // Delete the reaction
    await db('event_reaction').where({ idreaction: reactionId }).del();

    res.status(200).json({ message: 'Reaction deleted successfully' });
  } catch (err) {
    console.error('Error deleting reaction:', err);
    res.status(500).json({ error: 'Server error while deleting reaction' });
  }
});

module.exports = router;
