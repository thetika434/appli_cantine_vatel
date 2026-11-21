# Plan — Cantine Vatel · Hackathon 21 novembre

Démo jury : 23–25 novembre. Deadline code : 18h00 aujourd'hui.

---

## 1. Architecture générale et arborescence

```
cantine-vatel/
├── api/                          # Node.js 20 + Express + pg (SQL brut)
│   ├── src/
│   │   ├── app.js                # Express, middlewares globaux
│   │   ├── db/
│   │   │   ├── pool.js           # Pool pg (DATABASE_URL depuis .env)
│   │   │   └── migrations/
│   │   │       └── 001_init.sql  # Schéma complet, idempotent
│   │   ├── middleware/
│   │   │   └── auth.js           # verifyJWT(), requireRole('admin'|'parent')
│   │   └── routes/
│   │       ├── auth.js           # POST /auth/login
│   │       ├── student.js        # /me, /menus, /dishes, /reservations, /transactions, /recharge/initiate
│   │       ├── parent.js         # /parent/children, /parent/transactions, /parent/recharge
│   │       ├── admin.js          # /admin/dashboard, /admin/orders, /admin/dishes
│   │       └── webhook.js        # POST /webhooks/adullam (raw body, avant json)
│   ├── .env.example
│   └── package.json
│
├── mobile/                       # Flutter (Android), SDK ≥ 3.x
│   ├── lib/
│   │   ├── main.dart
│   │   ├── theme.dart            # AppTheme (couleurs + typos extraites de la maquette)
│   │   ├── services/
│   │   │   └── api.dart          # ApiService (Dio), gestion token, refresh
│   │   ├── models/               # User, Dish, Reservation, Transaction (fromJson)
│   │   └── screens/
│   │       ├── splash_screen.dart
│   │       ├── login_screen.dart               # sélecteur Élève|Parent
│   │       ├── student/
│   │       │   ├── student_shell.dart          # BottomNav (Accueil|Menus|Historique|Profil)
│   │       │   ├── home_screen.dart            # solde + plat du jour + bouton Réserver
│   │       │   ├── menus_screen.dart           # sélecteur jours + liste plats
│   │       │   ├── dish_detail_screen.dart     # photo, infos, quantité, Ajouter
│   │       │   ├── reservation_summary_screen.dart
│   │       │   ├── recharge_screen.dart        # presets, opérateur, champ libre
│   │       │   ├── history_screen.dart         # onglets Tout|Repas|Recharges
│   │       │   └── profile_screen.dart         # statique + Se déconnecter
│   │       └── parent/
│   │           ├── parent_shell.dart           # BottomNav (Accueil|Historique|Alertes|Réglages)
│   │           ├── parent_home_screen.dart     # Mes enfants + soldes + Recharger
│   │           ├── child_detail_screen.dart    # onglets Aya|Yao, solde, derniers repas
│   │           ├── parent_recharge_screen.dart # sélecteur enfant + même widget recharge
│   │           ├── parent_history_screen.dart  # filtre Tous|Aya|Yao + Tout|Repas|Recharges
│   │           ├── alerts_screen.dart          # statique pour démo
│   │           └── settings_screen.dart        # statique + Se déconnecter
│   └── pubspec.yaml
│
├── admin/                        # React + Vite (SPA, servi par Nginx /admin)
│   ├── src/
│   │   ├── main.jsx
│   │   ├── services/api.js       # fetch wrapper + Bearer token
│   │   ├── components/
│   │   │   └── Layout.jsx        # Sidebar + zone principale
│   │   └── pages/
│   │       ├── Login.jsx
│   │       ├── Dashboard.jsx     # KPI + graphique semaine + dernières commandes
│   │       ├── Orders.jsx        # À préparer + tableau filtrable + Marquer servie
│   │       └── Menus.jsx         # Semaine + liste jours + formulaire ajout/modif
│   └── package.json
│
└── docs/
    ├── design/
    └── plan.md
```

