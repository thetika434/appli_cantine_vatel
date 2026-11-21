const router = require('express').Router();
const { verifyJWT, requireRole } = require('../middleware/auth');

const admin = [verifyJWT, requireRole('admin')];

router.get('/admin/dashboard',           ...admin, async (req, res) => res.status(501).json({ error: 'Not implemented yet' }));
router.get('/admin/orders',              ...admin, async (req, res) => res.status(501).json({ error: 'Not implemented yet' }));
router.patch('/admin/orders/:id/serve',  ...admin, async (req, res) => res.status(501).json({ error: 'Not implemented yet' }));
router.patch('/admin/orders/:id/cancel', ...admin, async (req, res) => res.status(501).json({ error: 'Not implemented yet' }));
router.get('/admin/dishes',              ...admin, async (req, res) => res.status(501).json({ error: 'Not implemented yet' }));
router.post('/admin/dishes',             ...admin, async (req, res) => res.status(501).json({ error: 'Not implemented yet' }));
router.put('/admin/dishes/:id',          ...admin, async (req, res) => res.status(501).json({ error: 'Not implemented yet' }));
router.delete('/admin/dishes/:id',       ...admin, async (req, res) => res.status(501).json({ error: 'Not implemented yet' }));

module.exports = router;
