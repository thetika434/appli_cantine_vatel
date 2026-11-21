import { useState, useEffect, useMemo } from 'react'
import { getOrders, markServed, markCancelled, formatFCFA, todayISO, formatDateLong } from '../services/api.js'

const TABS = [
  { key: 'all',       label: 'Toutes'   },
  { key: 'confirmed', label: 'À servir' },
  { key: 'served',    label: 'Servies'  },
  { key: 'cancelled', label: 'Annulées' },
]

function StatusLabel({ status }) {
  if (status === 'served')    return <span className="status-served">Servie</span>
  if (status === 'confirmed') return <span className="status-confirmed">À servir</span>
  return <span className="status-cancelled">Annulée</span>
}

export default function Orders() {
  const [date, setDate]       = useState(todayISO())
  const [data, setData]       = useState(null)
  const [orders, setOrders]   = useState([])
  const [loading, setLoading] = useState(true)
  const [tab, setTab]         = useState('all')
  const [search, setSearch]   = useState('')

  useEffect(() => {
    setLoading(true)
    getOrders(date).then(d => {
      setData(d)
      setOrders(d.orders ?? [])
      setLoading(false)
    })
  }, [date])

  const counts = useMemo(() => ({
    all:       orders.length,
    confirmed: orders.filter(o => o.status === 'confirmed').length,
    served:    orders.filter(o => o.status === 'served').length,
    cancelled: orders.filter(o => o.status === 'cancelled').length,
  }), [orders])

  const filtered = useMemo(() => {
    return orders
      .filter(o => tab === 'all' || o.status === tab)
      .filter(o => !search || o.student_name.toLowerCase().includes(search.toLowerCase()))
  }, [orders, tab, search])

  async function handleServe(id) {
    await markServed(id)
    setOrders(prev => prev.map(o => o.id === id ? { ...o, status: 'served' } : o))
  }

  async function handleCancel(id) {
    await markCancelled(id)
    setOrders(prev => prev.map(o => o.id === id ? { ...o, status: 'cancelled' } : o))
  }

  const dateLabel = formatDateLong(date)
  const dateCapitalized = dateLabel.charAt(0).toUpperCase() + dateLabel.slice(1)

  return (
    <div>
      {/* Header */}
      <div style={{ display: 'flex', alignItems: 'flex-start', justifyContent: 'space-between', marginBottom: 24 }}>
        <div>
          <h1 style={{ fontSize: 26, fontWeight: 700, marginBottom: 4 }}>Commandes du jour</h1>
          <p style={{ color: 'var(--text-secondary)', fontSize: 13 }}>
            {dateCapitalized} · service de 12 h à 13 h 30
          </p>
        </div>
        <div style={{ display: 'flex', gap: 10, alignItems: 'center' }}>
          <input
            type="date"
            value={date}
            onChange={e => setDate(e.target.value)}
            style={{
              padding: '9px 12px', borderRadius: 10, border: '1.5px solid var(--border)',
              background: 'var(--surface)', fontSize: 13, color: 'var(--text)',
            }}
          />
          <button style={{
            display: 'flex', alignItems: 'center', gap: 6,
            padding: '10px 18px', borderRadius: 10, border: '1.5px solid var(--border)',
            background: 'var(--surface)', fontSize: 13, fontWeight: 500, color: 'var(--text)',
          }}>
            <svg width="14" height="14" fill="none" stroke="currentColor" strokeWidth="2" viewBox="0 0 24 24">
              <path d="M21 15v4a2 2 0 01-2 2H5a2 2 0 01-2-2v-4" strokeLinecap="round" />
              <polyline points="7,10 12,15 17,10" strokeLinecap="round" strokeLinejoin="round" />
              <line x1="12" y1="15" x2="12" y2="3" strokeLinecap="round" />
            </svg>
            Exporter
          </button>
        </div>
      </div>

      {loading && <div style={{ color: 'var(--text-secondary)', padding: '40px 0' }}>Chargement…</div>}

      {!loading && (
        <>
          {/* À préparer */}
          <div className="card" style={{ marginBottom: 16 }}>
            <div style={{ fontFamily: 'Poppins', fontWeight: 600, fontSize: 14, marginBottom: 14 }}>À préparer</div>
            <div style={{ display: 'flex', gap: 10, flexWrap: 'wrap' }}>
              {(data?.summary ?? []).map((s, i) => (
                <div key={i} style={{
                  display: 'flex', alignItems: 'center', gap: 10,
                  background: 'var(--bg)', borderRadius: 10, padding: '10px 16px',
                  flex: '1 1 160px', minWidth: 160,
                }}>
                  <div style={{ width: 36, height: 36, borderRadius: 8, background: 'var(--surface-high)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                    <svg width="18" height="18" fill="none" stroke="var(--text-secondary)" strokeWidth="1.8" viewBox="0 0 24 24">
                      <path d="M18 8h1a4 4 0 010 8h-1" strokeLinecap="round" />
                      <path d="M2 8h16v9a4 4 0 01-4 4H6a4 4 0 01-4-4V8z" />
                      <line x1="6" y1="1" x2="6" y2="4" strokeLinecap="round" />
                      <line x1="10" y1="1" x2="10" y2="4" strokeLinecap="round" />
                      <line x1="14" y1="1" x2="14" y2="4" strokeLinecap="round" />
                    </svg>
                  </div>
                  <div>
                    <div style={{ fontWeight: 700, fontSize: 20, lineHeight: 1 }}>{s.count}</div>
                    <div style={{ fontSize: 12, color: 'var(--text-secondary)', marginTop: 2 }}>{s.dish_name}</div>
                  </div>
                </div>
              ))}
            </div>
          </div>

          {/* Table */}
          <div className="card">
            {/* Tabs + Search */}
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 16 }}>
              <div style={{ display: 'flex', gap: 0 }}>
                {TABS.map(t => (
                  <button
                    key={t.key}
                    onClick={() => setTab(t.key)}
                    style={{
                      padding: '8px 14px', fontSize: 13, fontWeight: tab === t.key ? 600 : 400,
                      color: tab === t.key ? 'var(--text)' : 'var(--text-secondary)',
                      background: 'none',
                      borderBottom: tab === t.key ? '2px solid var(--green)' : '2px solid transparent',
                      transition: 'color 0.15s',
                    }}
                  >
                    {t.label} <span style={{ fontSize: 12, opacity: 0.7 }}>{counts[t.key]}</span>
                  </button>
                ))}
              </div>
              <div style={{ position: 'relative' }}>
                <span style={{ position: 'absolute', left: 10, top: '50%', transform: 'translateY(-50%)', color: 'var(--text-secondary)' }}>
                  <svg width="14" height="14" fill="none" stroke="currentColor" strokeWidth="2" viewBox="0 0 24 24">
                    <circle cx="11" cy="11" r="8" /><line x1="21" y1="21" x2="16.65" y2="16.65" strokeLinecap="round" />
                  </svg>
                </span>
                <input
                  type="text"
                  placeholder="Rechercher un élève"
                  value={search}
                  onChange={e => setSearch(e.target.value)}
                  style={{
                    padding: '8px 12px 8px 32px', borderRadius: 8,
                    border: '1.5px solid var(--border)', background: 'var(--bg)',
                    fontSize: 13, color: 'var(--text)', width: 220,
                  }}
                />
              </div>
            </div>

            {/* Table */}
            <table style={{ width: '100%', borderCollapse: 'collapse' }}>
              <thead>
                <tr style={{ borderBottom: '1px solid var(--border)' }}>
                  {['N°', 'Élève', 'Plat', 'Créneau', 'Montant', 'Statut', ''].map(h => (
                    <th key={h} style={{ textAlign: 'left', padding: '0 8px 10px', fontSize: 12, color: 'var(--text-secondary)', fontWeight: 500 }}>{h}</th>
                  ))}
                </tr>
              </thead>
              <tbody>
                {filtered.length === 0 && (
                  <tr>
                    <td colSpan={7} style={{ padding: '24px 8px', color: 'var(--text-secondary)', textAlign: 'center', fontSize: 13 }}>
                      Aucune commande
                    </td>
                  </tr>
                )}
                {filtered.map(o => (
                  <tr key={o.id} style={{ borderBottom: '1px solid var(--bg)' }}>
                    <td style={{ padding: '12px 8px', fontSize: 13, color: 'var(--text-secondary)' }}>#{o.id}</td>
                    <td style={{ padding: '12px 8px' }}>
                      <div style={{ fontWeight: 500, fontSize: 13 }}>{o.student_name}</div>
                      <div style={{ fontSize: 11, color: 'var(--text-secondary)' }}>{o.class}</div>
                    </td>
                    <td style={{ padding: '12px 8px', fontSize: 13 }}>{o.dish_name}</td>
                    <td style={{ padding: '12px 8px', fontSize: 13, color: 'var(--text-secondary)' }}>{o.slot}</td>
                    <td style={{ padding: '12px 8px', fontSize: 13, fontWeight: 500 }}>{formatFCFA(o.amount_fcfa)}</td>
                    <td style={{ padding: '12px 8px' }}><StatusLabel status={o.status} /></td>
                    <td style={{ padding: '12px 0', textAlign: 'right' }}>
                      {o.status === 'confirmed' && (
                        <button
                          onClick={() => handleServe(o.id)}
                          style={{
                            padding: '6px 14px', borderRadius: 8,
                            background: 'var(--green)', color: '#fff',
                            fontSize: 12, fontWeight: 600,
                          }}
                        >
                          Marquer servie
                        </button>
                      )}
                      {o.status === 'served' && (
                        <button
                          onClick={() => handleCancel(o.id)}
                          style={{
                            padding: '6px 14px', borderRadius: 8,
                            border: '1px solid var(--border)', background: 'var(--surface)',
                            fontSize: 12, fontWeight: 500, color: 'var(--text-secondary)',
                          }}
                        >
                          Annuler
                        </button>
                      )}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </>
      )}
    </div>
  )
}