**Principe de communication :**
- Mobile et admin parlent exclusivement à `https://cantine-vatel.duckdns.org/api`
- Nginx route `/api` → `localhost:3000`, `/admin` → `dist/` admin buildé
- JWT signé avec `JWT_SECRET` (HS256), durée 7 jours, payload `{ id, role }`

---

## 2. Schéma de la base de données

```sql
-- ─────────────────────────────────────────
-- TABLE users  (élèves, parents, admins)
-- ─────────────────────────────────────────
CREATE TABLE users (
  id            SERIAL PRIMARY KEY,
  matricule     VARCHAR(30)  UNIQUE NOT NULL,
  -- Élève  : "VAT-24-0157"
  -- Parent : numéro de téléphone "+22507XXXXXXXX"
  -- Admin  : e-mail
  password_hash TEXT         NOT NULL,
  role          VARCHAR(10)  NOT NULL CHECK (role IN ('student','parent','admin')),
  full_name     VARCHAR(100) NOT NULL,
  class         VARCHAR(20),                   -- ex. "Terminale D" (student seulement)
  phone         VARCHAR(20),                   -- numéro mobile (parent / recharge)
  created_at    TIMESTAMPTZ  DEFAULT NOW()
);

-- ─────────────────────────────────────────
-- TABLE student_balances  (solde élève)
-- Contrainte CHECK en base, jamais de décimale
-- ─────────────────────────────────────────
CREATE TABLE student_balances (
  student_id  INT  PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  balance     INT  NOT NULL DEFAULT 0 CHECK (balance >= 0)
);

-- ─────────────────────────────────────────
-- TABLE parent_children  (liaison 1 parent → N enfants)
-- ─────────────────────────────────────────
CREATE TABLE parent_children (
  parent_id   INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  student_id  INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  PRIMARY KEY (parent_id, student_id)
);

-- ─────────────────────────────────────────
-- TABLE dishes  (plats proposés)
-- ─────────────────────────────────────────
CREATE TABLE dishes (
  id          SERIAL PRIMARY KEY,
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
-- TABLE reservations
-- Une seule réservation par élève par plat (UNIQUE)
-- ─────────────────────────────────────────
CREATE TABLE reservations (
  id          SERIAL PRIMARY KEY,
  student_id  INT NOT NULL REFERENCES users(id),
  dish_id     INT NOT NULL REFERENCES dishes(id),
  status      VARCHAR(20) NOT NULL DEFAULT 'confirmed'
              CHECK (status IN ('confirmed','served','cancelled')),
  created_at  TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE (student_id, dish_id)
);

-- ─────────────────────────────────────────
-- TABLE transactions  (journal du solde)
-- Chaque débit (réservation) ou crédit (recharge) est écrit
-- dans la MÊME transaction SQL que la mutation du solde
-- ─────────────────────────────────────────
CREATE TABLE transactions (
  id          SERIAL PRIMARY KEY,
  student_id  INT NOT NULL REFERENCES users(id),
  type        VARCHAR(10) NOT NULL CHECK (type IN ('debit','credit')),
  amount_fcfa INT NOT NULL CHECK (amount_fcfa > 0),
  label       VARCHAR(100),                    -- "Alloco poulet braisé" ou "Recharge Orange Money"
  reference   VARCHAR(100),                    -- reservation_id ou payment_id Adullam
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

-- ─────────────────────────────────────────
-- TABLE recharges  (paiements Adullam)
-- payment_id UNIQUE = déduplication webhook (livraison "au moins une fois")
-- ─────────────────────────────────────────
CREATE TABLE recharges (
  id              SERIAL  PRIMARY KEY,
  student_id      INT     NOT NULL REFERENCES users(id),
  initiated_by    INT     NOT NULL REFERENCES users(id),  -- élève ou parent
  payment_id      VARCHAR(100) UNIQUE NOT NULL,           -- ID retourné par Adullam
  idempotency_key UUID    NOT NULL,
  amount_fcfa     INT     NOT NULL CHECK (amount_fcfa > 0 AND amount_fcfa % 5 = 0),
  phone           VARCHAR(20) NOT NULL,
  channel         VARCHAR(20) NOT NULL
                  CHECK (channel IN ('orangeCI','mtnCI','moovCI','waveCI')),
  status          VARCHAR(20) NOT NULL DEFAULT 'pending',
  processed_at    TIMESTAMPTZ,
  created_at      TIMESTAMPTZ DEFAULT NOW()
);

-- Index utiles
CREATE INDEX ON dishes (serve_date, visible);
CREATE INDEX ON reservations (student_id, created_at DESC);
CREATE INDEX ON transactions (student_id, created_at DESC);
```

