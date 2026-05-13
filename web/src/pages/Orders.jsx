import { useEffect, useState } from 'react'
import { getAllOrders } from '../services/api'
import { Search, RefreshCw, Clock, CheckCircle, XCircle, Truck, Package } from 'lucide-react'

const statusMeta = {
  pending:          { label: 'Pending',     color: 'bg-amber-50 text-amber-600',  icon: Clock       },
  accepted:         { label: 'Accepted',    color: 'bg-blue-50 text-blue-600',    icon: CheckCircle },
  out_for_delivery: { label: 'On the Way',  color: 'bg-indigo-50 text-indigo-600',icon: Truck       },
  delivered:        { label: 'Delivered',   color: 'bg-green-50 text-green-600',  icon: Package     },
  declined:         { label: 'Declined',    color: 'bg-red-50 text-red-500',      icon: XCircle     },
}

const fmt = (n) => {
  if (!n) return '0'
  if (n >= 1000) return `${(n/1000).toFixed(1)}K`
  return Number(n).toLocaleString()
}

export default function Orders() {
  const [orders, setOrders]   = useState([])
  const [loading, setLoading] = useState(true)
  const [search, setSearch]   = useState('')
  const [status, setStatus]   = useState('all')
  const [error, setError]     = useState('')

  const load = () => {
    setLoading(true)
    getAllOrders()
      .then(r => setOrders(r.data.orders || []))
      .catch(e => setError(e.response?.data?.error || 'Failed to load orders'))
      .finally(() => setLoading(false))
  }

  useEffect(() => { load() }, [])

  const filtered = orders.filter(o => {
    const matchStatus = status === 'all' || o.status === status
    const matchSearch = !search ||
      o.product_name?.toLowerCase().includes(search.toLowerCase()) ||
      o.stockholder_name?.toLowerCase().includes(search.toLowerCase()) ||
      o.shop_name?.toLowerCase().includes(search.toLowerCase()) ||
      String(o.order_id).includes(search)
    return matchStatus && matchSearch
  })

  const countBy = (s) => orders.filter(o => o.status === s).length

  const totalGmv = orders
    .filter(o => o.status === 'delivered')
    .reduce((s, o) => s + (o.total_price || 0), 0)

  const tabs = [
    ['all',          'All',        orders.length],
    ['pending',      'Pending',    countBy('pending')],
    ['accepted',     'Accepted',   countBy('accepted')],
    ['out_for_delivery','On Way',  countBy('out_for_delivery')],
    ['delivered',    'Delivered',  countBy('delivered')],
    ['declined',     'Declined',   countBy('declined')],
  ]

  return (
    <div className="space-y-6">
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h2 className="text-2xl font-black text-gray-900">Orders</h2>
          <p className="text-gray-500 text-sm mt-1">
            {orders.length} total orders · Delivered GMV: BDT {fmt(totalGmv)}
          </p>
        </div>
        <button onClick={load} className="flex items-center gap-2 btn-ghost text-sm">
          <RefreshCw size={14} /> Refresh
        </button>
      </div>

      {/* Status tabs */}
      <div className="flex gap-2 flex-wrap">
        {tabs.map(([val, lbl, cnt]) => (
          <button key={val} onClick={() => setStatus(val)}
            className={`px-4 py-2 rounded-xl text-sm font-semibold transition-all
              ${status === val
                ? 'bg-violet-600 text-white shadow-sm'
                : 'bg-white text-gray-600 border border-gray-200 hover:border-violet-300'}`}>
            {lbl}
            <span className={`ml-2 px-1.5 py-0.5 rounded-full text-xs
              ${status === val ? 'bg-white/20 text-white' : 'bg-gray-100 text-gray-500'}`}>
              {cnt}
            </span>
          </button>
        ))}
      </div>

      {/* Search */}
      <div className="relative">
        <Search size={16} className="absolute left-3.5 top-1/2 -translate-y-1/2 text-gray-400" />
        <input value={search} onChange={e => setSearch(e.target.value)}
          placeholder="Search by product, supplier, shop or order ID…"
          className="input pl-10 max-w-sm" />
      </div>

      {error && <p className="text-red-500 text-sm">{error}</p>}

      {/* Table */}
      <div className="card p-0 overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full min-w-[800px]">
            <thead>
              <tr className="border-b border-gray-100 bg-gray-50/50">
                <th className="th">Order ID</th>
                <th className="th">Product</th>
                <th className="th">Supplier</th>
                <th className="th">Shop Owner</th>
                <th className="th">Qty</th>
                <th className="th">Total</th>
                <th className="th">Platform Fee</th>
                <th className="th">Status</th>
                <th className="th">Date</th>
              </tr>
            </thead>
            <tbody>
              {loading ? (
                Array(6).fill(0).map((_, i) => (
                  <tr key={i} className="border-b border-gray-50">
                    {Array(9).fill(0).map((_, j) => (
                      <td key={j} className="td">
                        <div className="h-4 bg-gray-100 rounded animate-pulse" />
                      </td>
                    ))}
                  </tr>
                ))
              ) : filtered.length === 0 ? (
                <tr><td colSpan={9} className="text-center py-12 text-gray-400 text-sm">No orders found</td></tr>
              ) : filtered.map(o => {
                const meta  = statusMeta[o.status] || statusMeta.pending
                const Icon  = meta.icon
                const fee   = ((o.total_price || 0) * 0.02).toFixed(0)
                return (
                  <tr key={o.order_id} className="tr">
                    <td className="td">
                      <span className="font-mono text-xs text-violet-600 font-semibold">#{o.order_id}</span>
                    </td>
                    <td className="td">
                      <p className="font-semibold text-gray-800 text-sm">{o.product_name}</p>
                      <p className="text-xs text-gray-400">{o.variant_name}</p>
                    </td>
                    <td className="td text-gray-600 text-sm">{o.stockholder_name}</td>
                    <td className="td text-gray-600 text-sm">{o.shop_name}</td>
                    <td className="td text-gray-500 text-sm">{o.quantity} {o.unit}</td>
                    <td className="td font-semibold text-gray-800">BDT {fmt(o.total_price)}</td>
                    <td className="td">
                      <span className={`font-bold text-sm ${o.status === 'delivered' ? 'text-green-600' : 'text-gray-400'}`}>
                        {o.status === 'delivered' ? `BDT ${fee}` : '—'}
                      </span>
                    </td>
                    <td className="td">
                      <span className={`badge ${meta.color}`}>
                        <Icon size={11} />
                        {meta.label}
                      </span>
                    </td>
                    <td className="td text-gray-400 text-xs">
                      {o.created_at ? new Date(o.created_at).toLocaleDateString('en-GB') : '—'}
                    </td>
                  </tr>
                )
              })}
            </tbody>
          </table>
        </div>

        {/* Footer summary */}
        {filtered.length > 0 && (
          <div className="px-6 py-3 border-t border-gray-50 bg-gray-50/30 flex items-center justify-between text-xs text-gray-500">
            <span>Showing {filtered.length} of {orders.length} orders</span>
            {status === 'all' || status === 'delivered' ? (
              <span className="font-semibold text-green-600">
                Platform earned: BDT {fmt(
                  filtered.filter(o => o.status === 'delivered')
                    .reduce((s, o) => s + (o.total_price || 0) * 0.02, 0)
                )}
              </span>
            ) : null}
          </div>
        )}
      </div>
    </div>
  )
}
