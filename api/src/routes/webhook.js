const router = require('express').Router();

// POST /api/webhooks/adullam
// express.raw() est monté dans app.js AVANT express.json() — req.body est un Buffer ici
router.post('/webhooks/adullam', async (req, res) => {
  res.status(501).json({ error: 'Not implemented yet' });
});

module.exports = router;
