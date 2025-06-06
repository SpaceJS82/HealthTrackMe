const express = require('express');
const router = express.Router();
const db = require('../../db/db');
const {authenticateToken} = require("./analyticsAuth");
const dayjs = require('dayjs');

router.post('/upload', async (req, res) => {
    const { title, metadata, secret_key } = req.body;

    if (secret_key !== "yoa_inappevent_tracking") {
        return
    }

    if (!title || !metadata) {
        return res.status(400).json({ error: 'Missing title or metadata' });
    }

    try {
        const [insertedId] = await db('inapp_events').insert({
            title,
            metadata: JSON.stringify(metadata) // Ensure it's stored as JSON string
        });

        const insertedEvent = await db('inapp_events')
            .where({ id: insertedId })
            .first();

        res.status(201).json({
            data: {
                id: insertedEvent.id,
                title: insertedEvent.title,
                metadata: JSON.parse(insertedEvent.metadata),
                date_created: insertedEvent.date_created
            },
            error: null
        });
    } catch (err) {
        console.error('Error inserting in-app event:', err);
        res.status(500).json({ error: 'Server error while uploading in-app event' });
    }
});

router.get('/by-title', authenticateToken, async (req, res) => {
    const userId = req.user.id;
    const { title, days } = req.query;

    if (!title || isNaN(days)) {
        return res.status(400).json({ error: 'Missing or invalid `title` or `days` query parameter' });
    }

    try {
        // ✅ Check if user is an admin
        const isAdmin = await db('isAdmin').where({ user_iduser: userId }).first();

        if (!isAdmin) {
            return res.status(403).json({ error: 'You must be an admin to access this resource' });
        }

        const startDate = dayjs().subtract(Number(days), 'day').startOf('day').toDate();
        const endDate = dayjs().endOf('day').toDate();

        const events = await db('inapp_events')
            .where('title', title)
            .andWhere('date_created', '>=', startDate)
            .andWhere('date_created', '<=', endDate)
            .orderBy('date_created', 'desc');

        const formatted = events.map(ev => ({
            id: ev.id,
            title: ev.title,
            metadata: JSON.parse(ev.metadata),
            date_created: ev.date_created
        }));

        res.json({ data: formatted, error: null });
    } catch (err) {
        console.error('Error fetching in-app events:', err);
        res.status(500).json({ data: [], error: 'Server error' });
    }
});
// Get all unique event titles
router.get('/titles', authenticateToken, async (req, res) => {
    try {
        // Check admin status
        const isAdmin = await db('isAdmin').where({ user_iduser: req.user.id }).first();
        if (!isAdmin) {
            return res.status(403).json({ error: 'Admin access required' });
        }

        const titles = await db('inapp_events')
            .distinct('title')
            .pluck('title')
            .orderBy('title', 'asc');

        res.json({ titles });
    } catch (err) {
        console.error('Error fetching event titles:', err);
        res.status(500).json({ error: 'Server error' });
    }
});

// Get event counts by date range
router.get('/count-by-date', authenticateToken, async (req, res) => {
    try {
        const { start, end, title } = req.query;
        
        // Check admin status
        const isAdmin = await db('isAdmin').where({ user_iduser: req.user.id }).first();
        if (!isAdmin) {
            return res.status(403).json({ error: 'Admin access required' });
        }

        // Validate inputs
        if (!start || !end || !title) {
            return res.status(400).json({ error: 'Missing required parameters' });
        }

        const counts = await db('inapp_events')
            .select(
                db.raw('DATE(date_created) as date'),
                db.raw('COUNT(*) as count')
            )
            .where('title', title)
            .andWhere('date_created', '>=', new Date(start))
            .andWhere('date_created', '<=', new Date(end))
            .groupByRaw('DATE(date_created)')
            .orderBy('date', 'asc');

        res.json(counts);
    } catch (err) {
        console.error('Error fetching event counts:', err);
        res.status(500).json({ error: 'Server error' });
    }
});
module.exports = router;