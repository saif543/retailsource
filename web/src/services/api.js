import axios from 'axios'

const BASE = 'http://localhost:5000/api'

const api = axios.create({ baseURL: BASE })

api.interceptors.request.use(cfg => {
  const token = localStorage.getItem('sl_token')
  if (token) cfg.headers.Authorization = `Bearer ${token}`
  return cfg
})

// ── Auth ────────────────────────────────────────────────────────────────────
export const login = (email, password) =>
  api.post('/auth/login', { email_or_phone: email, password })

// ── Earnings ────────────────────────────────────────────────────────────────
export const getPlatformEarnings = () => api.get('/earnings/platform')

// ── Admin: Users ────────────────────────────────────────────────────────────
export const getUsers   = () => api.get('/admin/users')
export const toggleVerify = (userId) => api.put(`/admin/users/${userId}/toggle-verify`)

// ── Admin: Orders ───────────────────────────────────────────────────────────
export const getAllOrders = () => api.get('/admin/orders')

export default api
