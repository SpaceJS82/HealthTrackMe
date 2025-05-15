// routes/friends.js
const express = require('express');
const jwt = require('jsonwebtoken');
const router = express.Router();
const { authenticateToken } = require('./auth');


const JWT_SECRET = 'your-secret-key';

const simpleAuthCheck = (req, res) => {
  const token = req.headers['authorization']?.split(' ')[1];
  if (!token) return res.send('no');

  jwt.verify(token, JWT_SECRET, (err) => {
    if (err) return res.send('no');
    res.send('yes');
  });
};


router.get('/get-friends', authenticateToken);
router.get('/get-friend-data', simpleAuthCheck);
router.get('/delete-friendship', authenticateToken);

module.exports = router;
