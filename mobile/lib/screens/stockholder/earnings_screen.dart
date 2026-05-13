import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/earnings_service.dart';
import '../../config/language.dart';

const _sp0 = Color(0xFF16002E);
const _sp1 = Color(0xFF3B0D6B);
const _sp2 = Color(0xFF7B2FD4);
const _sp3 = Color(0xFFBB6BF7);
const _bg  = Color(0xFFF8F0FF);
const _txt = Color(0xFF212121);
const _sub = Color(0xFF757575);
const _amb1 = Color(0xFFAD4A0A);
const _amb2 = Color(0xFFF5981E);
const _red1 = Color(0xFF7B1C1C);
const _red2 = Color(0xFFEF5350);

class _Tap extends StatefulWidget {
  final Widget child; final VoidCallback onTap;
  const _Tap({required this.child, required this.onTap});
  @override State<_Tap> createState() => _TapS();
}
class _TapS extends State<_Tap> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this,
      duration: const Duration(milliseconds: 80),
      reverseDuration: const Duration(milliseconds: 200));
  late final _s = Tween<double>(begin: 1.0, end: 0.95)
      .animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));
  @override void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext ctx) => GestureDetector(
    onTapDown: (_) => _c.forward(),
    onTapUp:   (_) { _c.reverse(); widget.onTap(); },
    onTapCancel: () => _c.reverse(),
    child: AnimatedBuilder(animation: _s,
      builder: (_, ch) => Transform.scale(scale: _s.value, child: ch),
      child: widget.child),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
class EarningsScreen extends StatefulWidget {
  const EarningsScreen({super.key});
  @override State<EarningsScreen> createState() => _ES();
}

class _ES extends State<EarningsScreen> with SingleTickerProviderStateMixin {
  bool _loading = true;
  Map<String, dynamic>? _data;

  late final _fadeC = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 500));

  @override
  void initState() {
    super.initState();
    appLang.addListener(_onLangChange);
    _load();
  }

  void _onLangChange() => setState(() {});

  @override
  void dispose() {
    appLang.removeListener(_onLangChange);
    _fadeC.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final d = await EarningsService.getStockholderEarnings();
    if (!mounted) return;
    setState(() { _data = d; _loading = false; });
    _fadeC.forward(from: 0);
  }

  String _fmt(double v) {
    if (v >= 100000) return '${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000)   return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }

  String _fmtDate(String? iso) {
    if (iso == null) return '';
    final dt = DateTime.tryParse(iso)?.toLocal();
    if (dt == null) return '';
    const months = ['Jan','Feb','Mar','Apr','May','Jun',
                    'Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${dt.day} ${months[dt.month - 1]}';
  }

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: SystemUiOverlayStyle.light,
    child: Scaffold(
      backgroundColor: _bg,
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _sp3))
          : FadeTransition(
              opacity: CurvedAnimation(parent: _fadeC, curve: Curves.easeOut),
              child: Column(children: [
                _header(),
                Expanded(child: RefreshIndicator(
                  onRefresh: _load, color: _sp3,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                    child: _data == null
                        ? _errorState()
                        : Column(children: [
                            _summaryRow(),
                            const SizedBox(height: 20),
                            _feeNote(),
                            const SizedBox(height: 20),
                            _chartCard(),
                            const SizedBox(height: 20),
                            _transactionList(),
                          ]),
                  ),
                )),
              ]),
            ),
    ),
  );

  // ── header ────────────────────────────────────────────────────────────────
  Widget _header() {
    final net    = (_data?['net_total'] as num?)?.toDouble() ?? 0.0;
    final orders = (_data?['total_orders'] as int?) ?? 0;
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
            colors: [_sp0, _sp1, _sp2, _sp3],
            stops: [0.0, 0.35, 0.7, 1.0],
            begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(32), bottomRight: Radius.circular(32)),
      ),
      child: SafeArea(bottom: false,
        child: Stack(children: [
          Positioned(top: -30, right: -30, child: _blob(160, Colors.white, .04)),
          Positioned(top: 10,  right: 50,  child: _blob(50,  _sp3, .3)),
          Positioned(top: 70,  left: -20,  child: _blob(100, _sp1, .25)),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 20, 28),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                _Tap(onTap: () => Navigator.pop(context),
                  child: Container(width: 42, height: 42,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(.14),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(.25)),
                    ),
                    child: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: Colors.white, size: 17))),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(S('my_earnings_title'), style: const TextStyle(color: Colors.white,
                      fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -.4)),
                  const SizedBox(height: 2),
                  Text(S('earnings_subtitle'),
                      style: const TextStyle(color: Colors.white54, fontSize: 12.5)),
                ])),
                _Tap(onTap: _load,
                  child: Container(width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(.14),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(.25)),
                    ),
                    child: const Icon(Icons.refresh_rounded, color: Colors.white, size: 18))),
              ]),
              const SizedBox(height: 24),
              Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(S('total_net_earnings'), style: const TextStyle(
                      color: Colors.white60, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text('BDT ${_fmtFull(net)}',
                      style: const TextStyle(color: Colors.white,
                          fontSize: 30, fontWeight: FontWeight.w900, letterSpacing: -.5)),
                ]),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(.18),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(.25)),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
                    Text('$orders', style: const TextStyle(
                        color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
                    const Text('orders', style: TextStyle(
                        color: Colors.white60, fontSize: 11)),
                  ])),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }

  // ── summary row ───────────────────────────────────────────────────────────
  Widget _summaryRow() {
    final gross     = (_data!['gross_total'] as num?)?.toDouble() ?? 0.0;
    final fee       = (_data!['platform_fee_total'] as num?)?.toDouble() ?? 0.0;
    final net       = (_data!['net_total'] as num?)?.toDouble() ?? 0.0;
    final thisNet   = (_data!['this_month_net'] as num?)?.toDouble() ?? 0.0;
    final lastNet   = (_data!['last_month_net'] as num?)?.toDouble() ?? 0.0;

    return Column(children: [
      Row(children: [
        Expanded(child: _statCard('Gross Earnings', _fmtFull(gross), _sp1, Icons.attach_money_rounded)),
        const SizedBox(width: 12),
        Expanded(child: _statCard('Platform Fee (2%)', _fmtFull(fee), _amb1, Icons.percent_rounded)),
        const SizedBox(width: 12),
        Expanded(child: _statCard(S('net_earnings_label'), _fmtFull(net), _sp2, Icons.account_balance_wallet_rounded, highlight: true)),
      ]),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: _statCard(S('this_month_label'), _fmtFull(thisNet), _sp3, Icons.calendar_today_rounded)),
        const SizedBox(width: 12),
        Expanded(child: _statCard(S('last_month_label'), _fmtFull(lastNet), _sub, Icons.history_rounded)),
        const SizedBox(width: 12),
        const Expanded(child: SizedBox()),
      ]),
    ]);
  }

  Widget _statCard(String label, String value, Color c, IconData icon, {bool highlight = false}) =>
    Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: highlight
            ? const LinearGradient(colors: [_sp1, _sp3],
                begin: Alignment.topLeft, end: Alignment.bottomRight)
            : null,
        color: highlight ? null : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(
            color: (highlight ? _sp3 : _sp1).withOpacity(highlight ? .3 : .07),
            blurRadius: 14, offset: const Offset(0, 5))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(width: 30, height: 30,
          decoration: BoxDecoration(
            color: (highlight ? Colors.white : c).withOpacity(highlight ? .2 : .12),
            borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 15,
              color: highlight ? Colors.white : c)),
        const SizedBox(height: 10),
        Text(label,
            style: TextStyle(fontSize: 10, color: highlight ? Colors.white70 : _sub,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 2),
        Text('BDT $value',
            style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w900,
                color: highlight ? Colors.white : _txt),
            maxLines: 1, overflow: TextOverflow.ellipsis),
      ]),
    );

  // ── fee note ──────────────────────────────────────────────────────────────
  Widget _feeNote() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: _amb2.withOpacity(.1),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: _amb2.withOpacity(.3)),
    ),
    child: const Row(children: [
      Icon(Icons.info_outline_rounded, color: _amb1, size: 16),
      SizedBox(width: 10),
      Expanded(child: Text(
        'SupplyLink charges a 2% platform fee on each delivered order. '
        'Your net earnings are automatically calculated after this deduction.',
        style: TextStyle(color: _amb1, fontSize: 11.5, height: 1.45))),
    ]),
  );

  // ── monthly chart ─────────────────────────────────────────────────────────
  Widget _chartCard() {
    final monthly = List<Map<String, dynamic>>.from(_data?['monthly'] ?? []);
    if (monthly.isEmpty) return const SizedBox.shrink();

    final netValues = monthly.map((m) => (m['net'] as num).toDouble()).toList();
    final maxY = netValues.reduce((a, b) => a > b ? a : b) * 1.3;
    final labels = monthly.map((m) => m['short_label'] as String? ?? '').toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDeco(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 32, height: 32,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [_sp1, _sp3]),
              borderRadius: BorderRadius.circular(9)),
            child: const Icon(Icons.bar_chart_rounded, color: Colors.white, size: 16)),
          const SizedBox(width: 10),
          const Text('Monthly Net Earnings', style: TextStyle(
              fontSize: 15, fontWeight: FontWeight.w900, color: _txt)),
        ]),
        const SizedBox(height: 20),
        SizedBox(
          height: 180,
          child: BarChart(BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: maxY <= 0 ? 1000 : maxY,
            barGroups: netValues.asMap().entries.map((e) =>
              BarChartGroupData(x: e.key, barRods: [
                BarChartRodData(
                  toY: e.value,
                  gradient: const LinearGradient(
                      colors: [_sp1, _sp3],
                      begin: Alignment.bottomCenter, end: Alignment.topCenter),
                  width: 22,
                  borderRadius: BorderRadius.circular(6),
                ),
              ])
            ).toList(),
            titlesData: FlTitlesData(
              show: true,
              bottomTitles: AxisTitles(sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (v, _) {
                  final i = v.toInt();
                  if (i < 0 || i >= labels.length) return const SizedBox.shrink();
                  return Padding(padding: const EdgeInsets.only(top: 6),
                    child: Text(labels[i], style: const TextStyle(
                        fontSize: 10.5, color: _sub, fontWeight: FontWeight.w600)));
                },
              )),
              leftTitles:  AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles:   AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: AxisTitles(sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 50,
                getTitlesWidget: (v, _) => Text(
                  _fmt(v), style: const TextStyle(fontSize: 9.5, color: _sub)),
              )),
            ),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (_) => FlLine(
                  color: _sp3.withOpacity(.12), strokeWidth: 1),
            ),
            borderData: FlBorderData(show: false),
          )),
        ),
      ]),
    );
  }

  // ── transaction list ──────────────────────────────────────────────────────
  Widget _transactionList() {
    final txns = List<Map<String, dynamic>>.from(_data?['transactions'] ?? []);
    if (txns.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(28),
        decoration: _cardDeco(),
        child: Column(children: [
          Container(width: 56, height: 56,
            decoration: BoxDecoration(color: _sp3.withOpacity(.12), shape: BoxShape.circle),
            child: const Icon(Icons.receipt_long_outlined, color: _sp2, size: 26)),
          const SizedBox(height: 14),
          const Text('No transactions yet', style: TextStyle(
              fontWeight: FontWeight.w800, fontSize: 15, color: _txt)),
          const SizedBox(height: 6),
          const Text('Completed orders will appear here.',
              style: TextStyle(color: _sub, fontSize: 13)),
        ]),
      );
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(width: 32, height: 32,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [_sp1, _sp3]),
            borderRadius: BorderRadius.circular(9)),
          child: const Icon(Icons.receipt_long_rounded, color: Colors.white, size: 15)),
        const SizedBox(width: 10),
        const Text('Transaction History', style: TextStyle(
            fontSize: 15, fontWeight: FontWeight.w900, color: _txt)),
      ]),
      const SizedBox(height: 14),
      ...txns.map((t) => _txnCard(t)),
    ]);
  }

  Widget _txnCard(Map<String, dynamic> t) {
    final product  = '${t['product_name'] ?? ''} - ${t['variant_name'] ?? ''}';
    final shop     = t['shop_name'] as String? ?? '';
    final gross    = (t['total_price'] as num).toDouble();
    final fee      = (t['platform_fee'] as num).toDouble();
    final net      = (t['net_amount'] as num).toDouble();
    final date     = _fmtDate(t['delivered_at'] as String?);
    final orderId  = t['order_id'];

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: _cardDeco(),
      child: Column(children: [
        Row(children: [
          Container(width: 44, height: 44,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [_sp1, _sp3],
                  begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(product, style: const TextStyle(fontWeight: FontWeight.w800,
                fontSize: 13.5, color: _txt),
                maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text('$shop  ·  #ORD-$orderId  ·  $date',
                style: const TextStyle(color: _sub, fontSize: 11.5),
                maxLines: 1, overflow: TextOverflow.ellipsis),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('BDT ${_fmtFull(net)}',
                style: const TextStyle(color: _sp1,
                    fontWeight: FontWeight.w900, fontSize: 14)),
            Text('net', style: const TextStyle(color: _sub, fontSize: 10.5)),
          ]),
        ]),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _bg, borderRadius: BorderRadius.circular(8)),
          child: Row(children: [
            _miniKV('Gross', 'BDT ${_fmtFull(gross)}', _txt),
            const SizedBox(width: 4),
            const Text('−', style: TextStyle(color: _sub)),
            const SizedBox(width: 4),
            _miniKV('Fee (2%)', 'BDT ${_fmtFull(fee)}', _red2),
            const SizedBox(width: 4),
            const Text('=', style: TextStyle(color: _sub)),
            const SizedBox(width: 4),
            _miniKV('Net', 'BDT ${_fmtFull(net)}', _sp1),
          ]),
        ),
      ]),
    );
  }

  Widget _miniKV(String label, String value, Color c) => Column(
    crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 9.5, color: _sub)),
      Text(value, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: c)),
    ]);

  Widget _errorState() => Center(
    child: Padding(padding: const EdgeInsets.all(40), child: Column(children: [
      const Icon(Icons.wifi_off_rounded, size: 48, color: _sub),
      const SizedBox(height: 16),
      Text(S('could_not_load_earnings'), style: const TextStyle(
          fontWeight: FontWeight.w800, fontSize: 16, color: _txt)),
      const SizedBox(height: 8),
      const Text('Check your connection and try again.',
          style: TextStyle(color: _sub, fontSize: 13)),
      const SizedBox(height: 20),
      _Tap(onTap: _load, child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [_sp1, _sp3]),
          borderRadius: BorderRadius.circular(14)),
        child: Text(S('retry_btn'), style: const TextStyle(color: Colors.white,
            fontWeight: FontWeight.w800, fontSize: 14)))),
    ])),
  );

  BoxDecoration _cardDeco() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(20),
    boxShadow: [
      BoxShadow(color: _sp1.withOpacity(.07), blurRadius: 16, offset: const Offset(0, 5)),
      BoxShadow(color: Colors.black.withOpacity(.03), blurRadius: 4, offset: const Offset(0, 2)),
    ],
  );

  Widget _blob(double sz, Color c, double op) =>
    Container(width: sz, height: sz,
        decoration: BoxDecoration(shape: BoxShape.circle, color: c.withOpacity(op)));

  String _fmtFull(double v) {
    if (v >= 10000000) return '${(v / 10000000).toStringAsFixed(2)} Cr';
    if (v >= 100000)   return '${(v / 100000).toStringAsFixed(2)} L';
    return v.toStringAsFixed(0);
  }
}
