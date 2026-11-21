const router = require('express').Router();
const crypto = require('crypto');
const pool = require('../db/pool');
const notify = require('../db/notify');

// POST /api/webhooks/adullam
// express.raw() est monté dans app.js — req.body est un Buffer ici
router.post('/webhooks/adullam', async (req, res) => {
  // 1. Vérification HMAC-SHA256 en temps constant
  const signature = req.headers['adullam-signature'];
  if (!signature) return res.status(401).json({ error: 'Signature manquante' });

  const expected = crypto
    .createHmac('sha256', process.env.ADULLAM_WEBHOOK_SECRET)
    .update(req.body) // Buffer brut
    .digest('hex');

  let sigValid = false;
  try {
    sigValid = crypto.timingSafeEqual(
      Buffer.from(signature, 'hex'),
      Buffer.from(expected, 'hex')
    );
  } catch {
    sigValid = false;
  }

  if (!sigValid) return res.status(401).json({ error: 'Signature invalide' });

  // 2. Répondre 200 IMMÉDIATEMENT
  res.sendStatus(200);

  // 3. Traitement asynchrone
  try {
    const payload = JSON.parse(req.body.toString());

    if (payload.status !== 'completed') return;

    const paymentId = payload.id ?? payload.payment_id ?? payload.data?.id;
    if (!paymentId) return;

    // 4. Déduplication : si déjà processed_at, s'arrêter
    const { rows } = await pool.query(
      'SELECT id, student_id, amount_fcfa, processed_at FROM recharges WHERE payment_id = $1',
      [paymentId]
    );
    if (!rows.length || rows[0].processed_at) return;

    const recharge = rows[0];

    // 5. Crédit atomique
    const client = await pool.connect();
    try {
      await client.query('BEGIN');

      await client.query(
        `UPDATE recharges SET status = 'completed', processed_at = NOW()
         WHERE id = $1 AND processed_at IS NULL`,
        [recharge.id]
      );

      await client.query(
        'UPDATE student_balances SET balance = balance + $1 WHERE student_id = $2',
        [recharge.amount_fcfa, recharge.student_id]
      );

      await client.query(
        `INSERT INTO transactions (student_id, type, amount_fcfa, label, reference)
         VALUES ($1, 'credit', $2, 'Recharge mobile money', $3)`,
        [recharge.student_id, recharge.amount_fcfa, paymentId]
      );

      await client.query('COMMIT');

      // Notifier l'élève
      notify(recharge.student_id, {
        title: '💰 Solde rechargé',
        body: `${recharge.amount_fcfa} FCFA ont été ajoutés à votre solde.`,
        type: 'recharge',
      });

      // Notifier le parent s'il a initié la recharge
      const { rows: rechRow } = await pool.query(
        'SELECT initiated_by FROM recharges WHERE id = $1',
        [recharge.id]
      );
      if (rechRow.length && rechRow[0].initiated_by !== recharge.student_id) {
        notify(rechRow[0].initiated_by, {
          title: '💰 Recharge effectuée',
          body: `La recharge de ${recharge.amount_fcfa} FCFA pour votre enfant a été créditée.`,
          type: 'recharge',
        });
      }
    } catch (err) {
      await client.query('ROLLBACK');
      console.error('webhook credit ROLLBACK', err);
    } finally {
      client.release();
    }
  } catch (err) {
    console.error('webhook processing error', err);
  }
});

module.exports = router;
