const jwt = require('jsonwebtoken');
const JWT_SECRET = process.env.JWT_SECRET + "analytics";

function authenticateToken(req, res, next) {
    const authHeader = req.headers['authorization'];
    const token = authHeader?.split(' ')[1];

    if (!token) return res.sendStatus(401);

    jwt.verify(token, JWT_SECRET, (err, user) => {
        if (err) return res.sendStatus(403);

        req.user = user; // { iduser, username }
        next();
    });
}

module.exports = { authenticateToken, JWT_SECRET };