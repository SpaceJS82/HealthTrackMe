const express = require('express');
const path = require('path');
const bcrypt = require('bcrypt');
const db = require('./db'); // Knex instance

const app = express();
const router = express.Router();

app.use(express.static(path.join(__dirname, '../public'))); // Static files (HTML, CSS, JS)
app.use(express.json()); // Parse JSON request bodies

// Serve login page
app.get('/login.html', (req, res) => {
    res.sendFile(path.join(__dirname, '../public', 'login.html'));
});

// Serve register page (optional if you have one)
app.get('/register.html', (req, res) => {
    res.sendFile(path.join(__dirname, '../public', 'register.html'));
});

// Handle login POST request
router.post('/login', async (req, res) => {
    const { username, password } = req.body;

    try {
        const users = await db('user').where({ username });
        if (users.length === 0) {
            return res.status(404).send('User not found');
        }

        const user = users[0];

        const isMatch = await bcrypt.compare(password, user.password);
        if (!isMatch) {
            return res.status(401).send('Incorrect password');
        }

        res.status(200).send('Login successful');
    } catch (error) {
        console.error(error);
        res.status(500).send('Error logging in');
    }
});

// Handle register POST request
router.post('/register', async (req, res) => {
  const { username, password, name } = req.body; // Dodano: name

  try {
    const existingUsers = await db('user').where({ username });
    if (existingUsers.length > 0) {
      return res.status(409).send('Username already taken');
    }

    const saltRounds = 10;
    const hashedPassword = await bcrypt.hash(password, saltRounds);

    await db('user').insert({
      username,
      password: hashedPassword,
      name // Dodano
    });

    res.status(201).send('User registered successfully');
  } catch (error) {
    console.error(error);
    res.status(500).send('Error registering user');
  }
});


app.use(router);

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
    console.log(`Server is running on port ${PORT}`);
});
