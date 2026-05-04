import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/order_service.dart';
import 'order_status_screen.dart';
import 'rate_supplier_screen.dart';

const _c0   = Color(0xFF060D28);
const _c1   = Color(0xFF0E2260);
const _c2   = Color(0xFF1F4BD5);
const _c3   = Color(0xFF6C3FE8);
const _bg   = Color(0xFFF2F5FF);
const _txt  = Color(0xFF212121);
const _sub  = Color(0xFF757575);
const _amb1 = Color(0xFFAD4A0A); const _amb2 = Color(0xFFF5981E);
const _grn1 = Color(0xFF054F3A); const _grn2 = Color(0xFF0FBB84);
const _red1 = Color(0xFF7B1C1C); const _red2 = Color(0xFFEF5350);
const _pur1 = Color(0xFF4A148C); const _pur2 = Color(0xFFAB47BC);

class _Tap extends StatefulWidget {
  final Widget child; final VoidCallback onTap;
  const _Tap({required this.child, required this.onTap});
  @override State<_Tap> createState() => _TapS();
}
class _TapS extends State<_Tap> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this,
      duration: const Duration(milliseconds: 80),
      reverseDuration: const Duration(milliseconds: 200));
  late final _s = Tween<double>(begin: 1.0, end: 0.94)
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

class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({super.key});
  @override State<MyOrdersScreen> createState() => _MOS();
}

class _MOS extends State<MyOrdersScreen> with SingleTickerProviderStateMixin {
  int _filter = 0;
  bool _loading = true;
  List<Map<String, dynamic>> _orders = [];

