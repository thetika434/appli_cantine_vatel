import { useState, useEffect, useCallback } from 'react'
import { getWeekDishes, createDish, updateDish, deleteDish, formatFCFA } from '../services/api.js'

const DAY_LABELS = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven']

function getMondayOf(isoDate) {
  const d = new Date(isoDate + 'T12:00:00')
  const day = d.getDay()
  const diff = day === 0 ? -6 : 1 - day
  d.setDate(d.getDate() + diff)
  return d.toISOString().slice(0, 10)
}

function addDays(iso, n) {
  const d = new Date(iso + 'T12:00:00')
  d.setDate(d.getDate() + n)
  return d.toISOString().slice(0, 10)
}

function weekLabel(mon, fri) {
  const m = new Date(mon + 'T12:00:00')
  const f = new Date(fri + 'T12:00:00')
  const monthF = f.toLocaleDateString('fr-FR', { month: 'long' })
  if (m.getMonth() === f.getMonth()) {
    return `Semaine du ${m.getDate()} au ${f.getDate()} ${monthF}`
  }
  return `Semaine du ${m.getDate()} ${m.toLocaleDateString('fr-FR', { month: 'short' })}. au ${f.getDate()} ${monthF}`
}

const EMPTY_FORM = {
  name: '', description: '', photo_url: '',
  price_fcfa: '', quantity: '', visible: true,
}

function Toggle({ value, onChange }) {
  return (
    <div
      onClick={() => onChange(!value)}
      style={{
        width: 44, height: 24, borderRadius: 12, flexShrink: 0,
        background: value ? 'var(--green)' : 'var(--border)',
        position: 'relative', cursor: 'pointer', transition: 'background 0.2s',
      }}
    >
      <div style={{
        position: 'absolute', top: 2,
        left: value ? 22 : 2,
        width: 20, height: 20, borderRadius: '50%',
        background: '#fff', transition: 'left 0.2s',
        boxShadow: '0 1px 3px rgba(0,0,0,0.25)',
      }} />
    </div>
  )
}

function IconEdit() {
  return (
    <svg width="16" height="16" fill="none" stroke="currentColor" strokeWidth="1.8" viewBox="0 0 24 24">
      <path d="M11 4H4a2 2 0 00-2 2v14a2 2 0 002 2h14a2 2 0 002-2v-7" strokeLinecap="round" strokeLinejoin="round" />
      <path d="M18.5 2.5a2.121 2.121 0 013 3L12 15l-4 1 1-4 9.5-9.5z" strokeLinecap="round" strokeLinejoin="round" />
    </svg>
  )
}

function IconTrash() {
  return (
    <svg width="16" height="16" fill="none" stroke="currentColor" strokeWidth="1.8" viewBox="0 0 24 24">
      <polyline points="3,6 5,6 21,6" strokeLinecap="round" />
      <path d="M19 6l-1 14a2 2 0 01-2 2H8a2 2 0 01-2-2L5 6" strokeLinecap="round" strokeLinejoin="round" />
      <path d="M10 11v6M14 11v6" strokeLinecap="round" />
      <path d="M9 6V4a1 1 0 011-1h4a1 1 0 011 1v2" strokeLinecap="round" />
    </svg>
  )
}

