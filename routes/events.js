// routes/events.js
const express = require('express');
const jwt = require('jsonwebtoken');
const router = express.Router();

const JWT_SECRET = 'your-secret-key';

const simpleAuthCheck = (req, res) => {
  const token = req.headers['authorization']?.split(' ')[1];
  if (!token) return res.send('no');

  jwt.verify(token, JWT_SECRET, (err) => {
    if (err) return res.send('no');
    res.send('yes');
  });
};

router.get('/get-events', simpleAuthCheck);
router.get('/get-event-reactions', simpleAuthCheck);
router.get('/react-to-event', simpleAuthCheck);
router.post('/upload-event', simpleAuthCheck);

module.exports = router;
