const API_URL = import.meta.env.VITE_API_URL || 'https://cantine-vatel.duckdns.org/api'

function getToken() {
  return localStorage.getItem('admin_token')
}

async function request(path, options = {}) {
  const token = getToken()
  const res = await fetch(`${API_URL}${path}`, {
    ...options,
    headers: {
      'Content-Type': 'application/json',
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
      ...options.headers,
    },
  })

  if (res.status === 401) {
    localStorage.removeItem('admin_token')
    localStorage.removeItem('admin_user')
    window.location.reload()
    return
  }

  if (res.status === 204) return null

  const body = await res.json().catch(() => ({}))
  if (!res.ok) throw new Error(body.error || `Erreur ${res.status}`)
  return body
}

// ─── Mock data ────────────────────────────────────────────────────────────────

const MOCK_DASHBOARD = {
  today_orders: 186,
  revenue_fcfa: 213400,
  served: 142,
  cancelled: 5,
  weekly: [
    { day: 'Lun', count: 164 },
    { day: 'Mar', count: 171 },
    { day: 'Mer', count: 122 },
    { day: 'Jeu', count: 174 },
    { day: 'Ven', count: 186 },
  ],
  top_dishes: [
    { name: 'Alloco poulet braisé',    count: 64 },
    { name: 'Attiéké poisson braisé',  count: 48 },
    { name: 'Igname frite poulet',     count: 41 },
    { name: 'Foutou sauce gombo',      count: 33 },
  ],
  recent_orders: [
    { id: 1041, student_name: 'Aya Koffi',         class: 'Tle D',   dish_name: 'Alloco poulet braisé',   slot: '12 h – 12 h 45',    amount_fcfa: 1000, status: 'served'    },
    { id: 1042, student_name: 'Moussa Bamba',       class: '1re C',   dish_name: 'Foutou sauce gombo',     slot: '12 h – 12 h 45',    amount_fcfa: 1500, status: 'confirmed' },
    { id: 1043, student_name: 'Fatou Traoré',       class: '2nde A',  dish_name: 'Igname frite poulet',   slot: '12 h 45 – 13 h 30', amount_fcfa: 1200, status: 'served'    },
    { id: 1044, student_name: 'Serge Yao',          class: '2nde C',  dish_name: 'Attiéké poisson braisé',slot: '12 h 30 – 13 h 30', amount_fcfa: 1500, status: 'cancelled' },
  ],
  low_balance_students: [
    { name: 'Yao Koffi',    class: 'Tle B', balance: 500  },
    { name: 'Adjé Kouamé',  class: '2nde C', balance: 300 },
  ],
}

const MOCK_ORDERS = {
  summary: [
    { dish_name: 'Alloco poulet braisé',    count: 64 },
    { dish_name: 'Attiéké poisson braisé',  count: 48 },
    { dish_name: 'Igname frite poulet',     count: 41 },
    { dish_name: 'Foutou sauce gombo',      count: 33 },
    { dish_name: 'Riz sauce feuille',       count: 18 },
  ],
  orders: [
    { id: 1041, student_name: 'Aya Koffi',          class: 'Tle D',  dish_name: 'Alloco poulet braisé',   slot: '12 h – 12 h 45',    amount_fcfa: 1000, status: 'confirmed' },
    { id: 1042, student_name: 'Moussa Bamba',        class: '1re C',  dish_name: 'Foutou sauce gombo',     slot: '12 h – 12 h 45',    amount_fcfa: 1500, status: 'confirmed' },
    { id: 1043, student_name: 'Fatou Traoré',        class: '2nde A', dish_name: 'Igname frite poulet',   slot: '12 h 45 – 13 h 30', amount_fcfa: 1200, status: 'served'    },
    { id: 1044, student_name: "Kouadio N'Guessan",   class: 'Tle C',  dish_name: 'Alloco poulet braisé',  slot: '12 h – 12 h 45',    amount_fcfa: 1000, status: 'served'    },
    { id: 1045, student_name: 'Awa Diallo',          class: '1re D',  dish_name: 'Attiéké poisson braisé',slot: '12 h – 12 h 45',    amount_fcfa: 1500, status: 'confirmed' },
    { id: 1046, student_name: 'Serge Yao',           class: '2nde C', dish_name: 'Riz sauce feuille',     slot: '12 h 45 – 13 h 30', amount_fcfa: 800,  status: 'cancelled' },
    { id: 1047, student_name: 'Mariam Koné',         class: 'Tle A',  dish_name: 'Foutou sauce gombo',    slot: '12 h 45 – 13 h 30', amount_fcfa: 1500, status: 'served'    },
    { id: 1048, student_name: 'Jean-Marc Aka',       class: '1re A',  dish_name: 'Alloco poulet braisé',  slot: '12 h 45 – 13 h 30', amount_fcfa: 1000, status: 'confirmed' },
    { id: 1049, student_name: 'Esther Ouattara',     class: '2nde B', dish_name: 'Attiéké poisson braisé',slot: '12 h – 12 h 45',    amount_fcfa: 1500, status: 'served'    },
    { id: 1050, student_name: 'Ibrahim Sangaré',     class: 'Tle D',  dish_name: 'Igname frite poulet',   slot: '12 h – 12 h 45',    amount_fcfa: 1200, status: 'confirmed' },
  ],
}

// ─── Exports ──────────────────────────────────────────────────────────────────

export async function login(matricule, password) {
  const data = await request('/auth/login', {
    method: 'POST',
    body: JSON.stringify({ matricule, password }),
  })
  if (data.user.role !== 'admin') throw new Error('Accès réservé aux administrateurs')
  return data
}

export async function getDashboard(date) {
  try {
    return await request(`/admin/dashboard${date ? `?date=${date}` : ''}`)
  } catch {
    return MOCK_DASHBOARD
  }
}

export async function getOrders(date) {
  try {
    return await request(`/admin/orders${date ? `?date=${date}` : ''}`)
  } catch {
    return MOCK_ORDERS
  }
}

export async function markServed(id) {
  try {
    return await request(`/admin/orders/${id}/serve`, { method: 'PATCH' })
  } catch {
    return { reservation: { id, status: 'served' } }
  }
}

export async function markCancelled(id) {
  try {
    return await request(`/admin/orders/${id}/cancel`, { method: 'PATCH' })
  } catch {
    return { reservation: { id, status: 'cancelled' } }
  }
}

export function formatFCFA(n) {
  return String(n).replace(/\B(?=(\d{3})+(?!\d))/g, ' ') + ' FCFA'
}

export function todayISO() {
  return new Date().toISOString().slice(0, 10)
}

export function formatDateLong(iso) {
  return new Date(iso + 'T12:00:00').toLocaleDateString('fr-FR', {
    weekday: 'long', day: 'numeric', month: 'long',
  })
}
