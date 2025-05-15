// routes/health.js
const express = require('express');
const jwt = require('jsonwebtoken');
const router = express.Router();
const { authenticateToken } = require('./auth');


const JWT_SECRET = 'your-secret-key';



router.post('/upload-health-metric', authenticateToken);

module.exports = router;
