import { useState, useEffect } from 'react'
import { getDashboard, formatFCFA, todayISO, formatDateLong } from '../services/api.js'

function StatusLabel({ status }) {
  if (status === 'served')    return <span className="status-served">Servie</span>
  if (status === 'confirmed') return <span className="status-confirmed">À servir</span>
  return <span className="status-cancelled">Annulée</span>
}

function BarChart({ weekly }) {
  const max = Math.max(...weekly.map(d => d.count))
  const todayIdx = weekly.length - 1

  return (
    <div style={{ display: 'flex', alignItems: 'flex-end', gap: 8, height: 160, paddingTop: 24 }}>
      {weekly.map((d, i) => {
        const isToday = i === todayIdx
        const pct = max > 0 ? d.count / max : 0
        return (
          <div key={i} style={{ flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 4 }}>
            <span style={{ fontSize: 11, fontWeight: 600, color: isToday ? 'var(--orange)' : 'var(--text-secondary)' }}>
              {d.count}
            </span>
            <div style={{
              width: '100%',
              height: `${Math.round(pct * 120)}px`,
              minHeight: 4,
              background: isToday ? 'var(--orange)' : '#C5DEC8',
              borderRadius: '4px 4px 0 0',
              transition: 'height 0.3s',
            }} />
            <span style={{ fontSize: 11, color: 'var(--text-secondary)' }}>{d.day}</span>
          </div>
        )
      })}
    </div>
  )
}

