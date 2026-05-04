import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/order_service.dart';
import 'order_detail_screen.dart';

const _sg0 = Color(0xFF012B1E);
const _sg1 = Color(0xFF054F3A);
const _sg2 = Color(0xFF0A7A56);
const _sg3 = Color(0xFF0FBB84);
const _bg  = Color(0xFFF0FBF6);
const _txt = Color(0xFF212121);
const _sub = Color(0xFF757575);

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
    onTapUp: (_) { _c.reverse(); widget.onTap(); },
    onTapCancel: () => _c.reverse(),
    child: AnimatedBuilder(animation: _s,
      builder: (_, ch) => Transform.scale(scale: _s.value, child: ch),
      child: widget.child),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
class OrderInboxScreen extends StatefulWidget {
  const OrderInboxScreen({super.key});
  @override State<OrderInboxScreen> createState() => _OIS();
}

class _OIS extends State<OrderInboxScreen> {
  int _filter = 0;
  bool _loading = true;
  List<Map<String, dynamic>> _orders = [];

  final _filterKeys = ['', 'pending', 'accepted', 'out_for_delivery', 'delivered'];
  final _filterLabels = ['All', 'Pending', 'Accepted', 'On Way', 'Delivered'];

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = await OrderService.getIncomingOrders();
    if (!mounted) return;
    setState(() { _orders = list; _loading = false; });
  }

  List<Map<String, dynamic>> get _filtered {
    if (_filter == 0) return _orders;
    return _orders.where((o) => o['status'] == _filterKeys[_filter]).toList();
  }

  int _count(String key) => key.isEmpty
      ? _orders.length
      : _orders.where((o) => o['status'] == key).length;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _bg,
    body: Column(children: [
      _buildHeader(),
      Expanded(child: _loading
          ? const Center(child: CircularProgressIndicator(color: _sg2))
          : RefreshIndicator(
              color: _sg2,
              onRefresh: _load,
              child: _filtered.isEmpty
                  ? _empty()
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                      itemCount: _filtered.length,
                      itemBuilder: (_, i) => _card(_filtered[i])),
            )),
    ]),
  );

  Widget _buildHeader() => Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        colors: [_sg0, _sg1, _sg2, _sg3],
        stops: [0.0, 0.35, 0.7, 1.0],
        begin: Alignment.topLeft, end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.only(
        bottomLeft: Radius.circular(28), bottomRight: Radius.circular(28)),
    ),
    child: SafeArea(bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 20, 16),
        child: Column(children: [
          Row(children: [
            _Tap(onTap: () => Navigator.maybePop(context),
              child: Container(width: 42, height: 42,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(.14),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(.25)),
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white, size: 17))),
            const SizedBox(width: 14),
            const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Order Inbox', style: TextStyle(color: Colors.white,
                  fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -.4)),
              SizedBox(height: 2),
              Text('Manage incoming orders', style: TextStyle(color: Colors.white54, fontSize: 12.5)),
            ])),
            _Tap(onTap: _load,
              child: Container(width: 40, height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(.14),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withOpacity(.25)),
                ),
                child: const Icon(Icons.refresh_rounded, color: Colors.white, size: 20))),
          ]),
          const SizedBox(height: 14),
          SizedBox(height: 36,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _filterLabels.length,
              itemBuilder: (_, i) {
                final sel = _filter == i;
                final cnt = _count(_filterKeys[i]);
                return _Tap(onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _filter = i);
                },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: sel ? const LinearGradient(colors: [_sg1, _sg3]) : null,
                      color: sel ? null : Colors.white.withOpacity(.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: sel ? Colors.transparent : Colors.white.withOpacity(.3)),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Text(_filterLabels[i], style: TextStyle(
                          color: Colors.white,
                          fontWeight: sel ? FontWeight.w800 : FontWeight.w600,
                          fontSize: 12.5)),
                      if (cnt > 0) ...[
                        const SizedBox(width: 5),
                        Container(
                          width: 18, height: 18,
                          decoration: BoxDecoration(
                            color: sel ? Colors.white.withOpacity(.3) : Colors.white.withOpacity(.2),
                            shape: BoxShape.circle,
                          ),
                          child: Center(child: Text('$cnt',
                              style: const TextStyle(color: Colors.white,
                                  fontSize: 9.5, fontWeight: FontWeight.w900)))),
                      ],
                    ]),
                  ));
              },
            )),
        ]),
      ),
    ),
  );

  Widget _empty() => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
    Container(width: 72, height: 72,
      decoration: BoxDecoration(color: _sg3.withOpacity(.1), shape: BoxShape.circle),
      child: const Icon(Icons.inbox_rounded, color: _sg2, size: 34)),
    const SizedBox(height: 16),
    const Text('No orders', style: TextStyle(fontSize: 16,
        fontWeight: FontWeight.w800, color: _txt)),
    const SizedBox(height: 6),
    Text(_filter == 0
        ? 'New orders from shops will appear here'
        : 'No ${_filterLabels[_filter].toLowerCase()} orders',
        style: const TextStyle(color: _sub, fontSize: 13)),
  ]));

  Widget _card(Map<String, dynamic> o) {
    final st = o['status'] as String;
    List<Color> grad;
    String label;
    switch (st) {
      case 'pending':
        grad = const [Color(0xFFAD4A0A), Color(0xFFF5981E)];
        label = 'PENDING';
        break;
      case 'accepted':
        grad = const [_sg1, _sg3];
        label = 'ACCEPTED';
        break;
      case 'out_for_delivery':
        grad = const [Color(0xFF2D238A), Color(0xFF7C6FF5)];
        label = 'ON WAY';
        break;
      default:
        grad = const [Color(0xFF1A5C3A), Color(0xFF2ECC71)];
        label = 'DELIVERED';
    }
    final shop = (o['shop'] as String?) ?? 'Shop';
    final initials = shop.split(' ').where((s) => s.isNotEmpty).take(2).map((s) => s[0]).join();

    return _Tap(
      onTap: () async {
        await Navigator.push(context, MaterialPageRoute(
            builder: (_) => StockholderOrderDetailScreen(order: o)));
        _load();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(color: _sg1.withOpacity(.07), blurRadius: 14, offset: const Offset(0, 4)),
            BoxShadow(color: Colors.black.withOpacity(.03), blurRadius: 4, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Row(children: [
              Container(width: 40, height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: grad,
                      begin: Alignment.topLeft, end: Alignment.bottomRight),
                  shape: BoxShape.circle),
                child: Center(child: Text(initials.isEmpty ? '#' : initials,
                    style: const TextStyle(color: Colors.white,
                        fontWeight: FontWeight.w900, fontSize: 14)))),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(st == 'pending' ? 'New Order Request' : shop,
                    style: const TextStyle(fontSize: 14,
                        fontWeight: FontWeight.w800, color: _txt)),
                Text((o['product'] as String?) ?? '',
                    style: const TextStyle(fontSize: 12.5, color: _sub)),
              ])),
              Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: grad),
                  borderRadius: BorderRadius.circular(8)),
                child: Text(label, style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w900, fontSize: 10))),
            ]),
          ),
          Container(
            margin: const EdgeInsets.fromLTRB(14, 0, 14, 12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: _bg, borderRadius: BorderRadius.circular(10)),
            child: Row(children: [
              Expanded(child: Text('${o['qty']}',
                  style: const TextStyle(fontWeight: FontWeight.w700, color: _sub, fontSize: 13))),
              Text('৳${(o['price'] as num?)?.toStringAsFixed(0) ?? '0'}',
                  style: const TextStyle(color: _sg2,
                      fontWeight: FontWeight.w900, fontSize: 16)),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: _sub, size: 18),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
            child: Text((o['time'] as String?) ?? '',
                style: const TextStyle(fontSize: 11, color: _sub))),
        ]),
      ),
    );
  }
}
