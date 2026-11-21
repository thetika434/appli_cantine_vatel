const router = require('express').Router();
const { verifyJWT, requireRole } = require('../middleware/auth');
const pool = require('../db/pool');

const admin = [verifyJWT, requireRole('admin')];

// ─── GET /api/admin/dashboard ─────────────────────────────────────────────────
router.get('/admin/dashboard', ...admin, async (req, res) => {
  const date = req.query.date ?? new Date().toISOString().slice(0, 10);
  try {
    // KPI du jour
    const { rows: kpi } = await pool.query(
      `SELECT
         COUNT(*) FILTER (WHERE r.status != 'cancelled')     AS today_orders,
         COALESCE(SUM(d.price_fcfa) FILTER (WHERE r.status != 'cancelled'), 0) AS revenue_fcfa,
         COUNT(*) FILTER (WHERE r.status = 'served')         AS served,
         COUNT(*) FILTER (WHERE r.status = 'cancelled')      AS cancelled
       FROM reservations r
       JOIN dishes d ON d.id = r.dish_id
       WHERE d.serve_date = $1`,
      [date]
    );

    // Revenus des 7 derniers jours
    const { rows: weekly } = await pool.query(
      `SELECT gs.day::text AS date,
              COALESCE(SUM(d.price_fcfa) FILTER (WHERE r.status != 'cancelled'), 0) AS revenue_fcfa,
              COUNT(r.id) FILTER (WHERE r.status != 'cancelled') AS orders
       FROM generate_series(
         ($1::date - INTERVAL '6 days')::date,
         $1::date,
         '1 day'::interval
       ) gs(day)
       LEFT JOIN dishes d ON d.serve_date = gs.day AND d.visible = TRUE
       LEFT JOIN reservations r ON r.dish_id = d.id
       GROUP BY gs.day
       ORDER BY gs.day`,
      [date]
    );

    // Top plats du jour
    const { rows: topDishes } = await pool.query(
      `SELECT d.name, COUNT(*) AS orders
       FROM reservations r
       JOIN dishes d ON d.id = r.dish_id
       WHERE d.serve_date = $1 AND r.status != 'cancelled'
       GROUP BY d.name
       ORDER BY orders DESC
       LIMIT 5`,
      [date]
    );

    // Dernières commandes
    const { rows: recentOrders } = await pool.query(
      `SELECT r.id, u.full_name, u.class, d.name AS dish_name,
              d.price_fcfa, r.status, r.created_at
       FROM reservations r
       JOIN users u ON u.id = r.student_id
       JOIN dishes d ON d.id = r.dish_id
       WHERE d.serve_date = $1
       ORDER BY r.created_at DESC
       LIMIT 20`,
      [date]
    );

    res.json({
      date,
      ...kpi[0],
      weekly,
      top_dishes: topDishes,
      recent_orders: recentOrders,
    });
  } catch (err) {
    console.error('GET /admin/dashboard', err);
    res.status(500).json({ error: 'Erreur serveur' });
  }
});

// ─── GET /api/admin/orders ────────────────────────────────────────────────────
router.get('/admin/orders', ...admin, async (req, res) => {
  const date = req.query.date ?? new Date().toISOString().slice(0, 10);
  try {
    const { rows: summary } = await pool.query(
      `SELECT d.id AS dish_id, d.name, d.price_fcfa,
              COUNT(*) FILTER (WHERE r.status = 'confirmed') AS to_serve,
              COUNT(*) FILTER (WHERE r.status = 'served')    AS served,
              COUNT(*) FILTER (WHERE r.status = 'cancelled') AS cancelled
       FROM dishes d
       LEFT JOIN reservations r ON r.dish_id = d.id
       WHERE d.serve_date = $1 AND d.visible = TRUE
       GROUP BY d.id
       ORDER BY d.name`,
      [date]
    );

    const { rows: orders } = await pool.query(
      `SELECT r.id, u.full_name, u.class, u.matricule,
              d.name AS dish_name, d.price_fcfa, r.status, r.created_at
       FROM reservations r
       JOIN users u ON u.id = r.student_id
       JOIN dishes d ON d.id = r.dish_id
       WHERE d.serve_date = $1
       ORDER BY r.status, u.full_name`,
      [date]
    );

    res.json({ date, summary, orders });
  } catch (err) {
    console.error('GET /admin/orders', err);
    res.status(500).json({ error: 'Erreur serveur' });
  }
});

// ─── PATCH /api/admin/orders/:id/serve ────────────────────────────────────────
router.patch('/admin/orders/:id/serve', ...admin, async (req, res) => {
  try {
    const { rows } = await pool.query(
      `UPDATE reservations SET status = 'served'
       WHERE id = $1 AND status = 'confirmed'
       RETURNING *`,
      [req.params.id]
    );
    if (!rows.length) return res.status(404).json({ error: 'Réservation introuvable ou déjà traitée' });
    res.json({ reservation: rows[0] });
  } catch (err) {
    console.error('PATCH /admin/orders/:id/serve', err);
    res.status(500).json({ error: 'Erreur serveur' });
  }
});

