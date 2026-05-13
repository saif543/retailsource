import { useEffect, useState } from 'react'
import { getUsers, toggleVerify } from '../services/api'
import { Search, CheckCircle, XCircle, Store, Package, ShieldCheck, RefreshCw } from 'lucide-react'

const roleMeta = {
  shop_owner:   { label: 'Shop Owner',   icon: Store,       color: 'bg-blue-50 text-blue-600'   },
  stockholder:  { label: 'Stockholder',  icon: Package,     color: 'bg-green-50 text-green-600' },
  admin:        { label: 'Admin',        icon: ShieldCheck, color: 'bg-violet-50 text-violet-600' },
}

export default function Users() {
  const [users, setUsers]     = useState([])
  const [loading, setLoading] = useState(true)
  const [search, setSearch]   = useState('')
  const [filter, setFilter]   = useState('all')
  const [toggling, setToggling] = useState(null)
  const [error, setError]     = useState('')

  const load = () => {
    setLoading(true)
    getUsers()
      .then(r => setUsers(r.data.users || []))
      .catch(e => setError(e.response?.data?.error || 'Failed to load users'))
      .finally(() => setLoading(false))
  }

  useEffect(() => { load() }, [])

  const handleToggle = async (userId) => {
    setToggling(userId)
    try {
      await toggleVerify(userId)
      setUsers(prev => prev.map(u =>
        u.user_id === userId
          ? { ...u, is_verified: !u.is_verified }
          : u
      ))
    } catch (e) {
      alert(e.response?.data?.error || 'Failed to update user')
    } finally {
      setToggling(null)
    }
  }

  const filtered = users.filter(u => {
    const matchSearch = !search ||
      u.name?.toLowerCase().includes(search.toLowerCase()) ||
      u.email?.toLowerCase().includes(search.toLowerCase()) ||
      u.phone?.includes(search)
    const matchFilter = filter === 'all' || u.role === filter
    return matchSearch && matchFilter
  })

  const counts = {
    all:         users.length,
    shop_owner:  users.filter(u => u.role === 'shop_owner').length,
    stockholder: users.filter(u => u.role === 'stockholder').length,
  }

  return (
    <div className="space-y-6">
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h2 className="text-2xl font-black text-gray-900">User Management</h2>
          <p className="text-gray-500 text-sm mt-1">{users.length} registered users</p>
        </div>
        <button onClick={load} className="flex items-center gap-2 btn-ghost text-sm">
          <RefreshCw size={14} /> Refresh
        </button>
      </div>

      {/* Filters */}
      <div className="flex flex-wrap gap-2">
        {[['all','All Users'], ['shop_owner','Shop Owners'], ['stockholder','Stockholders']].map(([val, lbl]) => (
          <button key={val} onClick={() => setFilter(val)}
            className={`px-4 py-2 rounded-xl text-sm font-semibold transition-all
              ${filter === val
                ? 'bg-violet-600 text-white shadow-sm'
                : 'bg-white text-gray-600 border border-gray-200 hover:border-violet-300'}`}>
            {lbl}
            <span className={`ml-2 px-1.5 py-0.5 rounded-full text-xs
              ${filter === val ? 'bg-white/20 text-white' : 'bg-gray-100 text-gray-500'}`}>
              {counts[val] ?? counts.all}
            </span>
          </button>
        ))}
      </div>

      {/* Search */}
      <div className="relative">
        <Search size={16} className="absolute left-3.5 top-1/2 -translate-y-1/2 text-gray-400" />
        <input value={search} onChange={e => setSearch(e.target.value)}
          placeholder="Search by name, email or phone…"
          className="input pl-10 max-w-sm" />
      </div>

      {error && <p className="text-red-500 text-sm">{error}</p>}

      {/* Table */}
      <div className="card p-0 overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full min-w-[700px]">
            <thead>
              <tr className="border-b border-gray-100 bg-gray-50/50">
                <th className="th">User</th>
                <th className="th">Phone</th>
                <th className="th">Role</th>
                <th className="th">Profile</th>
                <th className="th">Joined</th>
                <th className="th">Status</th>
                <th className="th">Action</th>
              </tr>
            </thead>
            <tbody>
              {loading ? (
                Array(5).fill(0).map((_, i) => (
                  <tr key={i} className="border-b border-gray-50">
                    {Array(7).fill(0).map((_, j) => (
                      <td key={j} className="td">
                        <div className="h-4 bg-gray-100 rounded animate-pulse" />
                      </td>
                    ))}
                  </tr>
                ))
              ) : filtered.length === 0 ? (
                <tr><td colSpan={7} className="text-center py-12 text-gray-400 text-sm">No users found</td></tr>
              ) : filtered.map(u => {
                const meta     = roleMeta[u.role] || roleMeta.admin
                const RoleIcon = meta.icon
                const profile  = u.profile || {}
                const name2    = profile.shop_name || profile.company_name || '—'
                const verified = u.is_verified === true || u.is_verified === 1

                return (
                  <tr key={u.user_id} className="tr">
                    <td className="td">
                      <div className="flex items-center gap-3">
                        <div className="w-9 h-9 rounded-full bg-gradient-to-br from-violet-400 to-purple-600
                          flex items-center justify-center flex-shrink-0 text-white text-sm font-bold">
                          {u.name?.[0]?.toUpperCase() || '?'}
                        </div>
                        <div>
                          <p className="font-semibold text-gray-800 text-sm">{u.name}</p>
                          <p className="text-xs text-gray-400">{u.email}</p>
                        </div>
                      </div>
                    </td>
                    <td className="td text-gray-500">{u.phone || '—'}</td>
                    <td className="td">
                      <span className={`badge ${meta.color}`}>
                        <RoleIcon size={11} />
                        {meta.label}
                      </span>
                    </td>
                    <td className="td text-gray-500 text-xs">{name2}</td>
                    <td className="td text-gray-400 text-xs">
                      {u.created_at ? new Date(u.created_at).toLocaleDateString('en-GB') : '—'}
                    </td>
                    <td className="td">
                      {verified ? (
                        <span className="badge bg-green-50 text-green-600">
                          <CheckCircle size={11} /> Verified
                        </span>
                      ) : (
                        <span className="badge bg-gray-100 text-gray-500">
                          <XCircle size={11} /> Unverified
                        </span>
                      )}
                    </td>
                    <td className="td">
                      {u.role !== 'admin' && (
                        <button
                          onClick={() => handleToggle(u.user_id)}
                          disabled={toggling === u.user_id}
                          className={`text-xs font-semibold px-3 py-1.5 rounded-lg transition-all
                            ${verified
                              ? 'bg-red-50 text-red-600 hover:bg-red-100'
                              : 'bg-green-50 text-green-600 hover:bg-green-100'}
                            disabled:opacity-50`}>
                          {toggling === u.user_id ? '…' : verified ? 'Unverify' : 'Verify'}
                        </button>
                      )}
                    </td>
                  </tr>
                )
              })}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  )
}
