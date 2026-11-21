const pool = require('./pool');

// Insère une notification en base pour un user (fire-and-forget, n'interrompt jamais la requête principale)
async function notify(userId, { title, body, type }) {
  try {
    await pool.query(
      'INSERT INTO notifications (user_id, title, body, type) VALUES ($1, $2, $3, $4)',
      [userId, title, body, type]
    );
  } catch (err) {
    console.error('notify insert error', err.message);
  }
}

module.exports = notify;
