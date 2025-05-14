const express = require('express')
const path = require('path')
const db = require('./db');
const app = express()




app.use(express.static(path.join(__dirname, '../public')));

app.get('/', (req, res) => {
    res.sendFile(path.join(__dirname, '../public', 'index.html')
    );
})


router.post('/register', async (req, res) => {
    const {Ime, Priimek, email, geslo} = 
    req.body;
    try {
        const hashedPassword = await bcrypt.hash(geslo, 10);
        const query = 'INSERT INTO uporabnik (Ime, Priimek, email, geslo) VALUES (?, ?, ?, ?)';
        db.query(query, [Ime, Priimek, email, hashedPassword], (err, results) => {
            if (err) throw err;
            res.status(201).send('Uporabnik je uspešno registriran');
        });
        } catch (error) {
        res.status(500).send('Error registering user');

        }
    });

router.post('/login', async(req, res) => {
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
                    res.status(401).send('Napačno geslo');
                }
            } else {
                res.status(404).send('Uporabnik ne obstaja');
            }
        });
});








app.listen(3000, () => {
  console.log('Example app listening on port 3000!')
})