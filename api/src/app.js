require('dotenv').config();
const express = require('express');

const app = express();

// Raw body AVANT express.json — webhook Adullam exige le body brut pour HMAC
app.use('/api/webhooks/adullam', express.raw({ type: 'application/json' }));

app.use(express.json());

// Health check
app.get('/api/health', (_req, res) => res.json({ ok: true }));

// Routes
app.use('/api', require('./routes/auth'));
app.use('/api', require('./routes/student'));
app.use('/api', require('./routes/parent'));
app.use('/api', require('./routes/admin'));
app.use('/api', require('./routes/webhook'));
app.use('/api', require('./routes/notifications'));

// 404
app.use((_req, res) => res.status(404).json({ error: 'Route introuvable' }));

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`Cantine Vatel API — port ${PORT}`));
