import { useEffect, useState } from 'react'
import { getPlatformEarnings } from '../services/api'
import {
  BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip,
  ResponsiveContainer, LineChart, Line
} from 'recharts'
import {
  TrendingUp, DollarSign, ShoppingBag, Users,
  Store, ArrowUpRight, ArrowDownRight, Percent
} from 'lucide-react'

const fmt = (n) => {
  if (!n) return '0'
  if (n >= 10000000) return `${(n/10000000).toFixed(2)} Cr`
  if (n >= 100000)   return `${(n/100000).toFixed(2)} L`
  if (n >= 1000)     return `${(n/1000).toFixed(1)}K`
  return Number(n).toLocaleString()
}

const StatCard = ({ icon: Icon, label, value, sub, change, color = 'violet' }) => {
  const colors = {
    violet: 'bg-violet-50 text-violet-600',
    green:  'bg-green-50 text-green-600',
    amber:  'bg-amber-50 text-amber-600',
    blue:   'bg-blue-50 text-blue-600',
  }
  const up = change >= 0
  return (
    <div className="card flex flex-col gap-4">
      <div className="flex items-start justify-between">
        <div className={`w-11 h-11 rounded-2xl flex items-center justify-center ${colors[color]}`}>
          <Icon size={20} />
        </div>
        {change !== undefined && (
          <span className={`flex items-center gap-0.5 text-xs font-semibold px-2 py-1 rounded-full
            ${up ? 'bg-green-50 text-green-600' : 'bg-red-50 text-red-500'}`}>
            {up ? <ArrowUpRight size={12} /> : <ArrowDownRight size={12} />}
            {Math.abs(change).toFixed(1)}%
          </span>
        )}
      </div>
      <div>
        <p className="text-2xl font-black text-gray-900">{value}</p>
        <p className="text-sm text-gray-500 mt-0.5">{label}</p>
        {sub && <p className="text-xs text-gray-400 mt-1">{sub}</p>}
      </div>
    </div>
  )
}

const CustomTooltip = ({ active, payload, label }) => {
  if (!active || !payload?.length) return null
  return (
    <div className="bg-white border border-gray-100 rounded-xl shadow-lg px-4 py-3">
      <p className="text-xs font-semibold text-gray-500 mb-1">{label}</p>
      {payload.map(p => (
        <p key={p.name} className="text-sm font-bold" style={{ color: p.color }}>
          BDT {fmt(p.value)}
        </p>
      ))}
    </div>
  )
}