// ─── PATCH /api/admin/orders/:id/cancel ───────────────────────────────────────
// Annule la réservation et rembourse le solde de façon atomique
router.patch('/admin/orders/:id/cancel', ...admin, async (req, res) => {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    const { rows } = await client.query(
      `UPDATE reservations SET status = 'cancelled'
       WHERE id = $1 AND status = 'confirmed'
       RETURNING id, student_id, dish_id`,
      [req.params.id]
    );
    if (!rows.length) {
      await client.query('ROLLBACK');
      return res.status(404).json({ error: 'Réservation introuvable ou déjà traitée' });
    }
    const reservation = rows[0];

    const { rows: dishes } = await client.query(
      'SELECT name, price_fcfa FROM dishes WHERE id = $1',
      [reservation.dish_id]
    );
    const dish = dishes[0];

    // Rembourser le solde
    await client.query(
      'UPDATE student_balances SET balance = balance + $1 WHERE student_id = $2',
      [dish.price_fcfa, reservation.student_id]
    );

    // Remettre la quantité
    await client.query(
      'UPDATE dishes SET quantity = quantity + 1 WHERE id = $1',
      [reservation.dish_id]
    );

    // Écrire la transaction de crédit (remboursement)
    await client.query(
      `INSERT INTO transactions (student_id, type, amount_fcfa, label, reference)
       VALUES ($1, 'credit', $2, $3, $4)`,
      [reservation.student_id, dish.price_fcfa, `Remboursement — ${dish.name}`, String(reservation.id)]
    );

    await client.query('COMMIT');
    res.json({ reservation: { ...reservation, status: 'cancelled' } });
  } catch (err) {
    await client.query('ROLLBACK');
    console.error('PATCH /admin/orders/:id/cancel', err);
    res.status(500).json({ error: 'Erreur serveur' });
  } finally {
    client.release();
  }
});

// ─── GET /api/admin/dishes ────────────────────────────────────────────────────
router.get('/admin/dishes', ...admin, async (req, res) => {
  try {
    const ref = req.query.week ? new Date(req.query.week) : new Date();
    const day = ref.getDay();
    const diffToMonday = day === 0 ? -6 : 1 - day;
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
       ORDER BY serve_date, id`,
      [weekStart, weekEnd]
    );

    const byDate = {};
    for (const dish of rows) {
      if (!byDate[dish.serve_date]) byDate[dish.serve_date] = [];
      byDate[dish.serve_date].push(dish);
    }
    const days = Object.entries(byDate)
      .sort(([a], [b]) => a.localeCompare(b))
      .map(([date, dishes]) => ({ date, dishes }));

    res.json({ week_start: weekStart, week_end: weekEnd, days });
  } catch (err) {
    console.error('GET /admin/dishes', err);
    res.status(500).json({ error: 'Erreur serveur' });
  }
});

// ─── POST /api/admin/dishes ───────────────────────────────────────────────────
router.post('/admin/dishes', ...admin, async (req, res) => {
  const { name, description, photo_url, price_fcfa, serve_date, quantity, visible } = req.body ?? {};
  if (!name || !price_fcfa || !serve_date || quantity === undefined) {
    return res.status(400).json({ error: 'Champs requis : name, price_fcfa, serve_date, quantity' });
  }
  if (!Number.isInteger(price_fcfa) || price_fcfa <= 0 || price_fcfa % 5 !== 0) {
    return res.status(400).json({ error: 'price_fcfa invalide' });
  }
  try {
    const { rows } = await pool.query(
      `INSERT INTO dishes (name, description, photo_url, price_fcfa, serve_date, quantity, visible)
       VALUES ($1, $2, $3, $4, $5, $6, $7)
       RETURNING *`,
      [name, description ?? null, photo_url ?? null, price_fcfa, serve_date,
       quantity, visible !== false]
    );
    res.status(201).json({ dish: rows[0] });
  } catch (err) {
    console.error('POST /admin/dishes', err);
    res.status(500).json({ error: 'Erreur serveur' });
  }
});

// ─── PUT /api/admin/dishes/:id ────────────────────────────────────────────────
router.put('/admin/dishes/:id', ...admin, async (req, res) => {
  const fields = ['name', 'description', 'photo_url', 'price_fcfa', 'serve_date',
                  'slot_start', 'slot_end', 'quantity', 'visible'];
  const updates = [];
  const values = [];
  let idx = 1;

  for (const f of fields) {
    if (req.body[f] !== undefined) {
      updates.push(`${f} = $${idx++}`);
      values.push(req.body[f]);
    }
  }
  if (!updates.length) return res.status(400).json({ error: 'Aucun champ à mettre à jour' });
  values.push(req.params.id);

  try {
    const { rows } = await pool.query(
      `UPDATE dishes SET ${updates.join(', ')} WHERE id = $${idx} RETURNING *`,
      values
    );
    if (!rows.length) return res.status(404).json({ error: 'Plat introuvable' });
    res.json({ dish: rows[0] });
  } catch (err) {
    console.error('PUT /admin/dishes/:id', err);
    res.status(500).json({ error: 'Erreur serveur' });
  }
});

// ─── DELETE /api/admin/dishes/:id ─────────────────────────────────────────────
router.delete('/admin/dishes/:id', ...admin, async (req, res) => {
  try {
    const { rowCount } = await pool.query('DELETE FROM dishes WHERE id = $1', [req.params.id]);
    if (!rowCount) return res.status(404).json({ error: 'Plat introuvable' });
    res.sendStatus(204);
  } catch (err) {
    console.error('DELETE /admin/dishes/:id', err);
    res.status(500).json({ error: 'Erreur serveur' });
  }
});

module.exports = router;