export default function Dashboard() {
  const [data, setData] = useState(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')

  useEffect(() => {
    getDashboard(todayISO())
      .then(d => setData(d))
      .catch(err => setError(err.message || 'Erreur de chargement'))
      .finally(() => setLoading(false))
  }, [])

  if (loading) return <div style={{ color: 'var(--text-secondary)', padding: 40 }}>Chargement…</div>
  if (error)   return <div style={{ color: '#b91c1c', background: '#fff0f0', border: '1px solid #fca5a5', borderRadius: 10, padding: '16px 20px', margin: '8px 0' }}>{error}</div>
  if (!data)   return null

  const dateLabel = formatDateLong(todayISO())
  const dateCapitalized = dateLabel.charAt(0).toUpperCase() + dateLabel.slice(1)

  const served = data.served ?? 0
  const total  = data.today_orders ?? 0
  const cancelled = data.cancelled ?? 0

  const topMax = data.top_dishes?.[0]?.count ?? 1

  return (
    <div>
      {/* Header */}
      <div style={{ display: 'flex', alignItems: 'flex-start', justifyContent: 'space-between', marginBottom: 28 }}>
        <div>
          <h1 style={{ fontSize: 26, fontWeight: 700, marginBottom: 4 }}>
            Bonjour, Mme Kouassi
          </h1>
          <p style={{ color: 'var(--text-secondary)' }}>{dateCapitalized}</p>
        </div>
        <div style={{ display: 'flex', gap: 10 }}>
          <button
            style={{ display: 'flex', alignItems: 'center', gap: 6, padding: '10px 18px', borderRadius: 10, border: '1.5px solid var(--border)', background: 'var(--surface)', fontSize: 14, fontWeight: 500, color: 'var(--text)' }}
          >
            <svg width="16" height="16" fill="none" stroke="currentColor" strokeWidth="1.8" viewBox="0 0 24 24">
              <line x1="8" y1="6" x2="21" y2="6" strokeLinecap="round" />
              <line x1="8" y1="12" x2="21" y2="12" strokeLinecap="round" />
              <line x1="8" y1="18" x2="21" y2="18" strokeLinecap="round" />
              <circle cx="3.5" cy="6"  r="1" fill="currentColor" stroke="none" />
              <circle cx="3.5" cy="12" r="1" fill="currentColor" stroke="none" />
              <circle cx="3.5" cy="18" r="1" fill="currentColor" stroke="none" />
            </svg>
            Voir les commandes
          </button>
          <button style={{ display: 'flex', alignItems: 'center', gap: 6, padding: '10px 18px', borderRadius: 10, background: 'var(--orange)', color: '#fff', fontSize: 14, fontWeight: 600 }}>
            + Nouveau plat
          </button>
        </div>
      </div>

      {/* KPI cards */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: 16, marginBottom: 20 }}>
        <div className="card" style={{ background: 'var(--orange)', color: '#fff' }}>
          <div style={{ fontSize: 12, fontWeight: 500, opacity: 0.85, marginBottom: 8 }}>Commandes du jour</div>
          <div style={{ fontFamily: 'Poppins', fontSize: 36, fontWeight: 700, lineHeight: 1 }}>{total}</div>
          <div style={{ fontSize: 12, opacity: 0.85, marginTop: 6 }}>+12 par rapport à jeudi</div>
        </div>
        <div className="card">
          <div style={{ fontSize: 12, color: 'var(--text-secondary)', marginBottom: 8 }}>Recette du jour</div>
          <div style={{ fontFamily: 'Poppins', fontSize: 22, fontWeight: 700 }}>{formatFCFA(data.revenue_fcfa ?? 0)}</div>
          <div style={{ fontSize: 12, color: 'var(--green)', marginTop: 6, fontWeight: 500 }}>+8 % cette semaine</div>
        </div>
        <div className="card">
          <div style={{ fontSize: 12, color: 'var(--text-secondary)', marginBottom: 8 }}>Repas servis</div>
          <div style={{ fontFamily: 'Poppins', fontSize: 28, fontWeight: 700 }}>{served} / {total}</div>
          <div style={{ fontSize: 12, color: 'var(--text-secondary)', marginTop: 6 }}>{total - served} encore à servir</div>
        </div>
        <div className="card">
          <div style={{ fontSize: 12, color: 'var(--text-secondary)', marginBottom: 8 }}>Annulations</div>
          <div style={{ fontFamily: 'Poppins', fontSize: 36, fontWeight: 700 }}>{cancelled}</div>
          <div style={{ fontSize: 12, color: 'var(--text-secondary)', marginTop: 6 }}>
            {total > 0 ? ((cancelled / total) * 100).toFixed(1) : 0} % des commandes
          </div>
        </div>
      </div>

      {/* Charts row */}
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 320px', gap: 16, marginBottom: 20 }}>
        {/* Bar chart */}
        <div className="card">
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 4 }}>
            <div>
              <div style={{ fontFamily: 'Poppins', fontWeight: 600, fontSize: 15 }}>Commandes</div>
              <div style={{ fontSize: 12, color: 'var(--text-secondary)' }}>Cette semaine · {data.weekly?.reduce((s, d) => s + d.count, 0) ?? 0} au total</div>
            </div>
            <div style={{ display: 'flex', gap: 4 }}>
              {['Semaine', 'Mois'].map((l, i) => (
                <button key={l} style={{
                  padding: '5px 12px', borderRadius: 8, fontSize: 13,
                  background: i === 0 ? 'var(--surface-high)' : 'transparent',
                  border: '1px solid var(--border)',
                  fontWeight: i === 0 ? 600 : 400,
                  color: 'var(--text)',
                }}>
                  {l}
                </button>
              ))}
            </div>
          </div>
          <BarChart weekly={data.weekly ?? []} />
        </div>

        {/* Top dishes */}
        <div className="card">
          <div style={{ fontFamily: 'Poppins', fontWeight: 600, fontSize: 15, marginBottom: 16 }}>Plats du jour</div>
          {(data.top_dishes ?? []).map((d, i) => (
            <div key={i} style={{ marginBottom: 14 }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 4 }}>
                <span style={{ fontSize: 13, fontWeight: 500 }}>{d.name}</span>
                <span style={{ fontSize: 13, fontWeight: 600 }}>{d.count}</span>
              </div>
              <div style={{ height: 4, background: 'var(--surface-high)', borderRadius: 2 }}>
                <div style={{ height: '100%', width: `${(d.count / topMax) * 100}%`, borderRadius: 2, background: i === 0 ? 'var(--orange)' : 'var(--green)' }} />
              </div>
            </div>
          ))}
        </div>
      </div>

      {/* Élèves à solde faible */}
      {data.low_balance_students?.length > 0 && (
        <div className="card" style={{ marginBottom: 20, borderLeft: '3px solid var(--orange)' }}>
          <div style={{ fontFamily: 'Poppins', fontWeight: 600, fontSize: 15, marginBottom: 12 }}>
            Élèves à solde faible
          </div>
          <div style={{ display: 'flex', gap: 12, flexWrap: 'wrap' }}>
            {data.low_balance_students.map((s, i) => (
              <div key={i} style={{
                display: 'flex', alignItems: 'center', gap: 8,
                background: 'var(--bg)', borderRadius: 8, padding: '8px 14px',
              }}>
                <span style={{ fontWeight: 500 }}>{s.name}</span>
                <span style={{ color: 'var(--text-secondary)', fontSize: 12 }}>·</span>
                <span style={{ fontSize: 12, color: 'var(--text-secondary)' }}>{s.class}</span>
                <span style={{ color: 'var(--orange)', fontWeight: 700 }}>{formatFCFA(s.balance)}</span>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* Recent orders */}
      <div className="card">
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 16 }}>
          <div style={{ fontFamily: 'Poppins', fontWeight: 600, fontSize: 15 }}>Dernières commandes</div>
          <span style={{ color: 'var(--green)', fontSize: 13, fontWeight: 500, cursor: 'pointer' }}>Tout voir</span>
        </div>
        <table style={{ width: '100%', borderCollapse: 'collapse' }}>
          <thead>
            <tr style={{ borderBottom: '1px solid var(--border)' }}>
              {['Élève', 'Plat', 'Heure', 'Montant', 'Statut'].map(h => (
                <th key={h} style={{ textAlign: 'left', padding: '0 0 10px', fontSize: 12, color: 'var(--text-secondary)', fontWeight: 500 }}>{h}</th>
              ))}
            </tr>
          </thead>
          <tbody>
            {(data.recent_orders ?? []).map(o => (
              <tr key={o.id} style={{ borderBottom: '1px solid var(--bg)' }}>
                <td style={{ padding: '12px 0' }}>
                  <div style={{ fontWeight: 500 }}>{o.student_name}</div>
                  <div style={{ fontSize: 12, color: 'var(--text-secondary)' }}>{o.class}</div>
                </td>
                <td style={{ padding: '12px 8px', fontSize: 13 }}>{o.dish_name}</td>
                <td style={{ padding: '12px 8px', fontSize: 13, color: 'var(--text-secondary)' }}>
                  {o.slot?.split('–')[0]?.trim()}
                </td>
                <td style={{ padding: '12px 8px', fontSize: 13, fontWeight: 500 }}>{formatFCFA(o.amount_fcfa)}</td>
                <td style={{ padding: '12px 0' }}><StatusLabel status={o.status} /></td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  )
}
