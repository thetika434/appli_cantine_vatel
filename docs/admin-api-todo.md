# Routes API manquantes — session ADMIN

> Document de handoff pour la **session API**.  
> Une fois ces routes implémentées, la session ADMIN remplacera les données factices par les vrais appels.

---

## Contexte

L'interface admin (`admin/`) est terminée et tourne avec des **données factices** (`src/services/api.js`).  
Toutes les routes admin nécessitent l'en-tête `Authorization: Bearer <token>` avec `role = "admin"`.  
Préfixe commun : `/api`

---

## 1. `GET /admin/dashboard`

**Query param optionnel :** `?date=2026-11-21` (défaut = aujourd'hui)

**Réponse attendue :**
```json
{
  "today_orders": 186,
  "revenue_fcfa": 213400,
  "served": 142,
  "cancelled": 5,
  "weekly": [
    { "day": "Lun", "count": 164 },
    { "day": "Mar", "count": 171 },
    { "day": "Mer", "count": 122 },
    { "day": "Jeu", "count": 174 },
    { "day": "Ven", "count": 186 }
  ],
  "top_dishes": [
    { "name": "Alloco poulet braisé",   "count": 64 },
    { "name": "Attiéké poisson braisé", "count": 48 },
    { "name": "Igname frite poulet",    "count": 41 },
    { "name": "Foutou sauce gombo",     "count": 33 }
  ],
  "recent_orders": [
    {
      "id": 1041,
      "student_name": "Aya Koffi",
      "class": "Tle D",
      "dish_name": "Alloco poulet braisé",
      "slot": "12 h – 12 h 45",
      "amount_fcfa": 1000,
      "status": "served"
    }
  ],
  "low_balance_students": [
    { "name": "Yao Koffi", "class": "Tle B", "balance": 500 }
  ]
}
```

**Logique SQL suggérée :**
- `today_orders` : `COUNT(*)` des réservations avec `dishes.serve_date = $date`
- `revenue_fcfa` : `SUM(dishes.price_fcfa)` des réservations non annulées du jour
- `served` / `cancelled` : comptages par `status`
- `weekly` : regrouper par `serve_date` sur la semaine ISO contenant `$date`, renvoyer jour court FR
- `top_dishes` : `GROUP BY dish_id ORDER BY COUNT DESC LIMIT 4` pour `$date`
- `recent_orders` : 10 dernières réservations du jour, joindre `users` et `dishes`
- `low_balance_students` : `WHERE balance < 1000` (seuil configurable) — **champ nouveau, non dans le plan initial**

---

## 2. `GET /admin/orders`

**Query param optionnel :** `?date=2026-11-21` (défaut = aujourd'hui)

**Réponse attendue :**
```json
{
  "summary": [
    { "dish_name": "Alloco poulet braisé",   "count": 64 },
    { "dish_name": "Attiéké poisson braisé", "count": 48 },
    { "dish_name": "Igname frite poulet",    "count": 41 },
    { "dish_name": "Foutou sauce gombo",     "count": 33 },
    { "dish_name": "Riz sauce feuille",      "count": 18 }
  ],
  "orders": [
    {
      "id": 1041,
      "student_name": "Aya Koffi",
      "class": "Tle D",
      "dish_name": "Alloco poulet braisé",
      "slot": "12 h – 12 h 45",
      "amount_fcfa": 1000,
      "status": "confirmed"
    }
  ]
}
```

**Champ `slot` :** construire depuis `dishes.slot_start` et `dishes.slot_end` au format `"12 h – 13 h 30"`.  
**`status`** : valeurs possibles `"confirmed"` | `"served"` | `"cancelled"` (colonne `reservations.status`).  
**Tri conseillé :** `ORDER BY reservations.created_at DESC`.

---

## 3. `PATCH /admin/orders/:id/serve`

Marque la réservation `:id` comme servie.

**Réponse 200 :**
```json
{
  "reservation": {
    "id": 1041,
    "status": "served"
  }
}
```

**Logique :** `UPDATE reservations SET status = 'served' WHERE id = $1 AND status = 'confirmed'`  
Retourner 404 si introuvable, 409 si déjà servie ou annulée.

---

## 4. `PATCH /admin/orders/:id/cancel`

Annule la réservation et **rembourse le solde** (opération atomique).

**Réponse 200 :**
```json
{
  "reservation": {
    "id": 1041,
    "status": "cancelled"
  }
}
```

**Logique SQL (dans une transaction) :**
```sql
BEGIN;
  UPDATE reservations SET status = 'cancelled'
    WHERE id = $1 AND status IN ('confirmed', 'served');
  -- si 0 ligne → ROLLBACK, 409
  UPDATE student_balances
    SET balance = balance + dishes.price_fcfa
    FROM dishes
    JOIN reservations r ON r.dish_id = dishes.id
    WHERE r.id = $1 AND student_balances.student_id = r.student_id;
  INSERT INTO transactions (student_id, type, amount_fcfa, label, reference)
    SELECT r.student_id, 'credit', d.price_fcfa,
           'Remboursement ' || d.name, $1::text
    FROM reservations r JOIN dishes d ON d.id = r.dish_id
    WHERE r.id = $1;
COMMIT;
```

---

## Ce que la session ADMIN fera ensuite

Une fois les 4 routes déployées et testées (Postman ou curl), la session ADMIN :

1. Retirera les blocs `try/catch` avec fallback mock dans `api.js`
2. Vérifiera que les vrais JSON correspondent aux champs attendus
3. Commitera `fix(admin): connecter les routes API réelles`

---

## Test rapide (curl depuis le serveur)

```bash
# Obtenir un token admin
TOKEN=$(curl -s -X POST https://cantine-vatel.duckdns.org/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"matricule":"admin@vatel.ci","password":"admin1234"}' | jq -r '.token')

# Dashboard
curl -H "Authorization: Bearer $TOKEN" \
  https://cantine-vatel.duckdns.org/api/admin/dashboard

# Commandes
curl -H "Authorization: Bearer $TOKEN" \
  https://cantine-vatel.duckdns.org/api/admin/orders

# Marquer servie
curl -X PATCH -H "Authorization: Bearer $TOKEN" \
  https://cantine-vatel.duckdns.org/api/admin/orders/1/serve

# Annuler
curl -X PATCH -H "Authorization: Bearer $TOKEN" \
  https://cantine-vatel.duckdns.org/api/admin/orders/1/cancel
```
