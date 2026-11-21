import { useState } from 'react'
import { login } from '../services/api.js'

export default function Login({ onLogin }) {
  const [matricule, setMatricule] = useState('')
  const [password, setPassword]   = useState('')
  const [showPwd, setShowPwd]     = useState(false)
  const [loading, setLoading]     = useState(false)
  const [error, setError]         = useState('')

  async function handleSubmit(e) {
    e.preventDefault()
    if (!matricule || !password) return
    setLoading(true)
    setError('')
    try {
      const data = await login(matricule, password)
      localStorage.setItem('admin_token', data.token)
      localStorage.setItem('admin_user', JSON.stringify(data.user))
      onLogin(data.user)
    } catch (err) {
      setError(err.message || 'Identifiants invalides')
    } finally {
      setLoading(false)
    }
  }

  return (
    <div style={{ display: 'flex', minHeight: '100vh' }}>
      {/* Left — visual */}
      <div style={{
        flex: 1,
        background: 'linear-gradient(160deg, #2a1e0d 0%, #1a3020 40%, #0f1f14 100%)',
        display: 'flex', flexDirection: 'column', justifyContent: 'flex-end',
        padding: '48px', position: 'relative', overflow: 'hidden',
      }}>
        {/* decorative circles */}
        <div style={{ position: 'absolute', top: -60, left: -60, width: 240, height: 240, borderRadius: '50%', background: 'rgba(255,138,31,0.08)' }} />
        <div style={{ position: 'absolute', top: 80, right: 40, width: 160, height: 160, borderRadius: '50%', background: 'rgba(52,193,123,0.07)' }} />
        <div style={{ position: 'absolute', bottom: 80, right: -40, width: 200, height: 200, borderRadius: '50%', background: 'rgba(255,138,31,0.06)' }} />

        <h1 style={{ fontFamily: 'Poppins', fontSize: 'clamp(32px, 4vw, 52px)', fontWeight: 700, lineHeight: 1.15, color: '#fff', position: 'relative', zIndex: 1 }}>
          Gérez la cantine<br />
          <span style={{ color: '#FF8A1F' }}>sans </span>
          <span style={{ color: '#34C17B' }}>stress</span>
        </h1>
      </div>

      {/* Right — form */}
      <div style={{
        width: 480, flexShrink: 0,
        background: 'var(--bg)',
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        padding: '48px 48px',
      }}>
        <div style={{ width: '100%', maxWidth: 360 }}>
          <h2 style={{ fontFamily: 'Poppins', fontSize: 26, fontWeight: 700, marginBottom: 6 }}>
            Espace admin
          </h2>
          <p style={{ color: 'var(--text-secondary)', marginBottom: 32 }}>
            Connectez-vous pour continuer.
          </p>

          <form onSubmit={handleSubmit}>
            {/* E-mail / matricule */}
            <label style={{ display: 'block', marginBottom: 16 }}>
              <div style={{ fontSize: 13, fontWeight: 500, marginBottom: 6 }}>E-mail</div>
              <div style={{ position: 'relative' }}>
                <span style={{ position: 'absolute', left: 14, top: '50%', transform: 'translateY(-50%)', color: 'var(--text-secondary)' }}>
                  <svg width="16" height="16" fill="none" stroke="currentColor" strokeWidth="1.8" viewBox="0 0 24 24">
                    <rect x="2" y="4" width="20" height="16" rx="2" />
                    <polyline points="2,4 12,13 22,4" strokeLinecap="round" strokeLinejoin="round" />
                  </svg>
                </span>
                <input
                  type="text"
                  placeholder="a.kouassi@exemple.ci"
                  value={matricule}
                  onChange={e => setMatricule(e.target.value)}
                  style={{
                    width: '100%', padding: '13px 14px 13px 40px',
                    border: '1.5px solid var(--border)',
                    borderRadius: 10, background: 'var(--surface)',
                    fontSize: 14, color: 'var(--text)',
                  }}
                />
              </div>
            </label>

            {/* Mot de passe */}
            <label style={{ display: 'block', marginBottom: 10 }}>
              <div style={{ fontSize: 13, fontWeight: 500, marginBottom: 6 }}>Mot de passe</div>
              <div style={{ position: 'relative' }}>
                <span style={{ position: 'absolute', left: 14, top: '50%', transform: 'translateY(-50%)', color: 'var(--text-secondary)' }}>
                  <svg width="16" height="16" fill="none" stroke="currentColor" strokeWidth="1.8" viewBox="0 0 24 24">
                    <rect x="3" y="11" width="18" height="11" rx="2" />
                    <path d="M7 11V7a5 5 0 0110 0v4" strokeLinecap="round" />
                  </svg>
                </span>
                <input
                  type={showPwd ? 'text' : 'password'}
                  placeholder="••••••••••"
                  value={password}
                  onChange={e => setPassword(e.target.value)}
                  style={{
                    width: '100%', padding: '13px 44px 13px 40px',
                    border: '1.5px solid var(--border)',
                    borderRadius: 10, background: 'var(--surface)',
                    fontSize: 14, color: 'var(--text)',
                  }}
                />
                <button
                  type="button"
                  onClick={() => setShowPwd(v => !v)}
                  style={{ position: 'absolute', right: 14, top: '50%', transform: 'translateY(-50%)', background: 'none', color: 'var(--text-secondary)' }}
                >
                  <svg width="16" height="16" fill="none" stroke="currentColor" strokeWidth="1.8" viewBox="0 0 24 24">
                    {showPwd
                      ? <><path d="M17.94 17.94A10.07 10.07 0 0112 20c-7 0-11-8-11-8a18.45 18.45 0 015.06-5.94" /><path d="M9.9 4.24A9.12 9.12 0 0112 4c7 0 11 8 11 8a18.5 18.5 0 01-2.16 3.19" /><line x1="1" y1="1" x2="23" y2="23" /></>
                      : <><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z" /><circle cx="12" cy="12" r="3" /></>
                    }
                  </svg>
                </button>
              </div>
            </label>

            <div style={{ textAlign: 'right', marginBottom: 24 }}>
              <span style={{ color: 'var(--green)', fontSize: 13, cursor: 'pointer' }}>
                Mot de passe oublié ?
              </span>
            </div>

            {error && (
              <div style={{ background: '#fff0f0', border: '1px solid #fca5a5', borderRadius: 8, padding: '10px 14px', color: '#b91c1c', fontSize: 13, marginBottom: 16 }}>
                {error}
              </div>
            )}

            <button type="submit" className="btn-primary" disabled={loading}>
              {loading ? 'Connexion…' : 'Se connecter'}
            </button>
          </form>
        </div>
      </div>
    </div>
  )
}
