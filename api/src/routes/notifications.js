const router = require('express').Router();
const { verifyJWT } = require('../middleware/auth');
const pool = require('../db/pool');

// ─── GET /api/notifications ───────────────────────────────────────────────────
// Retourne les 30 dernières notifs (lues + non lues) pour le polling mobile
router.get('/notifications', verifyJWT, async (req, res) => {
  try {
    const { rows } = await pool.query(
      `SELECT id, title, body, type, read, created_at
       FROM notifications
       WHERE user_id = $1
       ORDER BY created_at DESC
       LIMIT 30`,
      [req.user.id]
    );
    const unread = rows.filter(n => !n.read).length;
    res.json({ notifications: rows, unread_count: unread });
  } catch (err) {
    console.error('GET /notifications', err);
    res.status(500).json({ error: 'Erreur serveur' });
  }
});

// ─── PATCH /api/notifications/read ───────────────────────────────────────────
// Marque toutes les notifs comme lues
router.patch('/notifications/read', verifyJWT, async (req, res) => {
  try {
    await pool.query(
      'UPDATE notifications SET read = TRUE WHERE user_id = $1 AND read = FALSE',
      [req.user.id]
    );
    res.json({ ok: true });
  } catch (err) {
    console.error('PATCH /notifications/read', err);
    res.status(500).json({ error: 'Erreur serveur' });
  }
});

module.exports = router;
