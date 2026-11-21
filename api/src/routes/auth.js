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

// ─── POST /api/auth/register ─────────────────────────────────────────────────
// Inscription libre depuis l'app mobile (élève ou parent).
router.post('/auth/register', async (req, res) => {
  const body = req.body ?? {};
  const role = body.role;
  const fullName = typeof body.full_name === 'string' ? body.full_name.trim() : '';
  const password = typeof body.password === 'string' ? body.password : '';
  const str = (v) => (typeof v === 'string' ? v.trim() : '');

  if (!['student', 'parent'].includes(role)) {
    return res.status(400).json({ error: 'Rôle invalide.' });
  }
  if (fullName.length < 3 || fullName.length > 100) {
    return res.status(400).json({ error: 'Le nom complet doit faire entre 3 et 100 caractères.' });
  }
  if (password.length < 6) {
    return res.status(400).json({ error: 'Le mot de passe doit faire au moins 6 caractères.' });
  }

  let matricule, phone, className = null, childMatricule = null;
  if (role === 'student') {
    matricule = str(body.matricule).toUpperCase();
    className = str(body.class);
    phone = str(body.phone) || null;
    if (!matricule || matricule.length > 30) {
      return res.status(400).json({ error: 'Matricule invalide.' });
    }
    if (!className || className.length > 20) {
      return res.status(400).json({ error: 'Classe invalide (20 caractères maximum).' });
    }
    if (phone && phone.length > 20) {
      return res.status(400).json({ error: 'Numéro de téléphone invalide.' });
    }
  } else {
    phone = str(body.phone).replace(/[\s.\-]/g, '');
    if (/^0\d{9}$/.test(phone)) phone = `+225${phone}`;
    childMatricule = str(body.child_matricule).toUpperCase();
    if (!/^\+225\d{10}$/.test(phone)) {
      return res.status(400).json({ error: 'Numéro de téléphone invalide (ex : 07 00 00 00 00).' });
    }
    if (!childMatricule) {
      return res.status(400).json({ error: "Matricule de l'enfant requis." });
    }
    matricule = phone;
  }

  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    const exists = await client.query('SELECT 1 FROM users WHERE matricule = $1', [matricule]);
    if (exists.rows.length) {
      await client.query('ROLLBACK');
      return res.status(409).json({
        error: role === 'student' ? 'Ce matricule est déjà utilisé.' : 'Ce numéro est déjà utilisé.',
      });
    }

    let childId = null;
    if (role === 'parent') {
      const child = await client.query(
        "SELECT id FROM users WHERE matricule = $1 AND role = 'student'",
        [childMatricule]
      );
      if (!child.rows.length) {
        await client.query('ROLLBACK');
        return res.status(404).json({ error: 'Aucun élève avec ce matricule.' });
      }
      childId = child.rows[0].id;
    }

    const hash = await bcrypt.hash(password, 10);
    const { rows } = await client.query(
      `INSERT INTO users (matricule, password_hash, role, full_name, class, phone)
       VALUES ($1, $2, $3, $4, $5, $6)
       RETURNING id, role, full_name, class`,
      [matricule, hash, role, fullName, className, phone]
    );
    const user = rows[0];

    if (role === 'student') {
      await client.query('INSERT INTO student_balances (student_id, balance) VALUES ($1, 0)', [user.id]);
    } else {
      await client.query(
        'INSERT INTO parent_children (parent_id, student_id) VALUES ($1, $2)',
        [user.id, childId]
      );
    }

    await client.query('COMMIT');

    const token = jwt.sign({ id: user.id, role: user.role }, process.env.JWT_SECRET, { expiresIn: '7d' });
    res.status(201).json({ token, user });
  } catch (err) {
    await client.query('ROLLBACK').catch(() => {});
    if (err.code === '23505') {
      return res.status(409).json({ error: 'Ce compte existe déjà.' });
    }
    console.error('POST /auth/register', err);
    res.status(500).json({ error: 'Erreur serveur' });
  } finally {
    client.release();
  }
});

module.exports = router;