export default function Dashboard() {
  const [data, setData]     = useState(null)
  const [loading, setLoading] = useState(true)
  const [error, setError]   = useState('')

  useEffect(() => {
    getPlatformEarnings()
      .then(r => setData(r.data))
      .catch(e => setError(e.response?.data?.error || 'Failed to load earnings'))
      .finally(() => setLoading(false))
  }, [])

  if (loading) return (
    <div className="flex items-center justify-center h-64">
      <div className="w-8 h-8 border-4 border-violet-200 border-t-violet-600 rounded-full animate-spin" />
    </div>
  )

  if (error) return (
    <div className="flex flex-col items-center justify-center h-64 gap-3">
      <p className="text-gray-400 text-sm">{error}</p>
      <button onClick={() => window.location.reload()} className="btn-primary text-sm px-4 py-2">Retry</button>
    </div>
  )

  const monthly   = data?.monthly || []
  const chartData = monthly.map(m => ({
    name:    m.label,
    revenue: m.platform_fee,
    gmv:     m.gmv,
  }))

  const thisRev  = data?.this_month_revenue || 0
  const lastRev  = data?.last_month_revenue || 0
  const revChange = lastRev > 0 ? ((thisRev - lastRev) / lastRev) * 100 : 0

  return (
    <div className="space-y-6">

      {/* Page title */}
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-2xl font-black text-gray-900">Platform Overview</h2>
          <p className="text-gray-500 text-sm mt-1">Real-time earnings & activity across SupplyLink</p>
        </div>
        <div className="flex items-center gap-2 bg-violet-50 border border-violet-100 rounded-xl px-4 py-2">
          <Percent size={14} className="text-violet-600" />
          <span className="text-sm font-semibold text-violet-700">2% commission model</span>
        </div>
      </div>

      {/* Stats grid */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
        <StatCard icon={DollarSign} label="Platform Revenue" color="violet"
          value={`BDT ${fmt(data?.platform_revenue)}`}
          sub={`From BDT ${fmt(data?.gmv)} GMV`} />
        <StatCard icon={TrendingUp} label="This Month Revenue" color="green"
          value={`BDT ${fmt(thisRev)}`}
          change={revChange} />
        <StatCard icon={ShoppingBag} label="Total Orders" color="blue"
          value={data?.total_orders?.toLocaleString() || '0'}
          sub="All delivered orders" />
        <StatCard icon={Users} label="Platform Users" color="amber"
          value={(( data?.total_buyers || 0) + (data?.total_sellers || 0)).toString()}
          sub={`${data?.total_buyers || 0} buyers · ${data?.total_sellers || 0} sellers`} />
      </div>

      {/* Charts row */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">

        {/* Revenue bar chart */}
        <div className="card lg:col-span-2">
          <div className="flex items-center justify-between mb-6">
            <div>
              <h3 className="font-bold text-gray-900">Monthly Performance</h3>
              <p className="text-xs text-gray-400 mt-0.5">Platform revenue vs GMV</p>
            </div>
            <div className="flex items-center gap-4 text-xs text-gray-500">
              <span className="flex items-center gap-1.5">
                <span className="w-2.5 h-2.5 rounded-full bg-violet-500 inline-block" />Revenue
              </span>
              <span className="flex items-center gap-1.5">
                <span className="w-2.5 h-2.5 rounded-full bg-violet-200 inline-block" />GMV
              </span>
            </div>
          </div>
          {chartData.length > 0 ? (
            <ResponsiveContainer width="100%" height={220}>
              <BarChart data={chartData} barGap={4}>
                <CartesianGrid strokeDasharray="3 3" stroke="#f3f4f6" vertical={false} />
                <XAxis dataKey="name" tick={{ fontSize: 11, fill: '#9ca3af' }} axisLine={false} tickLine={false} />
                <YAxis tick={{ fontSize: 10, fill: '#9ca3af' }} axisLine={false} tickLine={false}
                  tickFormatter={v => `${fmt(v)}`} width={50} />
                <Tooltip content={<CustomTooltip />} cursor={{ fill: '#f5f3ff' }} />
                <Bar dataKey="gmv"     fill="#ede9fe" radius={[4,4,0,0]} />
                <Bar dataKey="revenue" fill="#7c3aed" radius={[4,4,0,0]} />
              </BarChart>
            </ResponsiveContainer>
          ) : (
            <div className="flex items-center justify-center h-48 text-gray-400 text-sm">No data yet</div>
          )}
        </div>

        {/* Revenue trend line */}
        <div className="card">
          <h3 className="font-bold text-gray-900 mb-1">Revenue Trend</h3>
          <p className="text-xs text-gray-400 mb-5">Net platform fees over time</p>
          {chartData.length > 0 ? (
            <ResponsiveContainer width="100%" height={180}>
              <LineChart data={chartData}>
                <CartesianGrid strokeDasharray="3 3" stroke="#f3f4f6" vertical={false} />
                <XAxis dataKey="name" tick={{ fontSize: 10, fill: '#9ca3af' }} axisLine={false} tickLine={false} />
                <YAxis hide />
                <Tooltip content={<CustomTooltip />} />
                <Line type="monotone" dataKey="revenue" stroke="#7c3aed" strokeWidth={2.5}
                  dot={{ fill: '#7c3aed', r: 3 }} activeDot={{ r: 5 }} />
              </LineChart>
            </ResponsiveContainer>
          ) : (
            <div className="flex items-center justify-center h-48 text-gray-400 text-sm">No data yet</div>
          )}
        </div>
      </div>

      {/* Leaderboards */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">

        {/* Top Suppliers */}
        <div className="card">
          <div className="flex items-center gap-2 mb-5">
            <div className="w-8 h-8 rounded-xl bg-green-50 flex items-center justify-center">
              <Store size={16} className="text-green-600" />
            </div>
            <div>
              <h3 className="font-bold text-gray-900 text-sm">Top Suppliers</h3>
              <p className="text-xs text-gray-400">by total revenue</p>
            </div>
          </div>
          <div className="space-y-3">
            {(data?.top_sellers || []).map((s, i) => {
              const maxRev = data.top_sellers[0]?.revenue || 1
              const pct    = (s.revenue / maxRev) * 100
              return (
                <div key={i} className="flex items-center gap-3">
                  <span className="w-6 text-xs font-bold text-gray-400">#{i+1}</span>
                  <div className="flex-1 min-w-0">
                    <div className="flex items-center justify-between mb-1">
                      <p className="text-sm font-semibold text-gray-800 truncate">{s.company_name}</p>
                      <p className="text-xs font-bold text-green-600 ml-2">BDT {fmt(s.revenue)}</p>
                    </div>
                    <div className="h-1.5 bg-gray-100 rounded-full overflow-hidden">
                      <div className="h-full bg-gradient-to-r from-green-400 to-emerald-500 rounded-full"
                        style={{ width: `${pct}%` }} />
                    </div>
                    <p className="text-xs text-gray-400 mt-1">{s.orders} orders</p>
                  </div>
                </div>
              )
            })}
            {!data?.top_sellers?.length && <p className="text-gray-400 text-sm text-center py-6">No data yet</p>}
          </div>
        </div>

        {/* Top Buyers */}
        <div className="card">
          <div className="flex items-center gap-2 mb-5">
            <div className="w-8 h-8 rounded-xl bg-blue-50 flex items-center justify-center">
              <ShoppingBag size={16} className="text-blue-600" />
            </div>
            <div>
              <h3 className="font-bold text-gray-900 text-sm">Top Shop Owners</h3>
              <p className="text-xs text-gray-400">by total spending</p>
            </div>
          </div>
          <div className="space-y-3">
            {(data?.top_buyers || []).map((b, i) => {
              const maxSpent = data.top_buyers[0]?.spent || 1
              const pct      = (b.spent / maxSpent) * 100
              return (
                <div key={i} className="flex items-center gap-3">
                  <span className="w-6 text-xs font-bold text-gray-400">#{i+1}</span>
                  <div className="flex-1 min-w-0">
                    <div className="flex items-center justify-between mb-1">
                      <p className="text-sm font-semibold text-gray-800 truncate">{b.shop_name}</p>
                      <p className="text-xs font-bold text-blue-600 ml-2">BDT {fmt(b.spent)}</p>
                    </div>
                    <div className="h-1.5 bg-gray-100 rounded-full overflow-hidden">
                      <div className="h-full bg-gradient-to-r from-blue-400 to-indigo-500 rounded-full"
                        style={{ width: `${pct}%` }} />
                    </div>
                    <p className="text-xs text-gray-400 mt-1">{b.orders} orders</p>
                  </div>
                </div>
              )
            })}
            {!data?.top_buyers?.length && <p className="text-gray-400 text-sm text-center py-6">No data yet</p>}
          </div>
        </div>
      </div>

      {/* Recent transactions */}
      <div className="card">
        <h3 className="font-bold text-gray-900 mb-4">Recent Platform Earnings</h3>
        <div className="overflow-x-auto">
          <table className="w-full min-w-[600px]">
            <thead>
              <tr className="border-b border-gray-100">
                <th className="th">Order</th>
                <th className="th">Product</th>
                <th className="th">Seller</th>
                <th className="th">Buyer</th>
                <th className="th">Order Value</th>
                <th className="th">Platform Fee</th>
                <th className="th">Date</th>
              </tr>
            </thead>
            <tbody>
              {(data?.recent || []).map((r, i) => (
                <tr key={i} className="tr">
                  <td className="td font-mono text-xs text-violet-600">#{r.order_id}</td>
                  <td className="td font-medium">{r.product_name}</td>
                  <td className="td text-gray-500">{r.seller}</td>
                  <td className="td text-gray-500">{r.buyer}</td>
                  <td className="td font-semibold">BDT {fmt(r.total_price)}</td>
                  <td className="td">
                    <span className="font-bold text-green-600">BDT {fmt(r.platform_fee)}</span>
                  </td>
                  <td className="td text-gray-400 text-xs">
                    {r.delivered_at ? new Date(r.delivered_at).toLocaleDateString('en-GB') : '-'}
                  </td>
                </tr>
              ))}
              {!data?.recent?.length && (
                <tr><td colSpan={7} className="text-center py-10 text-gray-400 text-sm">No transactions yet</td></tr>
              )}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  )
}
