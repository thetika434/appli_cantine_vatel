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

// ─── POST /api/reservations (transaction SQL atomique) ────────────────────────
router.post('/reservations', ...student, async (req, res) => {
  const { dish_id } = req.body ?? {};
  if (!dish_id) return res.status(400).json({ error: 'dish_id requis' });

  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    // Vérifier que le plat existe et est visible
    const { rows: dishes } = await client.query(
      'SELECT id, name, price_fcfa, quantity FROM dishes WHERE id = $1 AND visible = TRUE',
      [dish_id]
    );
    if (!dishes.length) {
      await client.query('ROLLBACK');
      return res.status(404).json({ error: 'Plat introuvable' });
    }
    const dish = dishes[0];

    // Verrouiller et lire le solde
    const { rows: balRows } = await client.query(
      'SELECT balance FROM student_balances WHERE student_id = $1 FOR UPDATE',
      [req.user.id]
    );
    const balance = balRows[0]?.balance ?? 0;

    if (balance < dish.price_fcfa) {
      await client.query('ROLLBACK');
      return res.status(422).json({ error: 'Solde insuffisant' });
    }

    // Décrémenter la quantité — 0 lignes → épuisé
    const { rowCount } = await client.query(
      'UPDATE dishes SET quantity = quantity - 1 WHERE id = $1 AND quantity > 0',
      [dish_id]
    );
    if (rowCount === 0) {
      await client.query('ROLLBACK');
      return res.status(409).json({ error: 'Plat épuisé' });
    }

    // Insérer la réservation (UNIQUE student_id+dish_id → doublon → catch)
    const { rows: resRows } = await client.query(
      `INSERT INTO reservations (student_id, dish_id)
       VALUES ($1, $2)
       RETURNING id, student_id, dish_id, status, created_at`,
      [req.user.id, dish_id]
    );
    const reservation = resRows[0];

    // Débiter le solde
    const { rows: newBalRows } = await client.query(
      `UPDATE student_balances SET balance = balance - $1
       WHERE student_id = $2
       RETURNING balance`,
      [dish.price_fcfa, req.user.id]
    );
    const newBalance = newBalRows[0].balance;

    // Écrire la transaction
    await client.query(
      `INSERT INTO transactions (student_id, type, amount_fcfa, label, reference)
       VALUES ($1, 'debit', $2, $3, $4)`,
      [req.user.id, dish.price_fcfa, dish.name, String(reservation.id)]
    );

    await client.query('COMMIT');
    res.json({ reservation, new_balance: newBalance });
  } catch (err) {
    await client.query('ROLLBACK');
    if (err.code === '23505') { // unique_violation
      return res.status(409).json({ error: 'Déjà réservé' });
    }
    if (err.code === '23514') { // check_violation (balance >= 0)
      return res.status(422).json({ error: 'Solde insuffisant' });
    }
    console.error('POST /reservations', err);
    res.status(500).json({ error: 'Erreur serveur' });
  } finally {
    client.release();
  }
});

// ─── GET /api/reservations ────────────────────────────────────────────────────
router.get('/reservations', ...student, async (req, res) => {
  try {
    const { rows } = await pool.query(
      `SELECT r.id, r.dish_id, d.name AS dish_name, d.price_fcfa,
              d.serve_date::text, r.status, r.created_at
       FROM reservations r
       JOIN dishes d ON d.id = r.dish_id
       WHERE r.student_id = $1
       ORDER BY r.created_at DESC`,
      [req.user.id]
    );
    res.json({ reservations: rows });
  } catch (err) {
    console.error('GET /reservations', err);
    res.status(500).json({ error: 'Erreur serveur' });
  }
});

// ─── GET /api/transactions ────────────────────────────────────────────────────
router.get('/transactions', ...student, async (req, res) => {
  try {
    const { type } = req.query;
    const params = [req.user.id];
    let where = 'WHERE student_id = $1';
    if (type === 'debit' || type === 'credit') {
      where += ' AND type = $2';
      params.push(type);
    }
    const { rows } = await pool.query(
      `SELECT id, type, amount_fcfa, label, reference, created_at
       FROM transactions ${where}
       ORDER BY created_at DESC`,
      params
    );
    res.json({ transactions: rows });
  } catch (err) {
    console.error('GET /transactions', err);
    res.status(500).json({ error: 'Erreur serveur' });
  }
});

// ─── POST /api/recharge/initiate ──────────────────────────────────────────────
router.post('/recharge/initiate', ...student, async (req, res) => {
  res.status(501).json({ error: 'Not implemented yet' });
});

module.exports = router;
