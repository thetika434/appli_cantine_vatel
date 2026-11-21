const NAV = [
  {
    id: 'dashboard', label: 'Tableau de bord',
    icon: (
      <svg width="18" height="18" fill="none" stroke="currentColor" strokeWidth="1.8" viewBox="0 0 24 24">
        <rect x="3" y="3" width="7" height="7" rx="1.5" />
        <rect x="14" y="3" width="7" height="7" rx="1.5" />
        <rect x="3" y="14" width="7" height="7" rx="1.5" />
        <rect x="14" y="14" width="7" height="7" rx="1.5" />
      </svg>
    ),
  },
  {
    id: 'orders', label: 'Commandes',
    icon: (
      <svg width="18" height="18" fill="none" stroke="currentColor" strokeWidth="1.8" viewBox="0 0 24 24">
        <line x1="8" y1="6" x2="21" y2="6" strokeLinecap="round" />
        <line x1="8" y1="12" x2="21" y2="12" strokeLinecap="round" />
        <line x1="8" y1="18" x2="21" y2="18" strokeLinecap="round" />
        <circle cx="3.5" cy="6"  r="1" fill="currentColor" stroke="none" />
        <circle cx="3.5" cy="12" r="1" fill="currentColor" stroke="none" />
        <circle cx="3.5" cy="18" r="1" fill="currentColor" stroke="none" />
      </svg>
    ),
  },
  {
    id: 'menus', label: 'Menus',
    icon: (
      <svg width="18" height="18" fill="none" stroke="currentColor" strokeWidth="1.8" viewBox="0 0 24 24">
        <path d="M18 8h1a4 4 0 010 8h-1" strokeLinecap="round" />
        <path d="M2 8h16v9a4 4 0 01-4 4H6a4 4 0 01-4-4V8z" />
        <line x1="6" y1="1" x2="6" y2="4" strokeLinecap="round" />
        <line x1="10" y1="1" x2="10" y2="4" strokeLinecap="round" />
        <line x1="14" y1="1" x2="14" y2="4" strokeLinecap="round" />
      </svg>
    ),
  },
]

export default function Layout({ user, page, onNavigate, onLogout, children }) {
  const initials = user.full_name
    ? user.full_name.split(' ').slice(0, 2).map(w => w[0]).join('').toUpperCase()
    : 'AD'

  return (
    <div style={{ display: 'flex', minHeight: '100vh' }}>
      {/* Sidebar */}
      <aside style={{
        width: 'var(--sidebar-w)', flexShrink: 0,
        background: 'var(--surface)', borderRight: '1px solid var(--border)',
        display: 'flex', flexDirection: 'column',
        position: 'fixed', top: 0, left: 0, bottom: 0,
      }}>
        {/* Logo */}
        <div style={{ padding: '24px 20px 20px', borderBottom: '1px solid var(--border)' }}>
          <span style={{ fontFamily: 'Poppins', fontSize: 18, fontWeight: 700, color: 'var(--text)' }}>
            Espace{' '}
          </span>
          <span style={{ fontFamily: 'Poppins', fontSize: 18, fontWeight: 700, color: 'var(--orange)' }}>
            admin
          </span>
        </div>

        {/* Nav */}
        <nav style={{ flex: 1, padding: '12px 10px' }}>
          {NAV.map(item => {
            const active = page === item.id
            return (
              <button
                key={item.id}
                onClick={() => onNavigate(item.id)}
                style={{
                  display: 'flex', alignItems: 'center', gap: 10,
                  width: '100%', padding: '10px 12px', borderRadius: 8,
                  background: active ? 'var(--surface-high)' : 'transparent',
                  color: active ? 'var(--green)' : 'var(--text-secondary)',
                  fontWeight: active ? 600 : 400,
                  fontSize: 14, marginBottom: 4,
                  transition: 'background 0.15s, color 0.15s',
                }}
              >
                {item.icon}
                {item.label}
              </button>
            )
          })}
        </nav>

        {/* User + Logout */}
        <div style={{
          padding: '14px 16px', borderTop: '1px solid var(--border)',
          display: 'flex', alignItems: 'center', gap: 10,
        }}>
          <div style={{
            width: 36, height: 36, borderRadius: '50%',
            background: 'var(--orange)', color: '#fff',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            fontWeight: 700, fontSize: 13, flexShrink: 0,
          }}>
            {initials}
          </div>
          <div style={{ flex: 1, minWidth: 0 }}>
            <div style={{ fontWeight: 600, fontSize: 13, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>
              {user.full_name ? user.full_name.split(' ').slice(-1)[0] + ' ' + user.full_name.split(' ')[0][0] + '.' : 'Admin'}
            </div>
            <div style={{ color: 'var(--text-secondary)', fontSize: 12 }}>Gérante</div>
          </div>
          <button
            onClick={onLogout}
            title="Se déconnecter"
            style={{ background: 'none', color: 'var(--text-secondary)', padding: 4, flexShrink: 0 }}
          >
            <svg width="18" height="18" fill="none" stroke="currentColor" strokeWidth="1.8" viewBox="0 0 24 24">
              <path d="M9 21H5a2 2 0 01-2-2V5a2 2 0 012-2h4" strokeLinecap="round" />
              <polyline points="16,17 21,12 16,7" strokeLinecap="round" strokeLinejoin="round" />
              <line x1="21" y1="12" x2="9" y2="12" strokeLinecap="round" />
            </svg>
          </button>
        </div>
      </aside>

      {/* Main content */}
      <main style={{ marginLeft: 'var(--sidebar-w)', flex: 1, padding: '32px', minHeight: '100vh' }}>
        {children}
      </main>
    </div>
  )
}
