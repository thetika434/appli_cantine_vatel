const router = require('express').Router();
const { verifyJWT, requireRole } = require('../middleware/auth');

const student = [verifyJWT, requireRole('student')];

router.get('/me',                    verifyJWT,  async (req, res) => res.status(501).json({ error: 'Not implemented yet' }));
router.get('/menus/week',            ...student, async (req, res) => res.status(501).json({ error: 'Not implemented yet' }));
router.get('/dishes/:id',            ...student, async (req, res) => res.status(501).json({ error: 'Not implemented yet' }));
router.post('/reservations',         ...student, async (req, res) => res.status(501).json({ error: 'Not implemented yet' }));
router.get('/reservations',          ...student, async (req, res) => res.status(501).json({ error: 'Not implemented yet' }));
router.get('/transactions',          ...student, async (req, res) => res.status(501).json({ error: 'Not implemented yet' }));
router.post('/recharge/initiate',    ...student, async (req, res) => res.status(501).json({ error: 'Not implemented yet' }));

module.exports = router;
