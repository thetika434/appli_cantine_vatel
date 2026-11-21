const router = require('express').Router();

// POST /api/auth/login
router.post('/auth/login', async (req, res) => {
  res.status(501).json({ error: 'Not implemented yet' });
});

module.exports = router;
