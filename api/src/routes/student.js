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
  try {
    // Calculer lundi et vendredi de la semaine demandée
    const ref = req.query.date ? new Date(req.query.date) : new Date();
    const day = ref.getDay(); // 0=dim, 1=lun…
    const diffToMonday = (day === 0 ? -6 : 1 - day);
    const monday = new Date(ref);
    monday.setDate(ref.getDate() + diffToMonday);
    const friday = new Date(monday);
    friday.setDate(monday.getDate() + 4);

    const weekStart = monday.toISOString().slice(0, 10);
    const weekEnd   = friday.toISOString().slice(0, 10);

    const { rows } = await pool.query(
      `SELECT id, name, description, photo_url, price_fcfa,
              serve_date::text, slot_start::text, slot_end::text, quantity, visible
       FROM dishes
       WHERE serve_date BETWEEN $1 AND $2
         AND visible = TRUE
       ORDER BY serve_date, slot_start, id`,
      [weekStart, weekEnd]
    );

    // Regrouper par date
    const byDate = {};
    for (const dish of rows) {
      const d = dish.serve_date;
      if (!byDate[d]) byDate[d] = [];
      byDate[d].push(dish);
    }

    const days = Object.entries(byDate)
      .sort(([a], [b]) => a.localeCompare(b))
      .map(([date, dishes]) => ({ date, dishes }));

    res.json({ week_start: weekStart, week_end: weekEnd, days });
  } catch (err) {
    console.error('GET /menus/week', err);
    res.status(500).json({ error: 'Erreur serveur' });
  }
});

// ─── GET /api/dishes/:id ──────────────────────────────────────────────────────
router.get('/dishes/:id', ...student, async (req, res) => {
  try {
    const { rows } = await pool.query(
      `SELECT id, name, description, photo_url, price_fcfa,
              serve_date::text, slot_start::text, slot_end::text, quantity, visible
       FROM dishes WHERE id = $1`,
      [req.params.id]
    );
    if (!rows.length) return res.status(404).json({ error: 'Plat introuvable' });
    res.json({ dish: rows[0] });
  } catch (err) {
    console.error('GET /dishes/:id', err);
    res.status(500).json({ error: 'Erreur serveur' });
  }
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
