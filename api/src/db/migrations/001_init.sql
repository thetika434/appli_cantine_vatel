-- Migration idempotente — safe à relancer
-- psql -U cantine -d cantine -f 001_init.sql

-- ─────────────────────────────────────────
-- users  (élèves, parents, admins)
-- ─────────────────────────────────────────
CREATE TABLE IF NOT EXISTS users (
  id            SERIAL       PRIMARY KEY,
  matricule     VARCHAR(30)  UNIQUE NOT NULL,
  -- Élève  : "VAT-24-0157"
  -- Parent : "+22507XXXXXXXX"
  -- Admin  : e-mail
  password_hash TEXT         NOT NULL,
  role          VARCHAR(10)  NOT NULL CHECK (role IN ('student','parent','admin')),
  full_name     VARCHAR(100) NOT NULL,
  class         VARCHAR(20),
  phone         VARCHAR(20),
  created_at    TIMESTAMPTZ  DEFAULT NOW()
);

-- ─────────────────────────────────────────
-- student_balances  (solde élève, jamais négatif)
-- ─────────────────────────────────────────
CREATE TABLE IF NOT EXISTS student_balances (
  student_id  INT  PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  balance     INT  NOT NULL DEFAULT 0 CHECK (balance >= 0)
);

-- ─────────────────────────────────────────
-- parent_children  (1 parent → N enfants)
-- ─────────────────────────────────────────
CREATE TABLE IF NOT EXISTS parent_children (
  parent_id   INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  student_id  INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  PRIMARY KEY (parent_id, student_id)
);

