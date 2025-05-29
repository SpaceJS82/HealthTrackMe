// routes/events.js
const express = require('express');
const jwt = require('jsonwebtoken');
const router = express.Router();
const dayjs = require('dayjs');
const { authenticateToken } = require('./auth');
const db = require('../db/db');

router.get('/get-events', authenticateToken, async (req, res) => {
  const userId = req.user.id;

  const threeDaysAgo = dayjs().subtract(2, 'day').startOf('day').toISOString();
  const today = dayjs().endOf('day').toISOString();

  try {
    const friendsIdsRaw = await db('friendship')
        .where({ user_iduser: userId })
        .pluck('friend_iduser');

    const relevantUserIds = [...new Set([...friendsIdsRaw, userId])];

    const events = await db('event')
        .whereIn('user_iduser', relevantUserIds)
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

router.post('/upload-event', authenticateToken, async (req, res) => {
  const userId = req.user.id;
  const { metadata, type } = req.body;

  if (!metadata || !type) {
    return res.status(400).json({ error: 'Missing metadata or type' });
  }

  try {
    const [eventId] = await db('event').insert({
      user_iduser: userId,
      metadata: JSON.stringify(metadata),
      type,
      date: new Date()
    });

    const insertedEvent = await db('event').where({ idevent: eventId }).first();

    res.status(201).json({
      event: {
        ...insertedEvent,
        metadata: JSON.parse(insertedEvent.metadata)
      },
      error: null
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Error uploading event' });
  }
});

router.post('/react-to-event', authenticateToken, async (req, res) => {
  const reactingUser = req.user;
  const { eventId, reaction } = req.body;

  if (!eventId || !reaction) {
    return res.status(400).json({ error: 'Missing eventId or reaction' });
  }

  try {
    const event = await db('event').where({ idevent: eventId }).first();
    if (!event) return res.status(404).json({ error: 'Event not found' });

    const eventOwnerId = event.user_iduser;
    if (reactingUser.id === eventOwnerId) {
      return res.status(400).json({ error: "You can't react to your own event" });
    }

    const areFriends = await db('friendship')
        .where({ user_iduser: reactingUser.id, friend_iduser: eventOwnerId })
        .orWhere({ user_iduser: eventOwnerId, friend_iduser: reactingUser.id })
        .first();

    if (!areFriends) {
      return res.status(403).json({ error: "You can only react to your friends' events" });
    }

    await db('event_reaction')
        .where({ user_iduser: reactingUser.id, event_idevent: eventId })
        .delete();

    const [reactionId] = await db('event_reaction').insert({
      reaction,
      event_idevent: eventId,
      user_iduser: reactingUser.id
    });

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

    res.status(201).json({
      reaction: {
        id: newReaction.id,
        content: newReaction.content,
        eventId: newReaction.eventId,
        user: {
          id: newReaction.userId,
          name: newReaction.name,
          username: newReaction.username
        }
      }
    });
  } catch (err) {
    console.error('Error reacting to event:', err);
    res.status(500).json({ error: 'Server error while reacting to event' });
  }
});

// Remaining routes were not using APN and are unchanged
module.exports = router;