  late final _fadeC = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 380));

  static const _keys = ['', 'pending', 'accepted', 'out_for_delivery', 'delivered'];
  static const _labels = ['All', 'Pending', 'Accepted', 'On Way', 'Delivered'];

  @override
  void initState() { super.initState(); _load(); }
  @override
  void dispose() { _fadeC.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = await OrderService.getMyOrders();
    if (!mounted) return;
    setState(() { _orders = list; _loading = false; });
    _fadeC.forward(from: 0);
  }

  List<Map<String, dynamic>> get _filtered => _filter == 0
      ? _orders
      : _orders.where((o) => o['status'] == _keys[_filter]).toList();

  int _cnt(int i) => i == 0
      ? _orders.length
      : _orders.where((o) => o['status'] == _keys[i]).length;

  // status → gradient + icon + label
  List<Color> _grad(String s) {
    switch (s) {
      case 'pending':          return [_amb1, _amb2];
      case 'accepted':         return [_c1,   _c2];
      case 'out_for_delivery': return [_pur1, _pur2];
      case 'delivered':        return [_grn1, _grn2];
      default:                 return [_sub,  _sub];
    }
  }
  IconData _icon(String s) {
    switch (s) {
      case 'pending':          return Icons.hourglass_top_rounded;
      case 'accepted':         return Icons.check_circle_outline_rounded;
      case 'out_for_delivery': return Icons.local_shipping_rounded;
      case 'delivered':        return Icons.check_circle_rounded;
      default:                 return Icons.help_outline;
    }
  }
  String _statusLabel(String s) {
    switch (s) {
      case 'pending':          return 'Pending';
      case 'accepted':         return 'Accepted';
      case 'out_for_delivery': return 'On the Way';
      case 'delivered':        return 'Delivered';
      default:                 return s;
    }
  }

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: SystemUiOverlayStyle.light,
    child: Scaffold(
      backgroundColor: _bg,
      body: Column(children: [
        _header(),
        Expanded(child: _loading
            ? const Center(child: CircularProgressIndicator())
            : FadeTransition(
                opacity: CurvedAnimation(parent: _fadeC, curve: Curves.easeOut),
                child: RefreshIndicator(
                  onRefresh: _load, color: _c2,
                  child: _filtered.isEmpty
                      ? _empty()
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                          itemCount: _filtered.length,
                          itemBuilder: (_, i) => _card(_filtered[i]),
                        ),
                ),
              )),
      ]),
    ),
  );

  // ── gradient header ───────────────────────────────────────────────────────
  Widget _header() => Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
          colors: [_c0, _c1, _c2, _c3],
          stops: [0.0, 0.35, 0.72, 1.0],
          begin: Alignment.topLeft, end: Alignment.bottomRight),
      borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32), bottomRight: Radius.circular(32)),
    ),
    child: SafeArea(bottom: false,
      child: Stack(children: [
        Positioned(top: -20, right: -30, child: _blob(130, Colors.white, .04)),
        Positioned(top: 8,   right: 50,  child: _blob(44,  _c2, .3)),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('My Orders', style: TextStyle(color: Colors.white,
                    fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -.4)),
                SizedBox(height: 2),
                Text('Track all your placed orders',
                    style: TextStyle(color: Colors.white54, fontSize: 12.5)),
              ])),
              ClipRRect(borderRadius: BorderRadius.circular(12),
                child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: _Tap(onTap: _load,
                    child: Container(width: 42, height: 42,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.14),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withOpacity(0.25)),
                      ),
                      child: const Icon(Icons.refresh_rounded, color: Colors.white, size: 19)),
                  ),
                ),
              ),
            ]),
            const SizedBox(height: 18),
            // filter tabs
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: List.generate(_labels.length, (i) {
                final sel = _filter == i;
                final cnt = _cnt(i);
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _Tap(onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() => _filter = i);
                  }, child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: sel ? Colors.white : Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                          color: sel ? Colors.white : Colors.white.withOpacity(0.3)),
                      boxShadow: sel ? [BoxShadow(color: _c1.withOpacity(.3),
                          blurRadius: 8, offset: const Offset(0, 3))] : null,
                    ),
                    child: Text('${_labels[i]}${cnt > 0 ? '  $cnt' : ''}',
                        style: TextStyle(
                            color: sel ? _c1 : Colors.white,
                            fontWeight: FontWeight.w800, fontSize: 13)),
                  )),
                );
              })),
            ),
          ]),
        ),
      ]),
    ),
  );

  // ── order card ────────────────────────────────────────────────────────────
  Widget _card(Map<String, dynamic> o) {
    final st        = (o['status'] as String?) ?? 'pending';
    final grad      = _grad(st);
    final delivered = st == 'delivered';
    final price     = (o['price'] as num?)?.toDouble() ?? 0;

    return _Tap(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => OrderStatusScreen(order: o))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(color: _c1.withOpacity(.08), blurRadius: 20, offset: const Offset(0, 6)),
            BoxShadow(color: Colors.black.withOpacity(.03), blurRadius: 4, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // status icon
              Container(width: 52, height: 52,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: grad,
                      begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [BoxShadow(color: grad.last.withOpacity(.38),
                      blurRadius: 12, offset: const Offset(0, 4))],
                ),
                child: Icon(_icon(st), color: Colors.white, size: 24)),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${o['product'] ?? ''}',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800,
                        color: _txt, letterSpacing: -.2),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 3),
                Text('From ${o['supplier'] ?? ''}',
                    style: const TextStyle(color: _sub, fontSize: 12),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 7),
                Wrap(spacing: 6, runSpacing: 4, children: [
                  _metaPill(Icons.scale_rounded, '${o['qty'] ?? ''}', _c2),
                  _metaPill(Icons.access_time_rounded, '${o['time'] ?? ''}', _sub),
                ]),
              ])),
              const SizedBox(width: 8),
              // price + chevron
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('৳${price.toStringAsFixed(0)}',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900,
                        color: grad[0]),
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 6),
                Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400, size: 20),
              ]),
            ]),
          ),

          // status strip
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: [grad[0].withOpacity(.06), grad[1].withOpacity(.03)]),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(delivered ? 0 : 22),
                bottomRight: Radius.circular(delivered ? 0 : 22)),
              border: Border(top: BorderSide(color: grad[1].withOpacity(.12))),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            child: Row(children: [
              Container(width: 8, height: 8,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: grad), shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: grad.last.withOpacity(.5), blurRadius: 6)])),
              const SizedBox(width: 8),
              Text(_statusLabel(st),
                  style: TextStyle(color: grad[0],
                      fontWeight: FontWeight.w800, fontSize: 13)),
              const Spacer(),
              Text('Order #${o['id'] ?? ''}',
                  style: const TextStyle(color: _sub, fontSize: 11.5,
                      fontWeight: FontWeight.w600)),
            ]),
          ),

          // rate supplier button (delivered only)
          if (delivered)
            o['has_rating'] == true
                ? Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    decoration: BoxDecoration(
                      color: _grn2.withOpacity(.1),
                      borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(22),
                          bottomRight: Radius.circular(22)),
                      border: Border(top: BorderSide(color: _grn2.withOpacity(.2))),
                    ),
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.verified_rounded, color: _grn2, size: 18),
                      const SizedBox(width: 8),
                      Text('Rating Completed',
                          style: TextStyle(color: _grn1,
                              fontSize: 14, fontWeight: FontWeight.w800)),
                    ]),
                  )
                : _Tap(
                    onTap: () async {
                      final result = await Navigator.push(context,
                          MaterialPageRoute(builder: (_) => RateSupplierScreen(order: o)));
                      if (result == true) _load();
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            colors: [Color(0xFF7C1A00), Color(0xFFD03800),
                                     Color(0xFFF06000), Color(0xFFFF9500)],
                            stops: [0.0, 0.32, 0.68, 1.0],
                            begin: Alignment.topLeft, end: Alignment.bottomRight),
                        borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(22),
                            bottomRight: Radius.circular(22)),
                      ),
                      child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(Icons.star_rounded, color: Colors.white, size: 18),
                        SizedBox(width: 8),
                        Text('Rate this Supplier',
                            style: TextStyle(color: Colors.white,
                                fontSize: 14, fontWeight: FontWeight.w800)),
                      ]),
                    ),
                  ),
        ]),
      ),
    );
  }

  Widget _metaPill(IconData icon, String text, Color c) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
        color: c.withOpacity(.08), borderRadius: BorderRadius.circular(8)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 12, color: c),
      const SizedBox(width: 5),
      Text(text, style: TextStyle(color: c, fontSize: 11.5, fontWeight: FontWeight.w600)),
    ]),
  );

  Widget _empty() => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
    Container(width: 90, height: 90,
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [_c1, _c3]),
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: _c2.withOpacity(.3), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: const Icon(Icons.receipt_long_rounded, size: 44, color: Colors.white)),
    const SizedBox(height: 20),
    const Text('No orders yet', style: TextStyle(fontSize: 18,
        fontWeight: FontWeight.w800, color: _txt)),
    const SizedBox(height: 8),
    const Text('Orders you place will appear here.',
        style: TextStyle(color: _sub, fontSize: 14)),
  ]));

  Widget _blob(double sz, Color c, double op) =>
      Container(width: sz, height: sz,
          decoration: BoxDecoration(shape: BoxShape.circle, color: c.withOpacity(op)));
}
