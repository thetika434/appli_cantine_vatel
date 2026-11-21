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
  return request(`/admin/dashboard${date ? `?date=${date}` : ''}`)
}

export async function getOrders(date) {
  return request(`/admin/orders${date ? `?date=${date}` : ''}`)
}

export async function markServed(id) {
  return request(`/admin/orders/${id}/serve`, { method: 'PATCH' })
}

export async function markCancelled(id) {
  return request(`/admin/orders/${id}/cancel`, { method: 'PATCH' })
}

export async function getWeekDishes(weekStart) {
  return request(`/admin/dishes?week=${weekStart}`)
}

export async function createDish(data) {
  return request('/admin/dishes', { method: 'POST', body: JSON.stringify(data) })
}

export async function updateDish(id, data) {
  return request(`/admin/dishes/${id}`, { method: 'PUT', body: JSON.stringify(data) })
}

export async function deleteDish(id) {
  return request(`/admin/dishes/${id}`, { method: 'DELETE' })
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
