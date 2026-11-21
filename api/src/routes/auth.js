const router = require('express').Router();
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const pool = require('../db/pool');

router.post('/auth/login', async (req, res) => {
  const { matricule, password } = req.body ?? {};

  if (!matricule || !password) {
    return res.status(400).json({ error: 'Champs requis : matricule, password' });
  }

  try {
    const { rows } = await pool.query(
      'SELECT id, password_hash, role, full_name, class FROM users WHERE matricule = $1',
      [matricule]
    );

    if (!rows.length) {
      return res.status(401).json({ error: 'Identifiants invalides' });
    }

    const user = rows[0];
    const valid = await bcrypt.compare(password, user.password_hash);
    if (!valid) {
      return res.status(401).json({ error: 'Identifiants invalides' });
    }

    const token = jwt.sign(
      { id: user.id, role: user.role },
      process.env.JWT_SECRET,
      { expiresIn: '7d' }
    );

    res.json({
      token,
      user: {
        id: user.id,
        role: user.role,
        full_name: user.full_name,
        class: user.class,
      },
    });
  } catch (err) {
    console.error('POST /auth/login', err);
    res.status(500).json({ error: 'Erreur serveur' });
  }
});

module.exports = router;
