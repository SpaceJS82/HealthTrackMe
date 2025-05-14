const express = require('express');
const bcrypt = require('bcrypt');
const db = require('../db');

const router = express.Router();



router.post('/register', async (req, res) => {
        const {Ime, Priimek, email, geslo} =
        req.body;
        try {

            const hashedPassword = await bcrypt.hash(geslo, 10);
            const query = 'INSERT INTO uporabnik (Ime, Priimek, email, geslo) VALUES (?, ?, ?, ?)';
            db.query(query, [Ime, Priimek, email, hashedPassword], (err, results) => {
                if (err) throw err;
                res.status(201).json({message: 'Uporabnik je uspešno registriran'});
            });
        } catch (error) {
            res.status(500).send('Error registering user');
        }
});
module.exports = router;

router.post('/login', (req, res) => {
    const {email, geslo} = req.body;
    const query = 'SELECT * FROM uporabnik WHERE email = ?';
    db.query(query, [email], async (err, results) => {
        if (err) throw err;
        if (results.length > 0) {
            const user = results[0];

            const isMatch = await bcrypt.compare(geslo, user.geslo);

            if (isMatch) {
                res.status(200).send('Prijava uspešna');	
            } else {
                res.status(401).send('Napačno geslo');}
            } else {
                res.status(404).send('Uporabnik ne obstaja');
            }
        }
    );
});

module.exports = router;