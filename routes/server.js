const express = require('express');
const session = require('express-session');
const path = require('path');
const bcrypt = require('bcrypt');
const db = require('./db'); // Knex instance

const app = express();
const router = express.Router();

app.use(express.static(path.join(__dirname, '../public'))); // Adjust the path as necessary
app.use(express.json()); // Middleware to parse JSON bodies

app.use(session({
  secret: 'your-secret-key', // Change this to a secure secret key
  resave: false,
  saveUninitialized: true,
  cookie: { secure: false } // Set to true if using HTTPS
}));

router.get('/check-session', (req, res) => {
  res.json(req.session.user || 'No session');
});

// Serve login page


// Handle login POST request
router.post('/login', async (req, res) => {
    const { username, password } = req.body;

    try {
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

    req.session.user = {
            id: user.iduser,
            username: user.username,
            name: user.name
        };


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
