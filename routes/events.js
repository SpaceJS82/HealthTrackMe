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

router.get('/get-event-reactions', authenticateToken);
router.get('/react-to-event', authenticateToken);

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


module.exports = router;
