const express = require('express');
const path = require('path');
const bcrypt = require('bcrypt'); // Import bcrypt
const db = require('./db'); // Import the Knex instance

const app = express();
const router = express.Router();

app.use(express.static(path.join(__dirname, '../public'))); // Adjust the path as necessary
app.use(express.json()); // Middleware to parse JSON bodies

// Serve the login page
app.get('/login.html', (req, res) => {
    res.sendFile(path.join(__dirname, '../public', 'login.html'));
});

// Handle login POST request
router.post('/login', async (req, res) => {
  const { username, password } = req.body;

  try {
    // Find the user by username
    const users = await db('user').where({ username });
    if (users.length === 0) {
      return res.status(404).send('User not found');
    }

    const user = users[0];

    // Compare the provided password with the stored hash
    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch) {
      return res.status(401).send('Incorrect password');
    }

    // If the username and password are correct, send a success response
    res.status(200).send('Login successful');
  } catch (error) {
    console.error(error);
    res.status(500).send('Error logging in');
  }
});

app.use(router);

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Server is running on port ${PORT}`);
});
