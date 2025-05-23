const express = require('express');
const bcrypt = require('bcrypt');
const db = require('../db/db');

const router = express.Router();



// PATCH /profile/name
router.patch('/name', async (req, res) => {
  const { name } = req.body;
  const userId = req.user?.iduser;
  console.log('Decoded token user:', req.user);


  if (!name) return res.status(400).send('Name is required');

  try {
    await db('user').where({ iduser: userId }).update({ name });
    res.send('Name updated successfully');
  } catch (error) {
    console.error(error);
    res.status(500).send('Failed to update name');
  }
});

// PATCH /profile/password
router.patch('/password', async (req, res) => {
  const { oldPassword, newPassword } = req.body;
  const userId = req.user?.iduser;

  if (!oldPassword || !newPassword) return res.status(400).send('Old and new password required');

  try {
    const user = await db('user').where({ iduser: userId }).first();
    const isMatch = await bcrypt.compare(oldPassword, user.password);
    if (!isMatch) return res.status(401).send('Incorrect current password');

    const hashed = await bcrypt.hash(newPassword, 10);
    await db('user').where({ iduser: userId }).update({ password: hashed });

    res.send('Password updated successfully');
  } catch (error) {
    console.error(error);
    res.status(500).send('Failed to update password');
  }
});

// PATCH /profile/username
router.patch('/username', async (req, res) => {
  const { username } = req.body;
  const userId = req.user?.iduser;

  if (!username) return res.status(400).send('Username is required');

  // Email validation
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  if (!emailRegex.test(username.trim().toLowerCase())) {
    return res.status(400).send('Invalid email format');
  }

  try {
    const exists = await db('user')
        .where({ username })
        .andWhereNot('iduser', userId)
        .first();

    if (exists) return res.status(409).send('Username already taken');

    await db('user')
        .where({ iduser: userId })
        .update({ username });

    res.send('Username updated successfully');
  } catch (error) {
    console.error(error);
    res.status(500).send('Failed to update username');
  }
});

module.exports = router;
