import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/demand_service.dart';
import 'order_confirm_screen.dart';

// ── palette ───────────────────────────────────────────────────────────────────
const _c0   = Color(0xFF060D28);
const _c1   = Color(0xFF0E2260);
const _c2   = Color(0xFF1F4BD5);
const _c3   = Color(0xFF6C3FE8);
const _bg   = Color(0xFFF2F5FF);
const _txt  = Color(0xFF212121);
const _sub  = Color(0xFF757575);
const _grn1 = Color(0xFF054F3A);
const _grn2 = Color(0xFF0FBB84);
const _amb1 = Color(0xFFAD4A0A);
const _amb2 = Color(0xFFF5981E);

const _catGrad = {
  'Grocery'   : [Color(0xFFAD4A0A), Color(0xFFF5981E)],
  'Pharmacy'  : [Color(0xFF7B1C1C), Color(0xFFEF5350)],
  'Stationary': [Color(0xFF1840AF), Color(0xFF4F8EF7)],
  'Hardware'  : [Color(0xFF1B4D3E), Color(0xFF26A17B)],
};

// ── tap wrapper ───────────────────────────────────────────────────────────────
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

// ─────────────────────────────────────────────────────────────────────────────
class StockOrderScreen extends StatefulWidget {
  final Map<String, dynamic> stock;
  const StockOrderScreen({super.key, required this.stock});
  @override State<StockOrderScreen> createState() => _SOS();
}

class _SOS extends State<StockOrderScreen> with SingleTickerProviderStateMixin {
  bool _busy = false;