export default function Menus() {
  const today = new Date().toISOString().slice(0, 10)
  const [weekStart, setWeekStart] = useState(() => getMondayOf(today))
  const [days, setDays]           = useState([])
  const [selectedDay, setSelectedDay] = useState(today)
  const [loading, setLoading]     = useState(true)
  const [error, setError]         = useState('')
  const [panelOpen, setPanelOpen] = useState(false)
  const [editingDish, setEditingDish] = useState(null)
  const [form, setForm]           = useState(EMPTY_FORM)
  const [saving, setSaving]       = useState(false)
  const [saveError, setSaveError] = useState('')
  const [confirmId, setConfirmId] = useState(null)

  const weekEnd = addDays(weekStart, 4)
  const weekDates = Array.from({ length: 5 }, (_, i) => addDays(weekStart, i))
  const dishesMap = Object.fromEntries(days.map(d => [d.date, d.dishes ?? []]))
  const selectedDishes = dishesMap[selectedDay] ?? []

  const load = useCallback(() => {
    setLoading(true)
    setError('')
    getWeekDishes(weekStart)
      .then(data => setDays(data.days ?? []))
      .catch(err => setError(err.message || 'Erreur de chargement'))
      .finally(() => setLoading(false))
  }, [weekStart])

  useEffect(() => { load() }, [load])

  useEffect(() => {
    if (!weekDates.includes(selectedDay)) setSelectedDay(weekStart)
  }, [weekStart])

  function setField(key, val) {
    setForm(f => ({ ...f, [key]: val }))
  }

  function handlePhotoChange(e) {
    const file = e.target.files?.[0]
    if (!file) return
    const reader = new FileReader()
    reader.onload = (ev) => {
      const img = new Image()
      img.onload = () => {
        const MAX = 600
        let { width, height } = img
        if (width > MAX || height > MAX) {
          if (width > height) { height = Math.round(height * MAX / width); width = MAX }
          else { width = Math.round(width * MAX / height); height = MAX }
        }
        const canvas = document.createElement('canvas')
        canvas.width = width; canvas.height = height
        canvas.getContext('2d').drawImage(img, 0, 0, width, height)
        setField('photo_url', canvas.toDataURL('image/jpeg', 0.75))
      }
      img.src = ev.target.result
    }
    reader.readAsDataURL(file)
  }

  function openAdd() {
    setEditingDish(null)
    setForm({ ...EMPTY_FORM, serve_date: selectedDay })
    setSaveError('')
    setPanelOpen(true)
  }

  function openEdit(dish) {
    setEditingDish(dish)
    setForm({
      name:        dish.name ?? '',
      description: dish.description ?? '',
      photo_url:   dish.photo_url ?? '',
      price_fcfa:  dish.price_fcfa ?? '',
      quantity:    dish.quantity ?? '',
      visible:     dish.visible ?? true,
      serve_date:  dish.serve_date ?? selectedDay,
    })
    setSaveError('')
    setPanelOpen(true)
  }

  async function handleSave(e) {
    e.preventDefault()
    if (!form.name.trim())     return setSaveError('Le nom est requis')
    if (!form.price_fcfa)      return setSaveError('Le prix est requis')
    if (!form.quantity && form.quantity !== 0) return setSaveError('Le nombre de portions est requis')
    setSaving(true)
    setSaveError('')
    const payload = {
      name:        form.name.trim(),
      description: form.description.trim() || null,
      photo_url:   form.photo_url.trim() || null,
      price_fcfa:  Number(form.price_fcfa),
      quantity:    Number(form.quantity),
      visible:     form.visible,
      serve_date:  form.serve_date || selectedDay,
    }
    try {
      if (editingDish) await updateDish(editingDish.id, payload)
      else             await createDish(payload)
      setPanelOpen(false)
      load()
    } catch (err) {
      setSaveError(err.message || "Erreur lors de l'enregistrement")
    } finally {
      setSaving(false)
    }
  }

  async function handleDelete(dish) {
    if (confirmId !== dish.id) { setConfirmId(dish.id); return }
    try {
      await deleteDish(dish.id)
      setConfirmId(null)
      if (panelOpen && editingDish?.id === dish.id) setPanelOpen(false)
      load()
    } catch (err) {
      setError(err.message || 'Erreur lors de la suppression')
    }
  }

  const inputStyle = {
    width: '100%', padding: '10px 12px',
    border: '1.5px solid var(--border)', borderRadius: 8,
    background: 'var(--bg)', fontSize: 13, color: 'var(--text)',
  }

  const labelStyle = { display: 'block', fontSize: 12, fontWeight: 500, color: 'var(--text-secondary)', marginBottom: 4 }

  return (
    <div>
      {/* Header */}
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 24 }}>
        <h1 style={{ fontSize: 26, fontWeight: 700 }}>Menus</h1>
        <button
          onClick={openAdd}
          style={{ display: 'flex', alignItems: 'center', gap: 6, padding: '10px 18px', borderRadius: 10, background: 'var(--orange)', color: '#fff', fontSize: 14, fontWeight: 600 }}
        >
          + Ajouter un plat
        </button>
      </div>

      {/* Week navigation */}
      <div style={{ display: 'flex', alignItems: 'center', gap: 12, marginBottom: 20 }}>
        <button
          onClick={() => setWeekStart(w => addDays(w, -7))}
          style={{ width: 32, height: 32, borderRadius: 8, border: '1.5px solid var(--border)', background: 'var(--surface)', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 16, color: 'var(--text)' }}
        >‹</button>
        <span style={{ fontWeight: 600, fontSize: 15 }}>{weekLabel(weekStart, weekEnd)}</span>
        <button
          onClick={() => setWeekStart(w => addDays(w, 7))}
          style={{ width: 32, height: 32, borderRadius: 8, border: '1.5px solid var(--border)', background: 'var(--surface)', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 16, color: 'var(--text)' }}
        >›</button>
      </div>

      {error && (
        <div style={{ color: '#b91c1c', background: '#fff0f0', border: '1px solid #fca5a5', borderRadius: 10, padding: '12px 16px', marginBottom: 16 }}>
          {error}
        </div>
      )}

      {/* Main layout */}
      <div style={{ display: 'flex', gap: 16, alignItems: 'flex-start' }}>

        {/* Left column */}
        <div style={{ flex: 1, minWidth: 0 }}>
          {/* Day tabs */}
          <div className="card" style={{ display: 'flex', gap: 8, padding: 12, marginBottom: 16 }}>
            {weekDates.map((date, i) => {
              const count = (dishesMap[date] ?? []).length
              const active = selectedDay === date
              const d = new Date(date + 'T12:00:00')
              return (
                <button
                  key={date}
                  onClick={() => setSelectedDay(date)}
                  style={{
                    flex: 1, padding: '10px 6px', borderRadius: 10,
                    background: active ? 'var(--green)' : 'var(--bg)',
                    color: active ? '#fff' : 'var(--text)',
                    fontWeight: active ? 700 : 400,
                    textAlign: 'center', lineHeight: 1.3,
                    border: 'none',
                  }}
                >
                  <div style={{ fontSize: 11, opacity: active ? 0.9 : 0.6 }}>{DAY_LABELS[i]}</div>
                  <div style={{ fontSize: 22, fontWeight: 700 }}>{d.getDate()}</div>
                  <div style={{ fontSize: 11, fontWeight: 600 }}>
                    {count > 0 ? `${count} plat${count > 1 ? 's' : ''}` : '—'}
                  </div>
                </button>
              )
            })}
          </div>

          {/* Dish list */}
          {loading && (
            <div style={{ color: 'var(--text-secondary)', padding: '32px 0', textAlign: 'center' }}>Chargement…</div>
          )}

          {!loading && selectedDishes.length === 0 && (
            <div className="card" style={{ textAlign: 'center', padding: '40px 20px', color: 'var(--text-secondary)' }}>
              Aucun plat prévu ce jour.
              <div style={{ marginTop: 12 }}>
                <button onClick={openAdd} style={{ background: 'none', color: 'var(--orange)', fontWeight: 600, fontSize: 14 }}>
                  + Ajouter un plat
                </button>
              </div>
            </div>
          )}

          {selectedDishes.map(dish => (
            <div
              key={dish.id}
              className="card"
              style={{
                display: 'flex', alignItems: 'center', gap: 14, marginBottom: 10,
                border: editingDish?.id === dish.id ? '1.5px solid var(--green)' : '1.5px solid transparent',
              }}
            >
              {/* Photo */}
              <div style={{
                width: 72, height: 72, borderRadius: 10, flexShrink: 0,
                background: 'var(--surface-high)', overflow: 'hidden',
                display: 'flex', alignItems: 'center', justifyContent: 'center',
              }}>
                {dish.photo_url
                  ? <img src={dish.photo_url} alt={dish.name} style={{ width: '100%', height: '100%', objectFit: 'cover' }} onError={e => { e.target.style.display = 'none' }} />
                  : <svg width="28" height="28" fill="none" stroke="var(--text-secondary)" strokeWidth="1.5" viewBox="0 0 24 24"><path d="M18 8h1a4 4 0 010 8h-1"/><path d="M2 8h16v9a4 4 0 01-4 4H6a4 4 0 01-4-4V8z"/><line x1="6" y1="1" x2="6" y2="4" strokeLinecap="round"/><line x1="10" y1="1" x2="10" y2="4" strokeLinecap="round"/><line x1="14" y1="1" x2="14" y2="4" strokeLinecap="round"/></svg>
                }
              </div>

              {/* Info */}
              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{ fontWeight: 600, fontSize: 14 }}>{dish.name}</div>
                <div style={{ fontSize: 12, color: 'var(--text-secondary)', marginTop: 3 }}>
                  {dish.quantity} portions ·{' '}
                  {dish.visible
                    ? <span style={{ color: 'var(--green)', fontWeight: 500 }}>Visible</span>
                    : <span style={{ color: 'var(--text-secondary)' }}>Masqué</span>
                  }
                </div>
              </div>

              {/* Price */}
              <span style={{ color: 'var(--orange)', fontWeight: 700, fontSize: 15, whiteSpace: 'nowrap' }}>
                {formatFCFA(dish.price_fcfa)}
              </span>

              {/* Actions */}
              <button
                onClick={() => openEdit(dish)}
                title="Modifier"
                style={{ padding: 8, borderRadius: 8, background: 'var(--bg)', color: 'var(--text-secondary)' }}
              >
                <IconEdit />
              </button>
              <button
                onClick={() => handleDelete(dish)}
                title={confirmId === dish.id ? 'Cliquer pour confirmer' : 'Supprimer'}
                style={{
                  padding: 8, borderRadius: 8,
                  background: confirmId === dish.id ? '#fef2f2' : 'var(--bg)',
                  color: confirmId === dish.id ? '#b91c1c' : 'var(--text-secondary)',
                  fontWeight: confirmId === dish.id ? 600 : 400,
                  fontSize: confirmId === dish.id ? 11 : 14,
                  whiteSpace: 'nowrap',
                }}
              >
                {confirmId === dish.id ? 'Supprimer ?' : <IconTrash />}
              </button>
            </div>
          ))}
        </div>

        {/* Right panel — form */}
        {panelOpen && (
          <div style={{ width: 320, flexShrink: 0 }}>
            <div className="card">
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 16 }}>
                <h3 style={{ fontSize: 16, fontWeight: 700 }}>
                  {editingDish ? 'Modifier le plat' : 'Nouveau plat'}
                </h3>
                <button onClick={() => setPanelOpen(false)} style={{ background: 'none', color: 'var(--text-secondary)', fontSize: 20, lineHeight: 1 }}>×</button>
              </div>

              <form onSubmit={handleSave}>
                {/* Photo upload */}
                <div style={{ marginBottom: 14 }}>
                  <label style={labelStyle}>Photo du plat</label>
                  <input id="photo-file-input" type="file" accept="image/*" style={{ display: 'none' }} onChange={handlePhotoChange} />
                  <div
                    onClick={() => document.getElementById('photo-file-input').click()}
                    style={{
                      width: '100%', height: 130, borderRadius: 10, overflow: 'hidden',
                      background: 'var(--bg)', border: '1.5px dashed var(--border)',
                      display: 'flex', alignItems: 'center', justifyContent: 'center',
                      cursor: 'pointer', marginBottom: 6, position: 'relative',
                    }}
                  >
                    {form.photo_url ? (
                      <img src={form.photo_url} alt="Aperçu" style={{ width: '100%', height: '100%', objectFit: 'cover' }} onError={e => { e.target.style.display = 'none' }} />
                    ) : (
                      <div style={{ textAlign: 'center', color: 'var(--text-secondary)' }}>
                        <svg width="28" height="28" fill="none" stroke="currentColor" strokeWidth="1.5" viewBox="0 0 24 24" style={{ display: 'block', margin: '0 auto 6px' }}>
                          <rect x="3" y="3" width="18" height="18" rx="2" /><circle cx="8.5" cy="8.5" r="1.5" fill="currentColor" stroke="none" />
                          <polyline points="21,15 16,10 5,21" strokeLinecap="round" strokeLinejoin="round" />
                        </svg>
                        <div style={{ fontSize: 12 }}>Cliquer pour importer une photo</div>
                      </div>
                    )}
                    {form.photo_url && (
                      <div style={{
                        position: 'absolute', bottom: 6, right: 6,
                        background: 'rgba(0,0,0,0.5)', color: '#fff',
                        borderRadius: 6, padding: '3px 8px', fontSize: 11,
                      }}>
                        Changer
                      </div>
                    )}
                  </div>
                </div>

                {/* Nom */}
                <div style={{ marginBottom: 12 }}>
                  <label style={labelStyle}>Nom du plat *</label>
                  <input
                    type="text"
                    placeholder="Alloco poulet braisé"
                    value={form.name}
                    onChange={e => setField('name', e.target.value)}
                    style={inputStyle}
                    required
                  />
                </div>

                {/* Prix + Portions */}
                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10, marginBottom: 12 }}>
                  <div>
                    <label style={labelStyle}>Prix (FCFA) *</label>
                    <div style={{ position: 'relative' }}>
                      <input
                        type="number"
                        placeholder="1000"
                        min="5" step="5"
                        value={form.price_fcfa}
                        onChange={e => setField('price_fcfa', e.target.value)}
                        style={{ ...inputStyle, paddingRight: 46 }}
                        required
                      />
                      <span style={{ position: 'absolute', right: 10, top: '50%', transform: 'translateY(-50%)', fontSize: 11, color: 'var(--text-secondary)' }}>FCFA</span>
                    </div>
                  </div>
                  <div>
                    <label style={labelStyle}>Portions *</label>
                    <input
                      type="number"
                      placeholder="30"
                      min="0"
                      value={form.quantity}
                      onChange={e => setField('quantity', e.target.value)}
                      style={inputStyle}
                      required
                    />
                  </div>
                </div>

                {/* Description */}
                <div style={{ marginBottom: 12 }}>
                  <label style={labelStyle}>Description</label>
                  <textarea
                    placeholder="Banane plantain frite, poulet braisé…"
                    value={form.description}
                    onChange={e => setField('description', e.target.value)}
                    rows={3}
                    style={{ ...inputStyle, resize: 'vertical', lineHeight: 1.5 }}
                  />
                </div>

                {/* Serve date */}
                <div style={{ marginBottom: 12 }}>
                  <label style={labelStyle}>Date de service *</label>
                  <input
                    type="date"
                    value={form.serve_date || selectedDay}
                    onChange={e => setField('serve_date', e.target.value)}
                    style={inputStyle}
                    required
                  />
                </div>

                {/* Visible toggle */}
                <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 20, padding: '12px 0', borderTop: '1px solid var(--border)' }}>
                  <span style={{ fontSize: 14, fontWeight: 500 }}>Visible dans l'app</span>
                  <Toggle value={form.visible} onChange={v => setField('visible', v)} />
                </div>

                {saveError && (
                  <div style={{ color: '#b91c1c', background: '#fff0f0', border: '1px solid #fca5a5', borderRadius: 8, padding: '8px 12px', fontSize: 13, marginBottom: 12 }}>
                    {saveError}
                  </div>
                )}

                <div style={{ display: 'flex', gap: 8 }}>
                  <button
                    type="button"
                    onClick={() => setPanelOpen(false)}
                    style={{ flex: 1, padding: '11px', borderRadius: 8, border: '1.5px solid var(--border)', background: 'var(--surface)', fontSize: 14, fontWeight: 500, color: 'var(--text)' }}
                  >
                    Annuler
                  </button>
                  <button
                    type="submit"
                    disabled={saving}
                    style={{ flex: 1, padding: '11px', borderRadius: 8, background: 'var(--orange)', color: '#fff', fontSize: 14, fontWeight: 600, opacity: saving ? 0.7 : 1 }}
                  >
                    {saving ? 'Enregistrement…' : 'Enregistrer'}
                  </button>
                </div>
              </form>
            </div>
          </div>
        )}
      </div>
    </div>
  )
}
