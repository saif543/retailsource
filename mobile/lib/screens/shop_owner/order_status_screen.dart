import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/order_service.dart';
import '../../services/receipt_service.dart';
import 'rate_supplier_screen.dart';

// ── palette ───────────────────────────────────────────────────────────────────
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

// ─────────────────────────────────────────────────────────────────────────────
class OrderStatusScreen extends StatefulWidget {
  final Map<String, dynamic> order;
  const OrderStatusScreen({super.key, required this.order});
  @override State<OrderStatusScreen> createState() => _OSS();
}

class _OSS extends State<OrderStatusScreen> with SingleTickerProviderStateMixin {
  late Map<String, dynamic> _order;
  bool _loading = false;
  bool _generatingOtp = false;
  String? _otp;

  late final _fadeC = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 400));

  @override
  void initState() {
    super.initState();
    _order = Map<String, dynamic>.from(widget.order);
    _fadeC.forward();
    _load();
  }

  @override void dispose() { _fadeC.dispose(); super.dispose(); }

  Future<void> _load() async {
    final id = _order['order_id'] as int?;
    if (id == null) return;
    setState(() => _loading = true);
    final fresh = await OrderService.getOrderStatus(id);
    if (!mounted) return;
    setState(() {
      if (fresh != null) _order = fresh;
      _loading = false;
    });
  }

  Future<void> _generateOtp() async {
    final id = _order['order_id'] as int?;
    if (id == null) return;
    HapticFeedback.mediumImpact();
    setState(() => _generatingOtp = true);
    final r = await OrderService.generateOtp(id);
    if (!mounted) return;
    setState(() => _generatingOtp = false);
    if (r.ok) {
      setState(() => _otp = r.otp);
      HapticFeedback.heavyImpact();
    } else {
      _err(r.error ?? 'Failed to generate OTP');
    }
  }

  void _err(String msg) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(backgroundColor: _red1, content: Text(msg,
        style: const TextStyle(fontWeight: FontWeight.w600))));

  String _fmt(String? iso) {
    if (iso == null) return '';
    final dt = DateTime.tryParse(iso)?.toLocal();
    if (dt == null) return '';
    final h = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    return '$h:${dt.minute.toString().padLeft(2, '0')} ${dt.hour >= 12 ? 'PM' : 'AM'}';
  }

  List<Color> _statusGrad(String s) {
    switch (s) {
      case 'pending':          return [_amb1, _amb2];
      case 'accepted':         return [_c1,   _c2];
      case 'out_for_delivery': return [_pur1, _pur2];
      case 'delivered':        return [_grn1, _grn2];
      default:                 return [_c1,   _c2];
    }
  }

  IconData _statusIcon(String s) {
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

  // ════════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final status     = (_order['status'] as String?) ?? 'pending';
    final grad       = _statusGrad(status);
    final delivered  = status == 'delivered';
    final onWay      = status == 'out_for_delivery';
    final accepted   = ['accepted', 'out_for_delivery', 'delivered'].contains(status);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _bg,
        body: FadeTransition(
          opacity: CurvedAnimation(parent: _fadeC, curve: Curves.easeOut),
          child: Column(children: [
            _header(status, grad),
            Expanded(child: RefreshIndicator(
              onRefresh: _load, color: _c2,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
                child: Column(children: [
                  // delivered banner
                  if (delivered) ...[_deliveredBanner(), const SizedBox(height: 20)],
                  // OTP card
                  if (onWay) ...[_otpCard(), const SizedBox(height: 20)],
                  // accepted info
                  if (status == 'accepted') ...[_acceptedInfo(), const SizedBox(height: 20)],
                  // timeline
                  _timeline(status),
                  const SizedBox(height: 20),
                  // order details
                  _detailsCard(),
                  const SizedBox(height: 20),
                  // supplier
                  _supplierCard(),
                  if (delivered) ...[
                    const SizedBox(height: 24),
                    _rateBtn(),
                    const SizedBox(height: 12),
                    _receiptBtn(),
                    const SizedBox(height: 12),
                    _backBtn(),
                  ],
                ]),
              ),
            )),
          ]),
        ),
      ),
    );
  }

  // ── gradient header ───────────────────────────────────────────────────────
  Widget _header(String status, List<Color> grad) {
    final product = _order['product'] as String?
        ?? '${_order['product_name'] ?? ''} - ${_order['variant_name'] ?? ''}';
    final orderId = _order['order_id'] ?? _order['id'] ?? '';

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: [_c0, _c1, grad[0], grad[1]],
            stops: const [0.0, 0.3, 0.68, 1.0],
            begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(32), bottomRight: Radius.circular(32)),
      ),
      child: SafeArea(bottom: false,
        child: Stack(children: [
          Positioned(top: -20, right: -30, child: _blob(130, Colors.white, .04)),
          Positioned(top: 8,   right: 50,  child: _blob(44,  _c2, .3)),
          Positioned(top: 50,  left: -20,  child: _blob(80,  _c3, .15)),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 20, 26),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // top bar
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
                  const Text('Order Status', style: TextStyle(color: Colors.white,
                      fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -.4)),
                  Text('Order #$orderId',
                      style: const TextStyle(color: Colors.white54, fontSize: 12.5)),
                ])),
                // refresh btn
                ClipRRect(borderRadius: BorderRadius.circular(12),
                  child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                    child: _Tap(onTap: _load,
                      child: Container(width: 42, height: 42,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.14),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withOpacity(0.25)),
                        ),
                        child: _loading
                            ? const Padding(
                                padding: EdgeInsets.all(11),
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.refresh_rounded,
                                color: Colors.white, size: 19)),
                    ),
                  ),
                ),
              ]),
              const SizedBox(height: 20),
              // status row
              Row(children: [
                Container(width: 52, height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(.18),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(.3), width: 1.5),
                  ),
                  child: Icon(_statusIcon(status), color: Colors.white, size: 26)),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(product,
                      style: const TextStyle(color: Colors.white, fontSize: 16,
                          fontWeight: FontWeight.w900, letterSpacing: -.3),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(.18),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(.25)),
                    ),
                    child: Text(_statusLabel(status),
                        style: const TextStyle(color: Colors.white,
                            fontSize: 12, fontWeight: FontWeight.w800))),
                ])),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }

  // ── delivered banner ──────────────────────────────────────────────────────
  Widget _deliveredBanner() => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      gradient: LinearGradient(
          colors: [_grn1.withOpacity(.12), _grn2.withOpacity(.06)]),
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: _grn2.withOpacity(.3)),
    ),
    child: Row(children: [
      Container(width: 52, height: 52,
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [_grn1, _grn2],
              begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(15),
          boxShadow: [BoxShadow(color: _grn2.withOpacity(.4),
              blurRadius: 14, offset: const Offset(0, 5))],
        ),
        child: const Icon(Icons.check_circle_rounded, color: Colors.white, size: 28)),
      const SizedBox(width: 14),
      const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Delivered Successfully!', style: TextStyle(fontSize: 15,
            fontWeight: FontWeight.w900, color: _grn1, letterSpacing: -.2)),
        SizedBox(height: 3),
        Text('Your order has arrived. Rate your supplier below.',
            style: TextStyle(color: _sub, fontSize: 12.5)),
      ])),
    ]),
  );

  // ── OTP card ──────────────────────────────────────────────────────────────
  Widget _otpCard() => Container(
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
          colors: [_c0, _pur1, _pur2],
          stops: [0.0, 0.45, 1.0],
          begin: Alignment.topLeft, end: Alignment.bottomRight),
      borderRadius: BorderRadius.circular(24),
      boxShadow: [BoxShadow(color: _pur2.withOpacity(.35),
          blurRadius: 20, offset: const Offset(0, 8))],
    ),
    child: Column(children: [
      // header row
      Row(children: [
        Container(width: 44, height: 44,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(.18),
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: Colors.white.withOpacity(.25)),
          ),
          child: const Icon(Icons.vpn_key_rounded, color: Colors.white, size: 22)),
        const SizedBox(width: 12),
        const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Delivery OTP', style: TextStyle(color: Colors.white,
              fontSize: 16, fontWeight: FontWeight.w900)),
          SizedBox(height: 2),
          Text('Share this code with the delivery person',
              style: TextStyle(color: Colors.white60, fontSize: 12)),
        ])),
      ]),
      const SizedBox(height: 22),

      if (_otp != null && _otp!.length == 6) ...[
        // OTP digit boxes
        Row(mainAxisAlignment: MainAxisAlignment.center, children: _otp!
            .split('')
            .asMap()
            .entries
            .map((e) => TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: Duration(milliseconds: 200 + e.key * 60),
              curve: Curves.elasticOut,
              builder: (_, v, __) => Transform.scale(scale: v,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: 44, height: 58,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [BoxShadow(color: _pur2.withOpacity(.4),
                        blurRadius: 12, offset: const Offset(0, 4))],
                  ),
                  child: Text(e.value,
                      style: const TextStyle(fontSize: 24,
                          fontWeight: FontWeight.w900, color: _pur1))),
              ),
            ))
            .toList()),
        const SizedBox(height: 12),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.access_time_rounded, color: Colors.white54, size: 13),
          const SizedBox(width: 5),
          const Text('Valid for 10 minutes',
              style: TextStyle(color: Colors.white54, fontSize: 12)),
        ]),
        const SizedBox(height: 16),
        _Tap(onTap: _generatingOtp ? () {} : _generateOtp,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.15),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(.25)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.refresh_rounded, color: Colors.white70, size: 16),
              const SizedBox(width: 7),
              const Text('Generate New Code',
                  style: TextStyle(color: Colors.white70,
                      fontSize: 13, fontWeight: FontWeight.w700)),
            ]),
          ),
        ),
      ] else ...[
        // Generate button
        _Tap(onTap: _generatingOtp ? () {} : _generateOtp,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: _pur2.withOpacity(.3),
                  blurRadius: 14, offset: const Offset(0, 5))],
            ),
            child: _generatingOtp
                ? const Center(child: SizedBox(width: 22, height: 22,
                    child: CircularProgressIndicator(color: _pur1, strokeWidth: 2.5)))
                : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.pin_outlined, color: _pur1, size: 20),
                    const SizedBox(width: 10),
                    const Text('Generate OTP', style: TextStyle(color: _pur1,
                        fontSize: 15, fontWeight: FontWeight.w900)),
                  ]),
          ),
        ),
        const SizedBox(height: 12),
        const Text('Tap to generate a one-time delivery code',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white60, fontSize: 12)),
      ],
    ]),
  );

  // ── accepted info ─────────────────────────────────────────────────────────
  Widget _acceptedInfo() => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: _c2.withOpacity(.2)),
      boxShadow: [BoxShadow(color: _c1.withOpacity(.08),
          blurRadius: 20, offset: const Offset(0, 6))],
    ),
    child: Row(children: [
      Container(width: 46, height: 46,
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [_c1, _c2],
              begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(13),
          boxShadow: [BoxShadow(color: _c2.withOpacity(.35),
              blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: const Icon(Icons.inventory_2_rounded, color: Colors.white, size: 22)),
      const SizedBox(width: 14),
      const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Order Accepted', style: TextStyle(fontSize: 14,
            fontWeight: FontWeight.w800, color: _c1)),
        SizedBox(height: 3),
        Text('Supplier is preparing your order for dispatch. '
            'You will be notified when it is on the way.',
            style: TextStyle(color: _sub, fontSize: 12.5)),
      ])),
    ]),
  );

  // ── timeline ──────────────────────────────────────────────────────────────
  Widget _timeline(String status) {
    final accepted      = ['accepted', 'out_for_delivery', 'delivered'].contains(status);
    final outForDeliv   = ['out_for_delivery', 'delivered'].contains(status);
    final delivered     = status == 'delivered';

    final steps = [
      _StepData('Order Placed',    _fmt(_order['created_at'] as String?), true,
          Icons.receipt_long_rounded, [_c1, _c2]),
      _StepData('Order Accepted',  accepted
          ? _fmt(_order['accepted_at'] as String?) : 'Waiting for supplier',
          accepted, Icons.check_circle_outline_rounded, [_c1, _c2]),
      _StepData('Out for Delivery', outForDeliv ? 'On the way' : 'Pending',
          outForDeliv, Icons.local_shipping_rounded, [_pur1, _pur2]),
      _StepData('Delivered',       delivered
          ? _fmt(_order['delivered_at'] as String?) : 'Pending',
          delivered, Icons.check_circle_rounded, [_grn1, _grn2]),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(color: _c1.withOpacity(.08), blurRadius: 20, offset: const Offset(0, 6)),
          BoxShadow(color: Colors.black.withOpacity(.03), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Delivery Progress', style: TextStyle(fontSize: 15,
            fontWeight: FontWeight.w900, color: _txt, letterSpacing: -.2)),
        const SizedBox(height: 18),
        ...steps.asMap().entries.map((e) =>
            _timelineStep(e.value, isLast: e.key == steps.length - 1)),
      ]),
    );
  }

  Widget _timelineStep(_StepData s, {required bool isLast}) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // dot + line column
      SizedBox(width: 30, child: Column(children: [
        Container(width: 30, height: 30,
          decoration: BoxDecoration(
            gradient: s.done
                ? LinearGradient(colors: s.grad,
                    begin: Alignment.topLeft, end: Alignment.bottomRight)
                : null,
            color: s.done ? null : const Color(0xFFEEF0F8),
            shape: BoxShape.circle,
            boxShadow: s.done ? [BoxShadow(color: s.grad.last.withOpacity(.4),
                blurRadius: 8, offset: const Offset(0, 3))] : null,
          ),
          child: Icon(s.icon,
              color: s.done ? Colors.white : Colors.grey.shade400, size: 14)),
        if (!isLast)
          Container(width: 2, height: 36,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                    begin: Alignment.topCenter, end: Alignment.bottomCenter,
                    colors: s.done
                        ? [s.grad.last, s.grad.last.withOpacity(.2)]
                        : [Colors.grey.shade200, Colors.grey.shade200]),
                borderRadius: BorderRadius.circular(2))),
      ])),
      const SizedBox(width: 14),
      Padding(
        padding: EdgeInsets.only(top: 5, bottom: isLast ? 0 : 36),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(s.label, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800,
              color: s.done ? _txt : _sub)),
          const SizedBox(height: 2),
          Text(s.time, style: TextStyle(fontSize: 12,
              color: s.done ? _sub : Colors.grey.shade400)),
        ]),
      ),
    ],
  );

  // ── order details card ────────────────────────────────────────────────────
  Widget _detailsCard() {
    final price = (_order['price'] as num?)?.toDouble()
        ?? (_order['total_price'] as num?)?.toDouble() ?? 0.0;
    final qty = _order['qty'] as String?
        ?? '${(_order['quantity'] as num?)?.toStringAsFixed(0) ?? ''} ${_order['unit'] ?? ''}';
    final pricePerUnit = (_order['price_per_unit'] as num?)?.toDouble();
    final unit = _order['unit'] as String? ?? '';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDeco(),
      child: Column(children: [
        _infoRow(Icons.scale_rounded,      _c2,   'Quantity',   qty),
        _divider(),
        _infoRow(Icons.payments_rounded,   _grn1, 'Total',     '৳${price.toStringAsFixed(0)}',
            valueBold: true),
        if (pricePerUnit != null) ...[
          _divider(),
          _infoRow(Icons.sell_rounded,     _amb1, 'Per $unit',
              '৳${pricePerUnit.toStringAsFixed(0)} / $unit'),
        ],
        if ((_order['delivery_address'] as String?)?.isNotEmpty == true) ...[
          _divider(),
          _infoRow(Icons.location_on_rounded, _red2, 'Delivery',
              _order['delivery_address'] as String),
        ],
      ]),
    );
  }

  // ── supplier card ─────────────────────────────────────────────────────────
  Widget _supplierCard() {
    final name = _order['supplier'] as String?
        ?? _order['stockholder_name'] as String? ?? '';
    final initials = name.isNotEmpty
        ? name.trim().split(' ').map((s) => s[0]).take(2).join().toUpperCase()
        : '?';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDeco(),
      child: Row(children: [
        Container(width: 52, height: 52,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [_c1, _c3],
                begin: Alignment.topLeft, end: Alignment.bottomRight),
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: _c2.withOpacity(.3),
                blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Center(child: Text(initials,
              style: const TextStyle(color: Colors.white,
                  fontSize: 16, fontWeight: FontWeight.w900)))),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Supplier', style: TextStyle(fontSize: 11.5,
              color: _sub, fontWeight: FontWeight.w600)),
          const SizedBox(height: 3),
          Text(name.isNotEmpty ? name : 'Loading...',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: _txt)),
        ])),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [_grn1, _grn2]),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Text('Verified', style: TextStyle(color: Colors.white,
              fontSize: 11, fontWeight: FontWeight.w800))),
      ]),
    );
  }

  // ── rate supplier button ──────────────────────────────────────────────────
  Widget _rateBtn() => _Tap(
    onTap: () => Navigator.push(context,
        MaterialPageRoute(builder: (_) => RateSupplierScreen(order: _order))),
    child: Container(
      width: double.infinity, height: 58,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [Color(0xFF7C1A00), Color(0xFFD03800),
                     Color(0xFFF06000), Color(0xFFFF9500)],
            stops: [0.0, 0.32, 0.68, 1.0],
            begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: const Color(0xFFF06000).withOpacity(.45),
            blurRadius: 22, spreadRadius: -2, offset: const Offset(0, 10))],
      ),
      child: Stack(children: [
        Positioned.fill(child: ClipRRect(borderRadius: BorderRadius.circular(18),
          child: Align(alignment: Alignment.topCenter,
            child: FractionallySizedBox(heightFactor: .45, widthFactor: 1,
              child: Container(decoration: BoxDecoration(
                gradient: LinearGradient(begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.white.withOpacity(.2), Colors.transparent]))))))),
        const Center(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.star_rounded, color: Colors.white, size: 22),
          SizedBox(width: 10),
          Text('Rate this Supplier', style: TextStyle(color: Colors.white,
              fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: .2)),
        ])),
      ]),
    ),
  );

  Widget _receiptBtn() => _Tap(
    onTap: () => ReceiptService.downloadReceipt(_order),
    child: Container(
      width: double.infinity, height: 52,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _grn1.withOpacity(.4), width: 1.5),
        boxShadow: [BoxShadow(color: _grn1.withOpacity(.08),
            blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: const Center(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.download_rounded, color: _grn1, size: 20),
        SizedBox(width: 10),
        Text('Download Receipt', style: TextStyle(color: _grn1,
            fontSize: 15, fontWeight: FontWeight.w800)),
      ])),
    ),
  );

  Widget _backBtn() => _Tap(
    onTap: () => Navigator.pop(context),
    child: Container(
      width: double.infinity, height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _c2.withOpacity(.3)),
        boxShadow: [BoxShadow(color: _c1.withOpacity(.05),
            blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: const Center(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.arrow_back_rounded, color: _c2, size: 18),
        SizedBox(width: 8),
        Text('Back to My Orders', style: TextStyle(color: _c2,
            fontSize: 14, fontWeight: FontWeight.w800)),
      ])),
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

  Widget _infoRow(IconData icon, Color c, String label, String value,
      {bool valueBold = false}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(children: [
      Container(width: 34, height: 34,
        decoration: BoxDecoration(
            color: c.withOpacity(.1), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: c, size: 16)),
      const SizedBox(width: 12),
      SizedBox(width: 80, child: Text(label, style: const TextStyle(
          fontSize: 13, color: _sub, fontWeight: FontWeight.w500))),
      Expanded(child: Text(value, style: TextStyle(fontSize: 14, color: _txt,
          fontWeight: valueBold ? FontWeight.w800 : FontWeight.w600),
          maxLines: 2, overflow: TextOverflow.ellipsis)),
    ]),
  );

  Widget _divider() => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Divider(height: 1, color: Colors.grey.shade100),
  );

  Widget _blob(double sz, Color c, double op) =>
      Container(width: sz, height: sz,
          decoration: BoxDecoration(shape: BoxShape.circle, color: c.withOpacity(op)));
}

class _StepData {
  final String label, time;
  final bool done;
  final IconData icon;
  final List<Color> grad;
  const _StepData(this.label, this.time, this.done, this.icon, this.grad);
}