**Règle d'or :**
Tout débit du solde (`UPDATE student_balances SET balance = balance - $1`) et l'`INSERT INTO transactions` correspondant s'exécutent dans **une seule transaction SQL** (`BEGIN … COMMIT`). Idem pour le crédit après le webhook.

---

## 3. Routes de l'API

Préfixe commun : `/api`  
Authentification : en-tête `Authorization: Bearer <token>` sur toutes les routes protégées.

### Auth (public)

| Méthode | Route | Corps | Réponse |
|---------|-------|-------|---------|
| `POST` | `/auth/login` | `{ matricule, password }` | `{ token, user: { id, role, full_name, class } }` |

---

### Élève (`role: student`)

| Méthode | Route | Corps / Params | Réponse |
|---------|-------|----------------|---------|
| `GET` | `/me` | — | `{ user, balance }` |
| `GET` | `/menus/week` | `?date=2026-11-21` (optionnel, défaut = aujourd'hui) | `{ week_start, week_end, days: [{ date, dishes[] }] }` |
| `GET` | `/dishes/:id` | — | `{ dish }` |
| `POST` | `/reservations` | `{ dish_id }` | `{ reservation, new_balance }` |
| `GET` | `/reservations` | — | `{ reservations[] }` |
| `GET` | `/transactions` | `?type=debit\|credit` | `{ transactions[] }` |
| `POST` | `/recharge/initiate` | `{ amount, phone, channel }` | `{ payment_id, status: 'pending' }` |

**Détail `POST /reservations` (atomique) :**
```
BEGIN;
  SELECT balance FROM student_balances WHERE student_id = $1 FOR UPDATE;
  -- si balance < price_fcfa → ROLLBACK, retourner 422
  UPDATE student_balances SET balance = balance - price_fcfa WHERE student_id = $1;
  UPDATE dishes SET quantity = quantity - 1 WHERE id = $dish_id AND quantity > 0;
  -- si 0 ligne mise à jour → ROLLBACK, retourner 409 "Épuisé"
  INSERT INTO reservations (student_id, dish_id) VALUES ($1, $2);
  INSERT INTO transactions (student_id, type, amount_fcfa, label, reference) VALUES ($1, 'debit', price_fcfa, dish_name, reservation_id);
COMMIT;
```

---

### Parent (`role: parent`)

| Méthode | Route | Corps / Params | Réponse |
|---------|-------|----------------|---------|
| `GET` | `/parent/children` | — | `{ children: [{ student, balance }] }` |
| `GET` | `/parent/children/:student_id` | — | `{ student, balance, recent_transactions[] }` |
| `GET` | `/parent/transactions` | `?student_id=` | `{ transactions[] }` (tous les enfants ou filtré) |
| `POST` | `/parent/recharge` | `{ student_id, amount, phone, channel }` | `{ payment_id }` |

---

### Admin (`role: admin`)

| Méthode | Route | Corps / Params | Réponse |
|---------|-------|----------------|---------|
| `GET` | `/admin/dashboard` | `?date=` | `{ today_orders, revenue_fcfa, served, cancelled, weekly: [], top_dishes[], recent_orders[] }` |
| `GET` | `/admin/orders` | `?date=` | `{ summary: [{ dish, count }], orders[] }` |
| `PATCH` | `/admin/orders/:id/serve` | — | `{ reservation }` |
| `PATCH` | `/admin/orders/:id/cancel` | — | `{ reservation }` (rembourse le solde, atomique) |
| `GET` | `/admin/dishes` | `?week=2026-11-21` | `{ days: [{ date, dishes[] }] }` |
| `POST` | `/admin/dishes` | `{ name, description, photo_url, price_fcfa, serve_date, quantity, visible }` | `{ dish }` |
| `PUT` | `/admin/dishes/:id` | (mêmes champs, partiels) | `{ dish }` |
| `DELETE` | `/admin/dishes/:id` | — | `204` |

---

### Webhook Adullam (public, signature HMAC)

| Méthode | Route | Particularités |
|---------|-------|----------------|
| `POST` | `/webhooks/adullam` | `express.raw()` **avant** `express.json()` sur cette route uniquement |

**Logique du handler :**
1. Lire l'en-tête `adullam-signature`
2. Calculer `HMAC-SHA256(raw_body, ADULLAM_WEBHOOK_SECRET)` en hex
3. Comparer en temps constant (`timingSafeEqual`) → `401` si invalide
4. Répondre `200` **immédiatement**
5. Parser le JSON, vérifier `status === 'completed'`
6. Chercher la recharge par `payment_id` → si déjà `processed_at` non null, s'arrêter (déduplication)
7. Dans une transaction SQL :
   - `UPDATE recharges SET status='completed', processed_at=NOW()`
   - `UPDATE student_balances SET balance = balance + amount_fcfa`
   - `INSERT INTO transactions (type='credit', …)`

---

## 4. Découpage de la journée

Chaque créneau se termine par un **déploiement et un test bout-en-bout**. À tout moment à partir du créneau 3, une démo partielle est possible.

---

### 09h00–10h00 — Fondations : Git, DB, déploiement initial

**Objectif :** le serveur répond `{"ok":true}` sur `https://cantine-vatel.duckdns.org/api/health`

- [ ] `git remote add origin https://github.com/thetika434/appli_cantine_vatel.git` + push
- [ ] `api/` : `npm init`, dépendances (`express`, `pg`, `bcryptjs`, `jsonwebtoken`, `uuid`, `dotenv`)
- [ ] `001_init.sql` : toutes les tables
- [ ] `db/pool.js` : Pool pg depuis `DATABASE_URL`
- [ ] `app.js` : `GET /api/health` → `{ ok: true }`
- [ ] `api/.env.example` (sans valeurs)
- [ ] SSH sur le serveur : `git clone`, créer `/api/.env`, `npm install`, `pm2 start`, nginx config
- [ ] Vérification HTTPS

---

### 10h00–11h15 — Authentification

**Objectif :** s'identifier dans l'app Flutter et voir son solde

**API :**
- [ ] `POST /api/auth/login` (bcrypt compare, JWT signe)
- [ ] Middleware `verifyJWT`
- [ ] `GET /api/me`
- [ ] Données de test SQL : 1 admin, 1 parent, 2 élèves (Aya VAT-24-0157, Yao VAT-24-0158), soldes

**Flutter :**
- [ ] `pubspec.yaml` : dépendances (`dio`, `shared_preferences`, `go_router`)
- [ ] `theme.dart` : couleurs (#F3F6F0, #FF8A1F, #34C17B, #1F1B18, #6E6660), Poppins, Inter
- [ ] `splash_screen.dart` : photo alloco + "Venez réserver votre Dabali chap chap"
- [ ] `login_screen.dart` : toggle Élève|Parent, champs, bouton Se connecter
- [ ] `api.dart` : `ApiService.login()`, stockage token + user dans SharedPreferences
- [ ] Navigation splash → login → home selon role

**Déploiement :** git push + pm2 restart + test Postman

---

### 11h15–12h30 — Menus et détail plat

**Objectif :** voir les plats de la semaine et le plat du jour dans Flutter

**API :**
- [ ] `GET /api/menus/week`
- [ ] `GET /api/dishes/:id`
- [ ] Données de test : 5 plats sur 2 jours (Alloco 1 000, Igname frite 1 200, Riz sauce feuille 800, Foutou gombo 1 500, Attiéké 1 500 épuisé)

**Flutter :**
- [ ] `student_shell.dart` (BottomNavigationBar 4 items)
- [ ] `home_screen.dart` : carte orange solde + œil, "+Recharger", plat du jour (photo, nom, prix orange, statut vert, bouton Réserver), section "Aussi au menu"
- [ ] `menus_screen.dart` : sélecteur jours (chips, jour actif vert), liste plats (photo 72px, nom, prix orange, statut, bouton +)
- [ ] `dish_detail_screen.dart` : photo héro, nom Poppins, prix orange, description, 2 tuiles (Retrait / Disponible), sélecteur –/+, bouton "Ajouter · X FCFA"

**Déploiement + test**

---

### 12h30–13h00 — Réservation (backend)

**Objectif :** le backend débite le solde de façon atomique

- [ ] `POST /api/reservations` avec transaction SQL complète (voir section 3)
- [ ] Tests Postman : solde insuffisant → 422, plat épuisé → 409, succès → 200 + nouveau solde
- [ ] Vérifier contrainte CHECK (solde >= 0) déclenche bien un rollback

---

### 13h00–14h30 — Réservation (Flutter) + Historique

**Objectif :** démo complète du parcours élève (connexion → réserver → historique)

**Flutter :**
- [ ] `reservation_summary_screen.dart` : miniature plat, tableau Solde/Repas/Nouveau solde, bouton "Confirmer"
- [ ] `ApiService.reserve()` → retour du nouveau solde → mise à jour home
- [ ] `history_screen.dart` : onglets Tout|Repas|Recharges, liste avec icône + date + montant coloré (rouge débit, vert crédit)
- [ ] `GET /api/transactions`

**Déploiement + démo partielle jury possible ✓**

---

### 14h30–15h45 — Recharge Adullam

**Objectif :** paiement mobile money réel qui crédite le solde via webhook

**API :**
- [ ] `POST /api/recharge/initiate` : génère UUID idempotency-key, appel `POST https://api.adullam.dev/v1/payments` (en-têtes `x-auth` + `x-idempotency-key`), INSERT recharges, retourne `payment_id`
- [ ] `POST /api/webhooks/adullam` : `express.raw()`, HMAC, déduplication, crédit atomique

**Flutter :**
- [ ] `recharge_screen.dart` : 4 presets (1 000/2 000/5 000/10 000), champ "Autre montant", 2 opérateurs (Orange Money, Wave), calcul "Nouveau solde", bouton "Payer X FCFA", note "Paiement simulé"
- [ ] `ApiService.initiateRecharge()` → polling ou message "Paiement en cours, le solde sera mis à jour automatiquement"

**Déploiement + test webhook (utiliser `curl` ou dashboard Adullam pour simuler)**

---

### 15h45–16h45 — Parcours Parent

**Objectif :** un parent se connecte, voit ses enfants, recharge l'enfant à solde faible

**API :**
- [ ] `GET /api/parent/children`
- [ ] `GET /api/parent/children/:student_id`
- [ ] `GET /api/parent/transactions`
- [ ] `POST /api/parent/recharge`

**Flutter :**
- [ ] `login_screen.dart` : champ "Téléphone" quand Parent sélectionné, route vers `parent_shell`
- [ ] `parent_home_screen.dart` : "Bonsoir Mme Koffi", liste enfants (avatar initiales, classe, solde ; "Solde faible" en orange si < seuil), bouton "Recharger [prénom]" contextuel, section Récemment avec transactions mixtes
- [ ] `child_detail_screen.dart` : onglets par enfant, solde + "+ Recharger", préférences, derniers repas
- [ ] `parent_recharge_screen.dart` : sélecteur enfant en haut (tuile Aya|tuile Yao), puis même widget recharge
- [ ] `parent_history_screen.dart` : filtre Tous|Aya|Yao + Tout|Repas|Recharges

**Déploiement + test**

---

### 16h45–17h30 — Interface Admin (React + Vite)

**Objectif :** l'admin se connecte, voit le dashboard, gère les commandes et les menus

- [ ] `npm create vite@latest admin -- --template react`, CSS simple (sans librairie lourde, couleurs du design system)
- [ ] `Layout.jsx` : sidebar (Tableau de bord / Commandes / Menus) + avatar bas, style "Espace admin" en orange
- [ ] `Login.jsx` : split gauche photo + droite formulaire (page 18)
- [ ] `Dashboard.jsx` : 4 KPI cards, graphique barres semaine (SVG simple ou recharts), top plats avec barres, tableau dernières commandes avec statuts colorés (page 19)
- [ ] `Orders.jsx` : section "À préparer" (tuiles quantité/plat), tabs filtre Toutes|À servir|Servies|Annulées, recherche, tableau avec bouton "Marquer servie" (page 20)
- [ ] `Menus.jsx` : navigation semaine (flèches), tabs jours, liste plats avec modifier/supprimer, panneau formulaire latéral (page 21)
- [ ] `npm run build` → déploiement dans `/var/www/admin` + config Nginx `/admin → dist/`

**Déploiement + test**

---

### 17h30–18h00 — Finitions et données de démo

- [ ] `profile_screen.dart` : avatar orange, nom + classe + matricule, chips préférences (désactivées pour démo), toggles notifications (désactivés), "Paramètres" (vide), "Se déconnecter" (orange, efface token + retour login)
- [ ] Données de démo complètes : 3 élèves, 2 parents, 1 admin, menus semaines du 24 et du 1er déc., historique cohérent (réservations passées, recharges)
- [ ] Vérification de l'état final bout-en-bout (connexion élève, réservation, recharge, historique, connexion parent, connexion admin)
- [ ] `README.md` minimaliste : identifiants de démo, URL de prod, URL admin

---

## Synthèse des dépendances externes

| Service | Clé / Secret | Usage |
|---------|-------------|-------|
| Adullam API | `ADULLAM_KEY` (en-tête `x-auth`) | Initier les paiements |
| Adullam Webhook | `ADULLAM_WEBHOOK_SECRET` (format `whsec_...`) | Vérifier la signature HMAC |
| PostgreSQL | `DATABASE_URL` | Connexion pg |
| JWT | `JWT_SECRET` | Signer / vérifier les tokens |

Tous les secrets vivent dans `/api/.env` sur le serveur. `api/.env.example` documente les clés sans valeurs.

---

## Contrat API — référence session mobile

> Format exact des requêtes et réponses. La session mobile s'y fie sans lire le code.

---

### POST /api/auth/login

**Public — pas de token requis.**

Requête `Content-Type: application/json` :
```json
{ "matricule": "VAT-24-0157", "password": "test1234" }
```

Réponse **200** :
```json
{
  "token": "eyJhbGciOiJIUzI1NiJ9...",
  "user": {
    "id": 2,
    "role": "student",
    "full_name": "Aya Koné",
    "class": "Terminale D"
  }
}
```
- `role` : `"student"` | `"parent"` | `"admin"`
- `class` : `string` si élève, `null` sinon
- `token` : JWT HS256, durée 7 jours, payload `{ id, role }`

Erreurs :
| Code | Corps | Cause |
|------|-------|-------|
| 400 | `{ "error": "Champs requis : matricule, password" }` | champ manquant |
| 401 | `{ "error": "Identifiants invalides" }` | matricule inconnu ou mot de passe incorrect |

---

### POST /api/reservations

**En-tête :** `Authorization: Bearer <token>` (rôle `student`)

Requête :
```json
{ "dish_id": 1 }
```

Réponse **200** :
```json
{
  "reservation": { "id": 1, "student_id": 2, "dish_id": 1, "status": "confirmed", "created_at": "..." },
  "new_balance": 4000
}
```

Erreurs :
| Code | Corps | Cause |
|------|-------|-------|
| 400 | `{ "error": "dish_id requis" }` | corps manquant |
| 404 | `{ "error": "Plat introuvable" }` | dish_id inconnu |
| 409 | `{ "error": "Déjà réservé" }` | réservation doublon |
| 409 | `{ "error": "Plat épuisé" }` | quantity = 0 |
| 422 | `{ "error": "Solde insuffisant" }` | balance < price_fcfa |

---

### GET /api/reservations

**En-tête :** `Authorization: Bearer <token>` (rôle `student`)

Réponse **200** :
```json
{
  "reservations": [
    {
      "id": 1,
      "dish_id": 1,
      "dish_name": "Alloco poulet braisé",
      "price_fcfa": 1000,
      "serve_date": "2026-11-24",
      "status": "confirmed",
      "created_at": "..."
    }
  ]
}
```

---

### GET /api/transactions

**En-tête :** `Authorization: Bearer <token>` (rôle `student`)  
**Query param :** `?type=debit` | `?type=credit` (optionnel, défaut = tous)

Réponse **200** :
```json
{
  "transactions": [
    {
      "id": 1,
      "type": "debit",
      "amount_fcfa": 1000,
      "label": "Alloco poulet braisé",
      "reference": "1",
      "created_at": "..."
    }
  ]
}
```

---

### GET /api/menus/week

**En-tête :** `Authorization: Bearer <token>` (rôle `student`)  
**Query param :** `?date=2026-11-24` (optionnel, défaut = aujourd'hui)

Réponse **200** :
```json
{
  "week_start": "2026-11-24",
  "week_end": "2026-11-28",
  "days": [
    {
      "date": "2026-11-24",
      "dishes": [
        {
          "id": 1,
          "name": "Alloco poulet braisé",
          "description": "...",
          "photo_url": null,
          "price_fcfa": 1000,
          "slot_start": "12:00:00",
          "slot_end": "13:30:00",
          "quantity": 30,
          "visible": true
        }
      ]
    }
  ]
}
```
- Seuls les plats `visible = true` sont retournés.
- `days` contient uniquement les jours ayant au moins un plat.

Erreurs : 401 (token manquant/invalide), 403 (rôle non autorisé)

---

### GET /api/dishes/:id

**En-tête :** `Authorization: Bearer <token>` (rôle `student`)

Réponse **200** :
```json
{
  "dish": {
    "id": 1,
    "name": "Alloco poulet braisé",
    "description": "Bananes plantain frites avec poulet braisé et sauce piment",
    "photo_url": null,
    "price_fcfa": 1000,
    "serve_date": "2026-11-24",
    "slot_start": "12:00:00",
    "slot_end": "13:30:00",
    "quantity": 30,
    "visible": true
  }
}
```

Erreurs : 401, 403, 404 `{ "error": "Plat introuvable" }`

---

### GET /api/me

**En-tête requis :** `Authorization: Bearer <token>`

Réponse **200** :
```json
{
  "user": {
    "id": 2,
    "matricule": "VAT-24-0157",
    "role": "student",
    "full_name": "Aya Koné",
    "class": "Terminale D",
    "phone": "0701000157"
  },
  "balance": 5000
}
```
- `balance` : entier FCFA, présent si `role === "student"`, `null` sinon

Erreurs :
| Code | Corps | Cause |
|------|-------|-------|
| 401 | `{ "error": "Token manquant" }` | en-tête Authorization absent |
| 401 | `{ "error": "Token invalide ou expiré" }` | JWT invalide ou expiré |

---

## Points de vigilance critiques

1. **Atomicité** : débit solde + écriture transaction = 1 seule transaction SQL, toujours.
2. **Webhook first** : le crédit du solde se fait **uniquement** dans le handler webhook, jamais depuis l'app.
3. **Déduplication** : vérifier `recharges.processed_at IS NULL` avant tout crédit.
4. **Raw body** : monter `express.raw({ type: 'application/json' })` sur `/api/webhooks/adullam` **avant** `express.json()` global.
5. **Solde négatif** : double protection — contrainte `CHECK (balance >= 0)` en base **et** vérification applicative dans la route réservation.
6. **Montants entiers** : jamais de virgule, jamais de float. Tout calcul en entiers FCFA.
7. **Canaux Adullam** : vérifier que le préfixe du numéro correspond au canal (`07` → `orangeCI`, `05` → `mtnCI`, `01` → `moovCI`, `0x`Wave → `waveCI`).
