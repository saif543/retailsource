import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom'
import Login     from './pages/Login'
import Layout    from './components/Layout'
import Dashboard from './pages/Dashboard'
import Users     from './pages/Users'
import Orders    from './pages/Orders'

const PrivateRoute = ({ children }) => {
  const token = localStorage.getItem('sl_token')
  const role  = localStorage.getItem('sl_role')
  if (!token || role !== 'admin') return <Navigate to="/login" replace />
  return children
}

export default function App() {
  return (
    <BrowserRouter>
      <Routes>
        <Route path="/login" element={<Login />} />
        <Route path="/" element={
          <PrivateRoute>
            <Layout />
          </PrivateRoute>
        }>
          <Route index          element={<Navigate to="/dashboard" replace />} />
          <Route path="dashboard" element={<Dashboard />} />
          <Route path="users"     element={<Users />} />
          <Route path="orders"    element={<Orders />} />
        </Route>
        <Route path="*" element={<Navigate to="/dashboard" replace />} />
      </Routes>
    </BrowserRouter>
  )
}
