import { useState, useEffect } from 'react'
import Login from './pages/Login.jsx'
import Dashboard from './pages/Dashboard.jsx'
import Orders from './pages/Orders.jsx'
import Menus from './pages/Menus.jsx'
import Layout from './components/Layout.jsx'

export default function App() {
  const [user, setUser] = useState(() => {
    try { return JSON.parse(localStorage.getItem('admin_user')) } catch { return null }
  })
  const [page, setPage] = useState('dashboard')

  useEffect(() => {
    const onStorage = () => {
      try { setUser(JSON.parse(localStorage.getItem('admin_user'))) } catch { setUser(null) }
    }
    window.addEventListener('storage', onStorage)
    return () => window.removeEventListener('storage', onStorage)
  }, [])

  function handleLogin(userData) {
    setUser(userData)
    setPage('dashboard')
  }

  function handleLogout() {
    localStorage.removeItem('admin_token')
    localStorage.removeItem('admin_user')
    setUser(null)
  }

  if (!user) return <Login onLogin={handleLogin} />

  return (
    <Layout user={user} page={page} onNavigate={setPage} onLogout={handleLogout}>
      {page === 'dashboard' && <Dashboard />}
      {page === 'orders'    && <Orders />}
      {page === 'menus'     && <Menus />}
    </Layout>
  )
}
