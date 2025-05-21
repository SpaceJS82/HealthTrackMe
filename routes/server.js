const express = require('express');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const db = require('./db'); // Knex instance
const path = require('path');

const app = express();
const router = express.Router();

const friendsRoutes = require('./friends');
const eventsRoutes = require('./events');
const healthRoutes = require('./health');
const profileRoutes = require('./profile');
const inviteRoutes = require('./invites');
const {authenticateToken} = require("./auth");

// Middleware to parse JSON bodies
app.use(express.static(path.join(__dirname, '../public'))); 
app.use(express.json());

// Secret key for JWT signing
const JWT_SECRET = process.env.JWT_SECRET;
 // Change to a more secure secret in production

// Serve login page (optional, as you might just return an API response)

router.get("/check-connectivity", async (req, res) => {
    res.json(200);
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

    // Compare the provided password with the stored hash
    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch) {
      return res.status(401).send('Incorrect password');
    }

    // Create a JWT token and send it to the client
    const token = jwt.sign(
      { id: user.iduser, username: user.username, name: user.name },
      JWT_SECRET,
      { expiresIn: '15m' } // Token expires in 15 min
    );

    res.status(200).json({
      token,
      user: {
        id: user.iduser,
        username: user.username,
        name: user.name
      }
    });
  } catch (error) {
    console.error(error);
    res.status(500).send('Error logging in');
  }
});

// Handle register POST request
router.post('/register', async (req, res) => {
  const { username, password, name } = req.body;

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
      name
    });

    res.status(201).send('User registered successfully');
  } catch (error) {
    console.error(error);
    res.status(500).send('Error registering user');
  }
});

// Middleware to verify JWT token
const verifyToken = async (req, res, next) => {
  const authHeader = req.headers["authorization"];
  const token = authHeader && authHeader.split(" ")[1];

  if (!token) return res.sendStatus(401);

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);

    const user = await db("user").where({ iduser: decoded.id }).first();
    if (!user) {
      return res.status(403).json({ error: "User no longer exists" });
    }

    req.user = user;
    next();
  } catch (err) {
    console.error("❌ Token error:", err.message);
    return res.status(403).json({ error: "Invalid or expired token" });
  }
};

// Route to check if the user is authenticated
router.get('/check-auth', verifyToken, (req, res) => {
  res.status(200).json({ user: req.user });
});

app.use(router);



// All /profile routes are protected
app.use('/profile', verifyToken, profileRoutes);
app.use('/friends', friendsRoutes);
app.use('/events', eventsRoutes);
app.use('/health', healthRoutes);

app.use('/invites', inviteRoutes);

module.exports = router;

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Server is running on port ${PORT}`);
});