  late final _fadeC = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 420));

  @override
  void initState() { super.initState(); _fadeC.forward(); }
  @override
  void dispose() { _fadeC.dispose(); super.dispose(); }

  Future<void> _proceed() async {
    final s          = widget.stock;
    final defaultQty = (s['quantity_available'] as num).toDouble();

    setState(() => _busy = true);
    final res = await DemandService.createDemand(
      productId: s['product_id'] as int,
      variantId: s['variant_id'] as int,
      quantity:  defaultQty.clamp(1, defaultQty).toDouble(),
      unit:      s['unit'] as String,
      notes:     'Direct order from stock browse',
    );
    if (!mounted) return;
    setState(() => _busy = false);

    final demandId = res['demand_id'] as int?;
    if (res['statusCode'] != 201 || demandId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: const Color(0xFFC62828),
            content: Text(res['error']?.toString() ?? 'Failed to create demand')));
      return;
    }

    final placed = await Navigator.pushReplacement<bool, dynamic>(context,
      MaterialPageRoute(builder: (_) => OrderConfirmScreen(
        demandId:        demandId,
        stockId:         s['stock_id'] as int,
        supplierName:    (s['company_name'] ?? s['stockholder_name']) as String,
        productLabel:    '${s['product_name']} - ${s['variant_name']}',
        pricePerUnit:    (s['price_per_unit'] as num).toDouble(),
        unit:            s['unit'] as String,
        maxQuantity:     defaultQty,
        defaultQuantity: defaultQty,
      )),
    );
    if (placed == true && mounted) Navigator.pop(context, true);
  }

  // ════════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final s        = widget.stock;
    final price    = (s['price_per_unit'] as num).toDouble();
    final qty      = (s['quantity_available'] as num).toDouble();
    final dist     = (s['distance_km'] as num?)?.toDouble();
    final rating   = (s['rating_avg'] as num?)?.toDouble() ?? 0;
    final catName  = (s['category_name'] ?? '') as String;
    final supplier = ((s['company_name'] ?? s['stockholder_name']) as String?) ?? '';
    final grad     = _catGrad[catName] ?? [_amb1, _amb2];

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _bg,
        body: FadeTransition(
          opacity: CurvedAnimation(parent: _fadeC, curve: Curves.easeOut),
          child: Column(children: [
            _header(s, grad, catName),
            Expanded(child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // ── price hero ──────────────────────────────────────────────
                _priceHero(price, qty, s['unit'] as String, grad),
                const SizedBox(height: 20),
                // ── supplier card ───────────────────────────────────────────
                _supplierCard(supplier, dist, rating),
                const SizedBox(height: 20),
                // ── details card ────────────────────────────────────────────
                _detailsCard(s, grad),
                // ── notes ───────────────────────────────────────────────────
                if ((s['additional_notes'] ?? '').toString().isNotEmpty) ...[
                  const SizedBox(height: 20),
                  _notesCard(s['additional_notes'] as String),
                ],
                const SizedBox(height: 32),
                // ── order CTA ───────────────────────────────────────────────
                _orderBtn(grad),
              ]),
            )),
          ]),
        ),
      ),
    );
  }

  // ── gradient header ───────────────────────────────────────────────────────
  Widget _header(Map<String, dynamic> s, List<Color> grad, String catName) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: [_c0, _c1, grad[0], grad[1]],
            stops: const [0.0, 0.32, 0.70, 1.0],
            begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(32), bottomRight: Radius.circular(32)),
      ),
      child: SafeArea(bottom: false,
        child: Stack(children: [
          Positioned(top: -20, right: -30, child: _blob(130, Colors.white, .04)),
          Positioned(top: 8,   right: 50,  child: _blob(44,  grad[1], .35)),
          Positioned(top: 45,  left: -20,  child: _blob(80,  _c3, .18)),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 20, 26),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // nav row
              Row(children: [
                ClipRRect(borderRadius: BorderRadius.circular(12),
                  child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                    child: _Tap(onTap: () => Navigator.pop(context),
                      child: Container(width: 42, height: 42,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.14),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withOpacity(0.25)),
                        ),
                        child: const Icon(Icons.arrow_back_ios_new_rounded,
                            color: Colors.white, size: 17)),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Stock Details',
                      style: TextStyle(color: Colors.white, fontSize: 18,
                          fontWeight: FontWeight.w900, letterSpacing: -.3)),
                  Text(catName,
                      style: TextStyle(color: Colors.white.withOpacity(.65), fontSize: 12.5)),
                ])),
                // available badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(.18),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(.3)),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.check_circle_rounded, color: Colors.white, size: 12),
                    const SizedBox(width: 5),
                    const Text('Available', style: TextStyle(color: Colors.white,
                        fontSize: 12, fontWeight: FontWeight.w700)),
                  ]),
                ),
              ]),
              const SizedBox(height: 20),
              // product identity row
              Row(children: [
                Container(width: 58, height: 58,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(.2),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.white.withOpacity(.35), width: 1.5),
                  ),
                  child: const Icon(Icons.inventory_2_rounded, color: Colors.white, size: 28)),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${s['product_name']}',
                      style: const TextStyle(color: Colors.white, fontSize: 20,
                          fontWeight: FontWeight.w900, letterSpacing: -.4)),
                  const SizedBox(height: 5),
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(.2),
                        borderRadius: BorderRadius.circular(8)),
                      child: Text('${s['variant_name']}',
                          style: const TextStyle(color: Colors.white,
                              fontSize: 12, fontWeight: FontWeight.w700))),
                    const SizedBox(width: 8),
                    Text(catName,
                        style: TextStyle(color: Colors.white.withOpacity(.65), fontSize: 12)),
                  ]),
                ])),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }

  // ── price hero card ───────────────────────────────────────────────────────
  Widget _priceHero(double price, double qty, String unit, List<Color> grad) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: [grad[0].withOpacity(.08), grad[1].withOpacity(.04)]),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: grad[1].withOpacity(.25)),
      ),
      child: Row(children: [
        // price
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Unit Price', style: TextStyle(color: grad[0],
              fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('৳${price.toStringAsFixed(0)}',
              style: TextStyle(color: grad[0], fontSize: 34,
                  fontWeight: FontWeight.w900, letterSpacing: -1)),
          Text('per $unit', style: TextStyle(color: grad[0].withOpacity(.7), fontSize: 13)),
        ])),
        // divider
        Container(width: 1, height: 60, color: grad[1].withOpacity(.2)),
        const SizedBox(width: 20),
        // available qty
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Available', style: TextStyle(color: grad[0],
              fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('${qty % 1 == 0 ? qty.toInt() : qty}',
              style: TextStyle(color: grad[0], fontSize: 34,
                  fontWeight: FontWeight.w900, letterSpacing: -1)),
          Text(unit, style: TextStyle(color: grad[0].withOpacity(.7), fontSize: 13)),
        ])),
      ]),
    );
  }

  // ── supplier card ─────────────────────────────────────────────────────────
  Widget _supplierCard(String name, double? dist, double rating) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDeco(),
      child: Row(children: [
        // supplier avatar
        Container(width: 52, height: 52,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [_c1, _c3],
                begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: _c2.withOpacity(.38),
                blurRadius: 12, offset: const Offset(0, 4))],
          ),
          child: const Icon(Icons.store_rounded, color: Colors.white, size: 24)),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Supplier', style: TextStyle(fontSize: 12,
              color: _sub, fontWeight: FontWeight.w500)),
          const SizedBox(height: 3),
          Text(name, style: const TextStyle(fontSize: 15.5,
              fontWeight: FontWeight.w800, color: _txt),
              maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 8),
          Row(children: [
            if (dist != null) ...[
              _infoPill(Icons.near_me_rounded,
                  '${dist.toStringAsFixed(1)} km', _c2),
              const SizedBox(width: 8),
            ],
            if (rating > 0)
              _infoPill(Icons.star_rounded,
                  rating.toStringAsFixed(1), Colors.amber.shade700),
          ]),
        ])),
      ]),
    );
  }

  // ── details card ──────────────────────────────────────────────────────────
  Widget _detailsCard(Map<String, dynamic> s, List<Color> grad) {
    final area = (s['warehouse_area'] ?? '') as String;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDeco(),
      child: Column(children: [
        _infoRow(
          icon: Icons.category_rounded, iconColor: _c2,
          label: 'Category', value: '${s['category_name']}'),
        _divider(),
        _infoRow(
          icon: Icons.sell_rounded, iconColor: grad[0],
          label: 'Price',
          value: '৳${(s['price_per_unit'] as num).toStringAsFixed(0)} / ${s['unit']}',
          valueBold: true),
        _divider(),
        _infoRow(
          icon: Icons.inventory_2_rounded, iconColor: _grn2,
          label: 'Stock', value:
              '${(s['quantity_available'] as num).toStringAsFixed(0)} ${s['unit']}'),
        if (area.isNotEmpty) ...[
          _divider(),
          _infoRow(
            icon: Icons.place_rounded, iconColor: _sub,
            label: 'Area', value: area),
        ],
      ]),
    );
  }

  // ── notes card ────────────────────────────────────────────────────────────
  Widget _notesCard(String notes) => Container(
    padding: const EdgeInsets.all(18),
    decoration: _cardDeco(),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(width: 36, height: 36,
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [_amb1, _amb2]),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [BoxShadow(color: _amb2.withOpacity(.35),
              blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: const Icon(Icons.sticky_note_2_rounded, color: Colors.white, size: 18)),
      const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Supplier Notes', style: TextStyle(fontSize: 13,
            fontWeight: FontWeight.w700, color: _sub)),
        const SizedBox(height: 6),
        Text(notes, style: const TextStyle(fontSize: 14, color: _txt, height: 1.55)),
      ])),
    ]),
  );

  // ── order CTA button ──────────────────────────────────────────────────────
  Widget _orderBtn(List<Color> grad) => _Tap(
    onTap: _busy ? () {} : _proceed,
    child: Container(
      width: double.infinity,
      height: 58,
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: [grad[0], grad[1]],
            begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: grad.last.withOpacity(.48),
              blurRadius: 22, spreadRadius: -2, offset: const Offset(0, 10)),
        ],
        border: Border.all(color: Colors.white.withOpacity(.12)),
      ),
      child: Stack(children: [
        // gloss
        Positioned.fill(child: ClipRRect(borderRadius: BorderRadius.circular(18),
          child: Align(alignment: Alignment.topCenter,
            child: FractionallySizedBox(heightFactor: .45, widthFactor: 1,
              child: Container(decoration: BoxDecoration(
                gradient: LinearGradient(begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.white.withOpacity(.22), Colors.transparent]))))))),
        Center(child: _busy
            ? const SizedBox(width: 22, height: 22,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
            : const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.shopping_cart_checkout_rounded, color: Colors.white, size: 22),
                SizedBox(width: 10),
                Text('Order This Stock', style: TextStyle(color: Colors.white,
                    fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: .2)),
              ])),
      ]),
    ),
  );

  // ── helpers ───────────────────────────────────────────────────────────────
  BoxDecoration _cardDeco() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(22),
    boxShadow: [
      BoxShadow(color: _c1.withOpacity(.08), blurRadius: 20, offset: const Offset(0, 6)),
      BoxShadow(color: Colors.black.withOpacity(.03), blurRadius: 4, offset: const Offset(0, 2)),
    ],
  );

  Widget _infoRow({
    required IconData icon, required Color iconColor,
    required String label, required String value, bool valueBold = false,
  }) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(children: [
      Container(width: 34, height: 34,
        decoration: BoxDecoration(
          color: iconColor.withOpacity(.1), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: iconColor, size: 17)),
      const SizedBox(width: 12),
      SizedBox(width: 80,
        child: Text(label, style: const TextStyle(fontSize: 13,
            color: _sub, fontWeight: FontWeight.w500))),
      Expanded(child: Text(value, style: TextStyle(fontSize: 14, color: _txt,
          fontWeight: valueBold ? FontWeight.w800 : FontWeight.w600))),
    ]),
  );

  Widget _divider() => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Divider(height: 1, color: Colors.grey.shade100),
  );

  Widget _infoPill(IconData icon, String text, Color c) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
        color: c.withOpacity(.1), borderRadius: BorderRadius.circular(8)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 12, color: c),
      const SizedBox(width: 5),
      Text(text, style: TextStyle(color: c, fontSize: 11.5, fontWeight: FontWeight.w700)),
    ]),
  );

  Widget _blob(double sz, Color c, double op) =>
      Container(width: sz, height: sz,
          decoration: BoxDecoration(shape: BoxShape.circle, color: c.withOpacity(op)));
}
