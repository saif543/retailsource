import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/stock_service.dart';
import '../../config/language.dart';
import 'post_stock_screen.dart';
import 'edit_stock_screen.dart';

const _sp0 = Color(0xFF16002E);
const _sp1 = Color(0xFF3B0D6B);
const _sp2 = Color(0xFF7B2FD4);
const _sp3 = Color(0xFFBB6BF7);
const _bg  = Color(0xFFF8F0FF);
const _txt = Color(0xFF212121);
const _sub = Color(0xFF757575);
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
    onTapUp: (_) { _c.reverse(); widget.onTap(); },
    onTapCancel: () => _c.reverse(),
    child: AnimatedBuilder(animation: _s,
      builder: (_, ch) => Transform.scale(scale: _s.value, child: ch),
      child: widget.child),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
class MyStockScreen extends StatefulWidget {
  const MyStockScreen({super.key});
  @override State<MyStockScreen> createState() => _MSS();
}

class _MSS extends State<MyStockScreen> {
  int _filter = 0;
  bool _loading = true;
  List<Map<String, dynamic>> _all = [];

  @override
  void initState() { super.initState(); appLang.addListener(_onLangChange); _load(); }
  void _onLangChange() => setState(() {});
  @override
  void dispose() { appLang.removeListener(_onLangChange); super.dispose(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = await StockService.getMyStock();
    if (!mounted) return;
    setState(() { _all = list; _loading = false; });
  }

  List<Map<String, dynamic>> get _filtered {
    if (_filter == 1) return _all.where((s) => s['status'] == 'Available').toList();
    if (_filter == 2) return _all.where((s) => s['status'] == 'Sold Out').toList();
    return _all;
  }

  int get _availableCount => _all.where((s) => s['status'] == 'Available').length;
  int get _soldCount => _all.where((s) => s['status'] == 'Sold Out').length;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _bg,
    body: Column(children: [
      _buildHeader(),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: Row(children: [
          _chip('All', 0, Icons.list_rounded),
          const SizedBox(width: 8),
          _chip('Available', 1, Icons.check_circle_outline),
          const SizedBox(width: 8),
          _chip('Sold Out', 2, Icons.cancel_outlined),
        ]),
      ),
      Expanded(child: _loading
          ? const Center(child: CircularProgressIndicator(color: _sp2))
          : RefreshIndicator(
              color: _sp2,
              onRefresh: _load,
              child: _filtered.isEmpty ? _empty() : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
                itemCount: _filtered.length,
                itemBuilder: (_, i) => _card(_filtered[i]),
              ),
            )),
    ]),
  );

  Widget _buildHeader() => Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        colors: [_sp0, _sp1, _sp2, _sp3],
        stops: [0.0, 0.35, 0.7, 1.0],
        begin: Alignment.topLeft, end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.only(
        bottomLeft: Radius.circular(28), bottomRight: Radius.circular(28)),
    ),
    child: SafeArea(bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 20, 20),
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
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(S('my_stock_title'), style: const TextStyle(color: Colors.white,
                  fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -.4)),
              SizedBox(height: 2),
              Text('Manage your listed stock items',
                  style: TextStyle(color: Colors.white54, fontSize: 12.5)),
            ])),
            _Tap(onTap: () async {
              await Navigator.push(context, MaterialPageRoute(
                  builder: (_) => const PostStockScreen()));
              _load();
            },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(.18),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(.25)),
                ),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.add_rounded, color: Colors.white, size: 16),
                  SizedBox(width: 4),
                  Text('Post', style: TextStyle(color: Colors.white,
                      fontWeight: FontWeight.w800, fontSize: 13)),
                ]))),
          ]),
          const SizedBox(height: 16),
          Row(children: [
            _statPill('${_all.length}', 'Total', Icons.inventory_2_outlined),
            const SizedBox(width: 10),
            _statPill('$_availableCount', 'Available', Icons.check_circle_outline),
            const SizedBox(width: 10),
            _statPill('$_soldCount', 'Sold Out', Icons.cancel_outlined),
          ]),
        ]),
      ),
    ),
  );

  Widget _statPill(String val, String label, IconData icon) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(.2)),
      ),
      child: Column(children: [
        Icon(icon, color: Colors.white70, size: 16),
        const SizedBox(height: 4),
        Text(val, style: const TextStyle(
            color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 11)),
      ]),
    ),
  );

  Widget _chip(String label, int idx, IconData icon) {
    final sel = _filter == idx;
    return Expanded(child: _Tap(onTap: () {
      HapticFeedback.selectionClick();
      setState(() => _filter = idx);
    },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          gradient: sel ? const LinearGradient(colors: [_sp1, _sp3]) : null,
          color: sel ? null : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: sel ? Colors.transparent : const Color(0xFFE8D5FF)),
          boxShadow: sel ? [BoxShadow(color: _sp3.withOpacity(.25),
              blurRadius: 8, offset: const Offset(0, 3))] : null,
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 15, color: sel ? Colors.white : _sub),
          const SizedBox(width: 5),
          Text(label, style: TextStyle(
              color: sel ? Colors.white : _txt,
              fontWeight: FontWeight.w800, fontSize: 12.5)),
        ]),
      )));
  }

  Widget _empty() => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
    Container(width: 72, height: 72,
      decoration: BoxDecoration(color: _sp3.withOpacity(.1), shape: BoxShape.circle),
      child: const Icon(Icons.inventory_2_outlined, color: _sp2, size: 34)),
    const SizedBox(height: 16),
    Text(S('no_stock_yet'), style: const TextStyle(fontSize: 16,
        fontWeight: FontWeight.w800, color: _txt)),
    const SizedBox(height: 6),
    const Text('Post your first stock item to get orders',
        style: TextStyle(color: _sub, fontSize: 13)),
    const SizedBox(height: 20),
    _PostBtn(),
  ]));

  Widget _card(Map<String, dynamic> s) {
    final available = s['status'] == 'Available';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: _sp1.withOpacity(.06), blurRadius: 14, offset: const Offset(0, 4)),
          BoxShadow(color: Colors.black.withOpacity(.03), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 10, 10),
          child: Row(children: [
            Container(width: 44, height: 44,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: available ? const [_sp1, _sp3] : const [Color(0xFF555), Color(0xFF999)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12)),
              child: Icon(available ? Icons.inventory_2_rounded : Icons.remove_shopping_cart_rounded,
                  color: Colors.white, size: 22)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text((s['product'] as String?) ?? '',
                  style: const TextStyle(fontSize: 15,
                      fontWeight: FontWeight.w900, color: _txt)),
              Text('Posted ${s['posted'] ?? ''}',
                  style: const TextStyle(color: _sub, fontSize: 11.5)),
            ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: available
                    ? const [_sp1, _sp3] : const [_red1, _red2]),
                borderRadius: BorderRadius.circular(8)),
              child: Text(available ? 'AVAILABLE' : 'SOLD OUT',
                  style: const TextStyle(color: Colors.white,
                      fontWeight: FontWeight.w900, fontSize: 10))),
            const SizedBox(width: 4),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: _sub),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              onSelected: (v) async {
                if (v == 'edit') {
                  final res = await Navigator.push(context,
                      MaterialPageRoute(builder: (_) => EditStockScreen(stock: s)));
                  if (res == true || res == 'deleted') _load();
                } else if (v == 'delete') {
                  _confirmDelete(s);
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'edit',
                    child: Row(children: [
                      Icon(Icons.edit_rounded, size: 16, color: _sp2),
                      SizedBox(width: 8), Text('Edit'),
                    ])),
                const PopupMenuItem(value: 'delete',
                    child: Row(children: [
                      Icon(Icons.delete_outline, size: 16, color: _red2),
                      SizedBox(width: 8), Text('Delete', style: TextStyle(color: _red2)),
                    ])),
              ],
            ),
          ]),
        ),
        Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: _bg, borderRadius: BorderRadius.circular(12)),
          child: Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Quantity', style: TextStyle(color: _sub, fontSize: 11)),
              const SizedBox(height: 2),
              Text((s['qty'] as String?) ?? '',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: _txt)),
            ])),
            Container(width: 1, height: 30, color: const Color(0xFFE8D5FF)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Price/Unit', style: TextStyle(color: _sub, fontSize: 11)),
              const SizedBox(height: 2),
              Text((s['price'] as String?) ?? '',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: _sp2)),
            ])),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Row(children: [
            const Icon(Icons.place_outlined, size: 14, color: _sub),
            const SizedBox(width: 4),
            Expanded(child: Text((s['loc'] as String?) ?? '',
                style: const TextStyle(fontSize: 12, color: _sub))),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          child: Row(children: [
            Expanded(child: _Tap(onTap: () async {
              final res = await Navigator.push(context,
                  MaterialPageRoute(builder: (_) => EditStockScreen(stock: s)));
              if (res == true || res == 'deleted') _load();
            },
              child: Container(height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: available
                      ? const [_sp1, _sp3] : const [Color(0xFF0E4470), Color(0xFF2196F3)]),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [BoxShadow(
                      color: (available ? _sp3 : const Color(0xFF2196F3)).withOpacity(.25),
                      blurRadius: 8, offset: const Offset(0, 3))],
                ),
                child: Center(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(available ? Icons.edit_rounded : Icons.refresh_rounded,
                      color: Colors.white, size: 14),
                  const SizedBox(width: 6),
                  Text(available ? 'Edit' : 'Repost', style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13)),
                ]))))),
            const SizedBox(width: 10),
            Expanded(child: _Tap(onTap: () => _confirmDelete(s),
              child: Container(height: 40,
                decoration: BoxDecoration(
                  border: Border.all(color: _red2.withOpacity(.5)),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.delete_outline, color: _red2, size: 14),
                  SizedBox(width: 6),
                  Text('Delete', style: TextStyle(color: _red2,
                      fontWeight: FontWeight.w800, fontSize: 13)),
                ]))))),
          ]),
        ),
      ]),
    );
  }

  Future<void> _confirmDelete(Map<String, dynamic> s) async {
    final stockId = s['stock_id'] as int?;
    if (stockId == null) return;
    HapticFeedback.mediumImpact();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 56, height: 56,
            decoration: BoxDecoration(color: _red2.withOpacity(.1), shape: BoxShape.circle),
            child: const Icon(Icons.delete_outline, color: _red2, size: 28)),
          const SizedBox(height: 16),
          Text(S('delete_stock_title'), style: const TextStyle(
              fontSize: 18, fontWeight: FontWeight.w900, color: _txt)),
          const SizedBox(height: 8),
          const Text('This action cannot be undone.',
              textAlign: TextAlign.center, style: TextStyle(color: _sub, fontSize: 13)),
          const SizedBox(height: 24),
          Row(children: [
            Expanded(child: _Tap(onTap: () => Navigator.pop(context, false),
              child: Container(height: 46,
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFE0E0E0)),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Center(child: Text('Cancel',
                    style: TextStyle(fontWeight: FontWeight.w700, color: _sub)))))),
            const SizedBox(width: 12),
            Expanded(child: _Tap(onTap: () => Navigator.pop(context, true),
              child: Container(height: 46,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [_red1, _red2]),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Center(child: Text('Delete',
                    style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white)))))),
          ]),
        ])),
      ),
    );
    if (confirm != true || !mounted) return;
    final res = await StockService.deleteStock(stockId);
    if (!mounted) return;
    if (res.ok) {
      _load();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: _red1,
        content: Text(res.error ?? 'Delete failed',
            style: const TextStyle(fontWeight: FontWeight.w600))));
    }
  }
}

class _PostBtn extends StatelessWidget {
  @override
  Widget build(BuildContext ctx) => GestureDetector(
    onTap: () async {
      await Navigator.push(ctx, MaterialPageRoute(builder: (_) => const PostStockScreen()));
    },
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 13),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [_sp1, _sp3]),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: _sp3.withOpacity(.3), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: const Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.add_rounded, color: Colors.white, size: 18),
        SizedBox(width: 8),
        Text('Post First Stock', style: TextStyle(
            color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14)),
      ]),
    ),
  );
}
