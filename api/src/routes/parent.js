const router = require('express').Router();
const { verifyJWT, requireRole } = require('../middleware/auth');
const pool = require('../db/pool');

const parent = [verifyJWT, requireRole('parent')];

// Utilitaire : vérifier qu'un student_id appartient bien au parent authentifié
async function assertChildOf(parentId, studentId) {
  const { rows } = await pool.query(
    'SELECT 1 FROM parent_children WHERE parent_id=$1 AND student_id=$2',
    [parentId, studentId]
  );
  return rows.length > 0;
}

// ─── GET /api/parent/children ─────────────────────────────────────────────────
router.get('/parent/children', ...parent, async (req, res) => {
  try {
    const { rows } = await pool.query(
      `SELECT u.id, u.full_name, u.class, u.matricule, sb.balance
       FROM parent_children pc
       JOIN users u ON u.id = pc.student_id
       LEFT JOIN student_balances sb ON sb.student_id = u.id
       WHERE pc.parent_id = $1
       ORDER BY u.full_name`,
      [req.user.id]
    );
    res.json({ children: rows });
  } catch (err) {
    console.error('GET /parent/children', err);
    res.status(500).json({ error: 'Erreur serveur' });
  }
});

// ─── GET /api/parent/children/:student_id ─────────────────────────────────────
router.get('/parent/children/:student_id', ...parent, async (req, res) => {
  try {
    const studentId = parseInt(req.params.student_id, 10);
    if (!(await assertChildOf(req.user.id, studentId))) {
      return res.status(403).json({ error: 'Accès refusé' });
    }

    const { rows: users } = await pool.query(
      `SELECT u.id, u.full_name, u.class, u.matricule, sb.balance
       FROM users u
       LEFT JOIN student_balances sb ON sb.student_id = u.id
       WHERE u.id = $1`,
      [studentId]
    );
    if (!users.length) return res.status(404).json({ error: 'Élève introuvable' });

    const { rows: transactions } = await pool.query(
      `SELECT id, type, amount_fcfa, label, reference, created_at
       FROM transactions
       WHERE student_id = $1
       ORDER BY created_at DESC
       LIMIT 10`,
      [studentId]
    );

    res.json({ student: users[0], balance: users[0].balance, recent_transactions: transactions });
  } catch (err) {
    console.error('GET /parent/children/:id', err);
    res.status(500).json({ error: 'Erreur serveur' });
  }
});

// ─── GET /api/parent/transactions ─────────────────────────────────────────────
router.get('/parent/transactions', ...parent, async (req, res) => {
  try {
    // Récupérer les IDs des enfants du parent
    const { rows: children } = await pool.query(
      'SELECT student_id FROM parent_children WHERE parent_id = $1',
      [req.user.id]
    );
    if (!children.length) return res.json({ transactions: [] });

    const childIds = children.map(c => c.student_id);

    // Filtre optionnel sur un enfant précis
    const { student_id } = req.query;
    let ids = childIds;
    if (student_id) {
      const sid = parseInt(student_id, 10);
      if (!childIds.includes(sid)) {
        return res.status(403).json({ error: 'Accès refusé' });
      }
      ids = [sid];
    }

    const placeholders = ids.map((_, i) => `$${i + 1}`).join(',');
    const { rows } = await pool.query(
      `SELECT t.id, t.student_id, u.full_name AS student_name,
              t.type, t.amount_fcfa, t.label, t.reference, t.created_at
       FROM transactions t
       JOIN users u ON u.id = t.student_id
       WHERE t.student_id IN (${placeholders})
       ORDER BY t.created_at DESC`,
      ids
    );
    res.json({ transactions: rows });
  } catch (err) {
    console.error('GET /parent/transactions', err);
    res.status(500).json({ error: 'Erreur serveur' });
  }
});

// ─── POST /api/parent/recharge ────────────────────────────────────────────────
router.post('/parent/recharge', ...parent, async (req, res) => {
  const { student_id, amount, phone, channel } = req.body ?? {};

  if (!student_id || !amount || !phone || !channel) {
    return res.status(400).json({ error: 'Champs requis : student_id, amount, phone, channel' });
  }
  if (!Number.isInteger(amount) || amount <= 0 || amount % 5 !== 0) {
    return res.status(400).json({ error: 'Montant invalide' });
  }
  const CHANNELS = ['orangeCI', 'mtnCI', 'moovCI', 'waveCI'];
  if (!CHANNELS.includes(channel)) {
    return res.status(400).json({ error: 'Canal invalide' });
  }

  try {
    if (!(await assertChildOf(req.user.id, student_id))) {
      return res.status(403).json({ error: 'Accès refusé' });
    }

    const { v4: uuidv4 } = require('uuid');
    const idempotencyKey = uuidv4();

    const normalizedPhone = phone.startsWith('+') ? phone : `+225${phone}`;

    const aduRes = await fetch('https://api.adullam.dev/v1/payments', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'x-auth': process.env.ADULLAM_KEY,
        'x-idempotency-key': idempotencyKey,
      },
      body: JSON.stringify({
        amount,
        currency: 'xof',
        customer_phone: normalizedPhone,
        channel,
        description: 'Recharge cantine Vatel',
      }),
    });

    const aduData = await aduRes.json();
    if (!aduRes.ok) {
      return res.status(502).json({ error: 'Erreur paiement', detail: aduData });
    }

    const paymentId = aduData.id ?? aduData.payment_id ?? aduData.data?.id;

    await pool.query(
      `INSERT INTO recharges
         (student_id, initiated_by, payment_id, idempotency_key, amount_fcfa, phone, channel)
       VALUES ($1, $2, $3, $4, $5, $6, $7)`,
      [student_id, req.user.id, paymentId, idempotencyKey, amount, phone, channel]
    );

    const extra = {};
    if (aduData.redirect_url) extra.redirect_url = aduData.redirect_url;
    if (aduData.ussd)         extra.ussd          = aduData.ussd;

    res.json({ payment_id: paymentId, status: 'pending', ...extra });
  } catch (err) {
    console.error('POST /parent/recharge', err);
    res.status(500).json({ error: 'Erreur serveur' });
  }
});

module.exports = router;
