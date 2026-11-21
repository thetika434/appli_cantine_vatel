const router = require('express').Router();
const { verifyJWT, requireRole } = require('../middleware/auth');
const pool = require('../db/pool');

const student = [verifyJWT, requireRole('student')];

// ─── GET /api/me ─── tous rôles ───────────────────────────────────────────────
router.get('/me', verifyJWT, async (req, res) => {
  try {
    const { rows } = await pool.query(
      'SELECT id, matricule, role, full_name, class, phone FROM users WHERE id = $1',
      [req.user.id]
    );
    if (!rows.length) return res.status(404).json({ error: 'Utilisateur introuvable' });

    const user = rows[0];
    let balance = null;

    if (user.role === 'student') {
      const bal = await pool.query(
        'SELECT balance FROM student_balances WHERE student_id = $1',
        [user.id]
      );
      balance = bal.rows[0]?.balance ?? 0;
    }

    res.json({ user, balance });
  } catch (err) {
    console.error('GET /me', err);
    res.status(500).json({ error: 'Erreur serveur' });
  }
});

// ─── GET /api/menus/week ──────────────────────────────────────────────────────
router.get('/menus/week', ...student, async (req, res) => {
  res.status(501).json({ error: 'Not implemented yet' });
});

// ─── GET /api/dishes/:id ──────────────────────────────────────────────────────
router.get('/dishes/:id', ...student, async (req, res) => {
  res.status(501).json({ error: 'Not implemented yet' });
});

// ─── POST /api/reservations ───────────────────────────────────────────────────
router.post('/reservations', ...student, async (req, res) => {
  res.status(501).json({ error: 'Not implemented yet' });
});

// ─── GET /api/reservations ────────────────────────────────────────────────────
router.get('/reservations', ...student, async (req, res) => {
  res.status(501).json({ error: 'Not implemented yet' });
});

// ─── GET /api/transactions ────────────────────────────────────────────────────
router.get('/transactions', ...student, async (req, res) => {
  res.status(501).json({ error: 'Not implemented yet' });
});

// ─── POST /api/recharge/initiate ──────────────────────────────────────────────
router.post('/recharge/initiate', ...student, async (req, res) => {
  res.status(501).json({ error: 'Not implemented yet' });
});

module.exports = router;