-- ─────────────────────────────────────────
-- dishes  (plats proposés)
-- ─────────────────────────────────────────
CREATE TABLE IF NOT EXISTS dishes (
  id          SERIAL       PRIMARY KEY,
  name        VARCHAR(100) NOT NULL,
  description TEXT,
  photo_url   VARCHAR(255),
  price_fcfa  INT  NOT NULL CHECK (price_fcfa > 0 AND price_fcfa % 5 = 0),
  serve_date  DATE NOT NULL,
  slot_start  TIME NOT NULL DEFAULT '12:00',
  slot_end    TIME NOT NULL DEFAULT '13:30',
  quantity    INT  NOT NULL CHECK (quantity >= 0),
  visible     BOOLEAN NOT NULL DEFAULT TRUE,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

-- ─────────────────────────────────────────
-- reservations
-- ─────────────────────────────────────────
CREATE TABLE IF NOT EXISTS reservations (
  id          SERIAL PRIMARY KEY,
  student_id  INT NOT NULL REFERENCES users(id),
  dish_id     INT NOT NULL REFERENCES dishes(id),
  status      VARCHAR(20) NOT NULL DEFAULT 'confirmed'
              CHECK (status IN ('confirmed','served','cancelled')),
  created_at  TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE (student_id, dish_id)
);

-- ─────────────────────────────────────────
-- transactions  (journal du solde)
-- ─────────────────────────────────────────
CREATE TABLE IF NOT EXISTS transactions (
  id          SERIAL PRIMARY KEY,
  student_id  INT NOT NULL REFERENCES users(id),
  type        VARCHAR(10) NOT NULL CHECK (type IN ('debit','credit')),
  amount_fcfa INT NOT NULL CHECK (amount_fcfa > 0),
  label       VARCHAR(100),
  reference   VARCHAR(100),
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

-- ─────────────────────────────────────────
-- recharges  (paiements Adullam)
-- payment_id UNIQUE = déduplication webhook
-- ─────────────────────────────────────────
CREATE TABLE IF NOT EXISTS recharges (
  id              SERIAL       PRIMARY KEY,
  student_id      INT          NOT NULL REFERENCES users(id),
  initiated_by    INT          NOT NULL REFERENCES users(id),
  payment_id      VARCHAR(100) UNIQUE NOT NULL,
  idempotency_key UUID         NOT NULL,
  amount_fcfa     INT          NOT NULL CHECK (amount_fcfa > 0 AND amount_fcfa % 5 = 0),
  phone           VARCHAR(20)  NOT NULL,
  channel         VARCHAR(20)  NOT NULL CHECK (channel IN ('orangeCI','mtnCI','moovCI','waveCI')),
  status          VARCHAR(20)  NOT NULL DEFAULT 'pending',
  processed_at    TIMESTAMPTZ,
  created_at      TIMESTAMPTZ DEFAULT NOW()
);

-- Index
CREATE INDEX IF NOT EXISTS idx_dishes_date       ON dishes       (serve_date, visible);
CREATE INDEX IF NOT EXISTS idx_reservations_user ON reservations (student_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_transactions_user ON transactions (student_id, created_at DESC);

-- ─────────────────────────────────────────
-- notifications  (in-app, polling mobile)
-- ─────────────────────────────────────────
CREATE TABLE IF NOT EXISTS notifications (
  id         SERIAL       PRIMARY KEY,
  user_id    INT          NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  title      VARCHAR(100) NOT NULL,
  body       VARCHAR(255) NOT NULL,
  type       VARCHAR(30)  NOT NULL,  -- 'reservation','served','cancelled','recharge'
  read       BOOLEAN      NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ  DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_notifications_user ON notifications (user_id, read, created_at DESC);

-- ─────────────────────────────────────────
-- Données de test (idempotentes)
-- ─────────────────────────────────────────
-- Mot de passe de tous : "test1234"  → bcrypt hash
-- Hash généré avec bcrypt.hashSync('test1234', 10)
INSERT INTO users (matricule, password_hash, role, full_name, class, phone)
VALUES
  ('admin@vatel.ci',
   '$2a$10$86sHwmhMP8OktEiyOm7BPOVEnkKi3K.g5x6/44OPcpRnvYMGaRzWS',
   'admin', 'Directeur Admin', NULL, NULL),
  ('VAT-24-0157',
   '$2a$10$86sHwmhMP8OktEiyOm7BPOVEnkKi3K.g5x6/44OPcpRnvYMGaRzWS',
   'student', 'Aya Koné', 'Terminale D', '0701000157'),
  ('VAT-24-0158',
   '$2a$10$86sHwmhMP8OktEiyOm7BPOVEnkKi3K.g5x6/44OPcpRnvYMGaRzWS',
   'student', 'Yao Kouassi', 'Terminale D', '0701000158'),
  ('+2250757001001',
   '$2a$10$86sHwmhMP8OktEiyOm7BPOVEnkKi3K.g5x6/44OPcpRnvYMGaRzWS',
   'parent', 'Mme Koné', NULL, '+2250757001001')
ON CONFLICT (matricule) DO NOTHING;

INSERT INTO student_balances (student_id, balance)
SELECT id, 5000 FROM users WHERE matricule = 'VAT-24-0157'
ON CONFLICT DO NOTHING;

INSERT INTO student_balances (student_id, balance)
SELECT id, 1200 FROM users WHERE matricule = 'VAT-24-0158'
ON CONFLICT DO NOTHING;

INSERT INTO parent_children (parent_id, student_id)
SELECT p.id, s.id
FROM users p, users s
WHERE p.matricule = '+2250757001001'
  AND s.matricule IN ('VAT-24-0157','VAT-24-0158')
ON CONFLICT DO NOTHING;

-- Plats de démonstration (semaine du 24 nov + 1er déc)
INSERT INTO dishes (name, description, photo_url, price_fcfa, serve_date, quantity, visible)
VALUES
  ('Alloco poulet braisé',   'Bananes plantain frites avec poulet braisé et sauce piment',    NULL, 1000, '2026-11-24', 30, TRUE),
  ('Igname frite sauce graine','Igname frite avec sauce graine maison',                       NULL, 1200, '2026-11-24', 25, TRUE),
  ('Riz sauce feuille',      'Riz blanc accompagné de sauce feuille de manioc au poisson',    NULL,  800, '2026-11-25', 40, TRUE),
  ('Foutou gombo',           'Foutou banane avec soupe gombo au crabe',                       NULL, 1500, '2026-11-25', 20, TRUE),
  ('Attiéké poisson braisé', 'Attiéké frais avec poisson braisé et tomates',                 NULL, 1500, '2026-11-25',  0, TRUE),
  ('Alloco poulet braisé',   'Bananes plantain frites avec poulet braisé et sauce piment',    NULL, 1000, '2026-12-01', 30, TRUE),
  ('Riz sauce arachide',     'Riz blanc avec sauce arachide au poulet',                       NULL, 1000, '2026-12-01', 35, TRUE)
ON CONFLICT DO NOTHING;
