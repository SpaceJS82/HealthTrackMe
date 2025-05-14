// routes/friends.js
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

router.get('/send-friend-request', simpleAuthCheck);
router.get('/approve-friend-request', simpleAuthCheck);
router.get('/decline-friend-request', simpleAuthCheck);
router.get('/get-friends', simpleAuthCheck);
router.get('/get-friend-data', simpleAuthCheck);

module.exports = router;
