import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/order_service.dart';
import '../../services/profile_service.dart';
import '../../services/location_service.dart';
import '../shared/location_picker_screen.dart';
import 'my_orders_screen.dart';

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
class OrderConfirmScreen extends StatefulWidget {
  final int demandId;
  final int stockId;
  final String supplierName;
  final String productLabel;
  final double pricePerUnit;
  final String unit;
  final double maxQuantity;
  final double defaultQuantity;
  final String? defaultAddress;
  final double? deliveryLat;
  final double? deliveryLng;

  const OrderConfirmScreen({
    super.key,
    required this.demandId,
    required this.stockId,
    required this.supplierName,
    required this.productLabel,
    required this.pricePerUnit,
    required this.unit,
    required this.maxQuantity,
    required this.defaultQuantity,
    this.defaultAddress,
    this.deliveryLat,
    this.deliveryLng,
  });

  @override
  State<OrderConfirmScreen> createState() => _OCS();
}

class _OCS extends State<OrderConfirmScreen> with SingleTickerProviderStateMixin {
  late final _qtyCtrl = TextEditingController(
    text: widget.defaultQuantity.clamp(1, widget.maxQuantity).toStringAsFixed(0));

  LocationResult? _loc;
  bool _busy = false;

  late final _fadeC = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 400));

  @override
  void initState() {
    super.initState();
    _fadeC.forward();
    _initLocation();
    _qtyCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() { _qtyCtrl.dispose(); _fadeC.dispose(); super.dispose(); }

  Future<void> _initLocation() async {
    // 1. Use widget-passed address first (from demand location)
    if (widget.defaultAddress != null && widget.defaultAddress!.isNotEmpty) {
      setState(() => _loc = LocationResult(
        lat: widget.deliveryLat ?? 0,
        lng: widget.deliveryLng ?? 0,
        address: widget.defaultAddress!,
        area: '', district: '',
      ));
      return;
    }
    // 2. Fall back to saved shop location (cache first, then network)
    final cached = await ProfileService.getCachedLocation();
    if (cached != null && mounted) setState(() => _loc = cached);

    final profile = await ProfileService.getProfile();
    if (!mounted) return;
    final prof = (profile?['profile'] as Map?) ?? {};
    final lat  = (prof['lat'] as num?)?.toDouble();
    final lng  = (prof['lng'] as num?)?.toDouble();
    if (lat != null && lat != 0 && lng != null && lng != 0) {
      final addr = (prof['shop_address'] as String?) ?? '';
      setState(() => _loc = LocationResult(
        lat: lat, lng: lng,
        address: addr.isNotEmpty ? addr : '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}',
        area:     (prof['area']     as String?) ?? '',
        district: (prof['district'] as String?) ?? '',
      ));
    }
  }

  Future<void> _pickLocation() async {
    final r = await Navigator.push<LocationResult>(context,
      MaterialPageRoute(builder: (_) => LocationPickerScreen(
        title: 'Delivery Location',
        initialLat: _loc?.lat,
        initialLng: _loc?.lng,
      )));
    if (r != null && mounted) setState(() => _loc = r);
  }

  double get _qty   => double.tryParse(_qtyCtrl.text.trim()) ?? 0;
  double get _total => _qty * widget.pricePerUnit;

  bool get _valid =>
      _qty > 0 && _qty <= widget.maxQuantity && _loc != null && _loc!.address.isNotEmpty;

  Future<void> _confirm() async {
    if (_qty <= 0) return _err('Enter a valid quantity');
    if (_qty > widget.maxQuantity)
      return _err('Only ${widget.maxQuantity.toStringAsFixed(0)} ${widget.unit} available');
    if (_loc == null || _loc!.address.isEmpty)
      return _err('Set a delivery location');

    final ok = await showDialog<bool>(context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Text('Place this order?',
            style: TextStyle(fontWeight: FontWeight.w800)),
        content: Column(mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _summaryLine(Icons.shopping_basket_rounded, widget.productLabel, _c2),
            const SizedBox(height: 8),
            _summaryLine(Icons.store_rounded, widget.supplierName, _sub),
            const SizedBox(height: 8),
            _summaryLine(Icons.scale_rounded,
                '${_qty.toStringAsFixed(0)} ${widget.unit}', _grn2),
            const SizedBox(height: 8),
            _summaryLine(Icons.location_on_rounded, _loc!.address, _amb2),
            const Divider(height: 24),
            Row(children: [
              const Text('Total', style: TextStyle(fontWeight: FontWeight.w700)),
              const Spacer(),
              Text('৳${_total.toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 18,
                      fontWeight: FontWeight.w900, color: _grn1)),
            ]),
            const SizedBox(height: 4),
            const Text('Cash on delivery',
                style: TextStyle(fontSize: 12, color: _sub)),
          ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
              child: const Text('Edit')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: _grn1, foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: const Text('Confirm', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
    if (ok != true) return;

    setState(() => _busy = true);
    final res = await OrderService.placeOrder(
      demandId:        widget.demandId,
      stockId:         widget.stockId,
      quantity:        _qty,
      deliveryAddress: _loc!.address,
      deliveryLat:     _loc!.lat != 0 ? _loc!.lat : null,
      deliveryLng:     _loc!.lng != 0 ? _loc!.lng : null,
    );
    if (!mounted) return;
    setState(() => _busy = false);

    if (res.ok) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: _grn1,
        content: Text('Order placed! ৳${res.total?.toStringAsFixed(0)} '
            '— waiting for supplier to accept.',
            style: const TextStyle(fontWeight: FontWeight.w600))));
      Navigator.pushAndRemoveUntil(context,
        MaterialPageRoute(builder: (_) => const MyOrdersScreen()),
        (route) => route.isFirst);
    } else {
      _err(res.error ?? 'Failed to place order');
    }
  }

  void _err(String msg) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(backgroundColor: const Color(0xFFC62828), content: Text(msg)));

  Widget _summaryLine(IconData icon, String text, Color c) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 15, color: c),
      const SizedBox(width: 8),
      Expanded(child: Text(text, style: TextStyle(fontSize: 13, color: _txt))),
    ],
  );

  // ════════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: SystemUiOverlayStyle.light,
    child: Scaffold(
      backgroundColor: _bg,
      body: FadeTransition(
        opacity: CurvedAnimation(parent: _fadeC, curve: Curves.easeOut),
        child: Column(children: [
          _header(),
          Expanded(child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // ── order summary ──────────────────────────────────────────────
              _summaryCard(),
              const SizedBox(height: 20),
              // ── quantity ───────────────────────────────────────────────────
              _sectionLabel('Quantity', Icons.scale_rounded, _c2),
              const SizedBox(height: 12),
              _quantityInput(),
              const SizedBox(height: 24),
              // ── delivery location ──────────────────────────────────────────
              _sectionLabel('Delivery Location', Icons.location_on_rounded, _c2),
              const SizedBox(height: 12),
              _locationCard(),
              const SizedBox(height: 24),
              // ── total ──────────────────────────────────────────────────────
              _totalCard(),
              const SizedBox(height: 32),
              // ── CTA ────────────────────────────────────────────────────────
              _placeBtn(),
            ]),
          )),
        ]),
      ),
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
        Positioned(top: 45,  left: -20,  child: _blob(80,  _c3, .18)),
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 20, 26),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
              const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Confirm Order', style: TextStyle(color: Colors.white,
                    fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -.4)),
                SizedBox(height: 2),
                Text('Review and place your order',
                    style: TextStyle(color: Colors.white54, fontSize: 12.5)),
              ])),
              // COD badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(.25)),
                ),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.payments_rounded, color: Colors.white, size: 13),
                  SizedBox(width: 5),
                  Text('Cash on Delivery', style: TextStyle(color: Colors.white,
                      fontSize: 11.5, fontWeight: FontWeight.w700)),
                ])),
            ]),
            const SizedBox(height: 20),
            // product row
            Row(children: [
              Container(width: 52, height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(.18),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(.3), width: 1.5),
                ),
                child: const Icon(Icons.shopping_basket_rounded,
                    color: Colors.white, size: 26)),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(widget.productLabel,
                    style: const TextStyle(color: Colors.white, fontSize: 17,
                        fontWeight: FontWeight.w900, letterSpacing: -.3),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 5),
                Row(children: [
                  const Icon(Icons.store_rounded, color: Colors.white54, size: 13),
                  const SizedBox(width: 5),
                  Flexible(child: Text('From ${widget.supplierName}',
                      style: TextStyle(color: Colors.white.withOpacity(.7), fontSize: 13),
                      maxLines: 1, overflow: TextOverflow.ellipsis)),
                ]),
              ])),
            ]),
          ]),
        ),
      ]),
    ),
  );

  // ── order summary card ────────────────────────────────────────────────────
  Widget _summaryCard() => Container(
    padding: const EdgeInsets.all(20),
    decoration: _cardDeco(),
    child: Column(children: [
      _infoRow(icon: Icons.store_rounded,      iconColor: _c2,
          label: 'Supplier',  value: widget.supplierName),
      _divider(),
      _infoRow(icon: Icons.sell_rounded,        iconColor: _amb1,
          label: 'Unit Price',
          value: '৳${widget.pricePerUnit.toStringAsFixed(0)} / ${widget.unit}',
          valueBold: true),
      _divider(),
      _infoRow(icon: Icons.inventory_2_rounded, iconColor: _grn2,
          label: 'Max Stock',
          value: '${widget.maxQuantity.toStringAsFixed(0)} ${widget.unit}'),
    ]),
  );

  // ── section label ─────────────────────────────────────────────────────────
  Widget _sectionLabel(String text, IconData icon, Color c) => Row(children: [
    Container(width: 32, height: 32,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [_c1, _c3],
            begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(9),
        boxShadow: [BoxShadow(color: _c2.withOpacity(.3),
            blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Icon(icon, color: Colors.white, size: 15)),
    const SizedBox(width: 10),
    Text(text, style: const TextStyle(fontSize: 15.5,
        fontWeight: FontWeight.w800, color: _txt, letterSpacing: -.2)),
  ]);

  // ── quantity input ────────────────────────────────────────────────────────
  Widget _quantityInput() => Container(
    decoration: _cardDeco(),
    padding: const EdgeInsets.fromLTRB(20, 8, 12, 8),
    child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
      Expanded(child: TextField(
        controller: _qtyCtrl,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900,
            color: _txt, letterSpacing: -1),
        decoration: InputDecoration(
          hintText: '0',
          hintStyle: const TextStyle(color: Color(0xFFCDD0E3), fontSize: 32,
              fontWeight: FontWeight.w900),
          border: InputBorder.none, enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none, contentPadding: EdgeInsets.zero,
          suffixText: widget.unit,
          suffixStyle: const TextStyle(fontSize: 16, color: _sub,
              fontWeight: FontWeight.w700),
        ),
      )),
      // max pill
      _Tap(onTap: () {
        _qtyCtrl.text = widget.maxQuantity.toStringAsFixed(0);
        setState(() {});
      }, child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [_c1, _c3]),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [BoxShadow(color: _c2.withOpacity(.3),
              blurRadius: 8, offset: const Offset(0, 3))],
        ),
        child: Text('Max\n${widget.maxQuantity.toStringAsFixed(0)}',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white,
                fontSize: 11, fontWeight: FontWeight.w800, height: 1.3)),
      )),
    ]),
  );

  // ── location card ─────────────────────────────────────────────────────────
  Widget _locationCard() => _Tap(onTap: _pickLocation,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: _loc != null ? _c2.withOpacity(.35) : const Color(0xFFE4E8F5),
          width: _loc != null ? 1.5 : 1),
        boxShadow: [
          BoxShadow(color: _c1.withOpacity(.08), blurRadius: 20, offset: const Offset(0, 6)),
          BoxShadow(color: Colors.black.withOpacity(.03), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(children: [
        // icon
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: 48, height: 48,
          decoration: BoxDecoration(
            gradient: LinearGradient(
                colors: _loc != null ? [_c1, _c2] : [const Color(0xFFE4E8F5), const Color(0xFFEEF0FA)],
                begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(14),
            boxShadow: _loc != null ? [BoxShadow(color: _c2.withOpacity(.35),
                blurRadius: 10, offset: const Offset(0, 4))] : null,
          ),
          child: Icon(Icons.location_on_rounded,
              color: _loc != null ? Colors.white : _sub, size: 22)),
        const SizedBox(width: 14),
        // text
        Expanded(child: _loc != null
            ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Delivery Address',
                    style: TextStyle(fontSize: 11.5, color: _sub,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(_loc!.address,
                    maxLines: 2, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13.5,
                        fontWeight: FontWeight.w700, color: _txt)),
                const SizedBox(height: 4),
                Text('Tap to change location',
                    style: TextStyle(fontSize: 11.5, color: _c2.withOpacity(.8),
                        fontWeight: FontWeight.w500)),
              ])
            : const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Set delivery location',
                    style: TextStyle(fontSize: 14,
                        fontWeight: FontWeight.w700, color: _txt)),
                SizedBox(height: 3),
                Text('Tap to pick on map',
                    style: TextStyle(fontSize: 12.5, color: _sub)),
              ])),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: _c2.withOpacity(.08), shape: BoxShape.circle),
          child: Icon(
              _loc != null ? Icons.edit_location_alt_rounded : Icons.add_location_alt_rounded,
              color: _c2, size: 20)),
      ]),
    ),
  );

  // ── total card ────────────────────────────────────────────────────────────
  Widget _totalCard() => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: LinearGradient(
          colors: [_grn1.withOpacity(.09), _grn2.withOpacity(.05)]),
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: _grn2.withOpacity(.25)),
    ),
    child: Row(children: [
      Container(width: 46, height: 46,
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [_grn1, _grn2],
              begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(13),
          boxShadow: [BoxShadow(color: _grn2.withOpacity(.38),
              blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: const Icon(Icons.payments_rounded, color: Colors.white, size: 22)),
      const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Order Total', style: TextStyle(color: _sub,
            fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 2),
        const Text('Cash on Delivery', style: TextStyle(color: _sub, fontSize: 11.5)),
      ])),
      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: _total),
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
          builder: (_, v, __) => Text('৳${v.toStringAsFixed(0)}',
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900,
                  color: _grn1, letterSpacing: -1)),
        ),
        Text('${_qty > 0 ? _qty.toStringAsFixed(0) : '0'} × '
            '৳${widget.pricePerUnit.toStringAsFixed(0)}',
            style: const TextStyle(fontSize: 12, color: _sub)),
      ]),
    ]),
  );

  // ── place order button ────────────────────────────────────────────────────
  Widget _placeBtn() => _Tap(
    onTap: (_busy || !_valid) ? () {} : _confirm,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: double.infinity, height: 58,
      decoration: BoxDecoration(
        gradient: _valid
            ? const LinearGradient(
                colors: [_grn1, Color(0xFF0A8F62), _grn2],
                stops: [0.0, 0.5, 1.0],
                begin: Alignment.topLeft, end: Alignment.bottomRight)
            : null,
        color: _valid ? null : const Color(0xFFDDE0F0),
        borderRadius: BorderRadius.circular(18),
        boxShadow: _valid ? [
          BoxShadow(color: _grn2.withOpacity(.45),
              blurRadius: 22, spreadRadius: -2, offset: const Offset(0, 10)),
        ] : null,
        border: Border.all(color: Colors.white.withOpacity(_valid ? .12 : 0)),
      ),
      child: Stack(children: [
        if (_valid)
          Positioned.fill(child: ClipRRect(borderRadius: BorderRadius.circular(18),
            child: Align(alignment: Alignment.topCenter,
              child: FractionallySizedBox(heightFactor: .45, widthFactor: 1,
                child: Container(decoration: BoxDecoration(
                  gradient: LinearGradient(begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.white.withOpacity(.2), Colors.transparent]))))))),
        Center(child: _busy
            ? const SizedBox(width: 22, height: 22,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
            : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.check_circle_rounded,
                    color: _valid ? Colors.white : _sub, size: 22),
                const SizedBox(width: 10),
                Text('Place Order',
                    style: TextStyle(
                        color: _valid ? Colors.white : _sub,
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

  Widget _infoRow({required IconData icon, required Color iconColor,
      required String label, required String value, bool valueBold = false}) =>
    Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        Container(width: 34, height: 34,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: iconColor, size: 17)),
        const SizedBox(width: 12),
        SizedBox(width: 80, child: Text(label, style: const TextStyle(
            fontSize: 13, color: _sub, fontWeight: FontWeight.w500))),
        Expanded(child: Text(value, style: TextStyle(fontSize: 14, color: _txt,
            fontWeight: valueBold ? FontWeight.w800 : FontWeight.w600))),
      ]),
    );

  Widget _divider() => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Divider(height: 1, color: Colors.grey.shade100),
  );

  Widget _blob(double sz, Color c, double op) =>
      Container(width: sz, height: sz,
          decoration: BoxDecoration(shape: BoxShape.circle, color: c.withOpacity(op)));
}
