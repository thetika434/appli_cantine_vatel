const router = require('express').Router();
const { verifyJWT, requireRole } = require('../middleware/auth');

const parent = [verifyJWT, requireRole('parent')];

router.get('/parent/children',               ...parent, async (req, res) => res.status(501).json({ error: 'Not implemented yet' }));
router.get('/parent/children/:student_id',   ...parent, async (req, res) => res.status(501).json({ error: 'Not implemented yet' }));
router.get('/parent/transactions',           ...parent, async (req, res) => res.status(501).json({ error: 'Not implemented yet' }));
router.post('/parent/recharge',              ...parent, async (req, res) => res.status(501).json({ error: 'Not implemented yet' }));

module.exports = router;
