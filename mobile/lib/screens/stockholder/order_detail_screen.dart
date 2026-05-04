import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/order_service.dart';
import '../../services/receipt_service.dart';

const _sg0 = Color(0xFF012B1E);
const _sg1 = Color(0xFF054F3A);
const _sg2 = Color(0xFF0A7A56);
const _sg3 = Color(0xFF0FBB84);
const _bg  = Color(0xFFF0FBF6);
const _txt = Color(0xFF212121);
const _sub = Color(0xFF757575);
const _red1 = Color(0xFF7B1C1C);
const _red2 = Color(0xFFEF5350);
const _amb1 = Color(0xFFAD4A0A);
const _amb2 = Color(0xFFF5981E);
const _ind1 = Color(0xFF2D238A);
const _ind2 = Color(0xFF7C6FF5);

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
class StockholderOrderDetailScreen extends StatefulWidget {
  final Map<String, dynamic> order;
  const StockholderOrderDetailScreen({super.key, required this.order});
  @override State<StockholderOrderDetailScreen> createState() => _SODS();
}

class _SODS extends State<StockholderOrderDetailScreen> {
  late String _status;
  late Map<String, dynamic> _order;
  bool _loading = false;

  final List<TextEditingController> _otpCtrl =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocus = List.generate(6, (_) => FocusNode());
  bool _otpVerifying = false;
  String _otpError = '';

  @override
  void initState() {
    super.initState();
    _order = Map<String, dynamic>.from(widget.order);
    _status = (_order['status'] as String?) ?? 'pending';
  }

  @override
  void dispose() {
    for (final c in _otpCtrl) c.dispose();
    for (final f in _otpFocus) f.dispose();
    super.dispose();
  }

  Future<void> _loadFresh() async {
    final orderId = _order['order_id'] as int?;
    if (orderId == null) return;
    final fresh = await OrderService.getOrderStatus(orderId);
    if (!mounted || fresh == null) return;
    setState(() {
      _order = {
        ..._order,
        'delivery_address': fresh['delivery_address'],
        'shop_owner_phone': fresh['shop_owner_phone'],
        'shop': fresh['shop_owner_name'] ?? _order['shop'],
        'shopName': fresh['shop_name'] ?? _order['shopName'],
        'area': fresh['shop_area'] ?? _order['area'],
        'accepted_at': fresh['accepted_at'],
        'delivered_at': fresh['delivered_at'],
        'status': fresh['status'] ?? _status,
      };
      _status = fresh['status'] as String? ?? _status;
      _loading = false;
    });
  }

  Future<void> _acceptOrder() async {
    final orderId = _order['order_id'] as int?;
    if (orderId == null) return;
    HapticFeedback.mediumImpact();
    setState(() => _loading = true);
    final result = await OrderService.acceptOrder(orderId);
    if (!mounted) return;
    if (result.ok) {
      await _loadFresh();
      if (!mounted) return;
      setState(() => _status = 'accepted');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: _sg1,
        content: const Text('Order accepted! Buyer info is now visible.',
            style: TextStyle(fontWeight: FontWeight.w600))));
    } else {
      setState(() => _loading = false);
      _err(result.error ?? 'Failed to accept');
    }
  }

  Future<void> _declineOrder() async {
    HapticFeedback.mediumImpact();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 56, height: 56,
            decoration: BoxDecoration(color: _red2.withOpacity(.1), shape: BoxShape.circle),
            child: const Icon(Icons.close_rounded, color: _red2, size: 28)),
          const SizedBox(height: 16),
          const Text('Decline Order?', style: TextStyle(
              fontSize: 18, fontWeight: FontWeight.w900, color: _txt)),
          const SizedBox(height: 8),
          const Text('The shop owner will be notified. This cannot be undone.',
              textAlign: TextAlign.center,
              style: TextStyle(color: _sub, fontSize: 13)),
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
                child: const Center(child: Text('Decline',
                    style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white)))))),
          ]),
        ])),
      ),
    );
    if (confirm != true || !mounted) return;
    final orderId = _order['order_id'] as int?;
    if (orderId != null) await OrderService.declineOrder(orderId);
    if (mounted) Navigator.pop(context, 'declined');
  }

  Future<void> _markOutForDelivery() async {
    final orderId = _order['order_id'] as int?;
    if (orderId == null) return;
    HapticFeedback.mediumImpact();
    setState(() => _loading = true);
    final result = await OrderService.markDelivered(orderId);
    if (!mounted) return;
    setState(() => _loading = false);
    if (result.ok) {
      setState(() => _status = 'out_for_delivery');
    } else {
      _err(result.error ?? 'Failed');
    }
  }

  Future<void> _verifyOtp() async {
    final code = _otpCtrl.map((c) => c.text.trim()).join();
    if (code.length != 6) {
      setState(() => _otpError = 'Enter all 6 digits');
      return;
    }
    final orderId = _order['order_id'] as int?;
    if (orderId == null) return;
    HapticFeedback.mediumImpact();
    setState(() { _otpVerifying = true; _otpError = ''; });
    final result = await OrderService.verifyOtp(orderId, code);
    if (!mounted) return;
    setState(() => _otpVerifying = false);
    if (result.ok) {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          child: Padding(padding: const EdgeInsets.all(28), child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 76, height: 76,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [_sg1, _sg3],
                    begin: Alignment.topLeft, end: Alignment.bottomRight),
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: _sg3.withOpacity(.4),
                    blurRadius: 20, offset: const Offset(0, 6))],
              ),
              child: const Icon(Icons.check_rounded, color: Colors.white, size: 40)),
            const SizedBox(height: 18),
            const Text('Delivery Confirmed!', style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.w900, color: _txt)),
            const SizedBox(height: 8),
            const Text('Order successfully delivered. Great job!',
                textAlign: TextAlign.center,
                style: TextStyle(color: _sub, fontSize: 13.5)),
            const SizedBox(height: 24),
            _Tap(onTap: () => Navigator.pop(context),
              child: Container(width: double.infinity, height: 50,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [_sg1, _sg3]),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: _sg3.withOpacity(.4),
                      blurRadius: 14, offset: const Offset(0, 6))],
                ),
                child: const Center(child: Text('Done',
                    style: TextStyle(color: Colors.white,
                        fontSize: 16, fontWeight: FontWeight.w900))))),
          ])),
        ),
      );
      if (mounted) Navigator.pop(context, 'delivered');
    } else {
      setState(() => _otpError = result.error ?? 'Invalid OTP');
    }
  }

  void _err(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: _red1,
      content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600))));

  List<Color> get _statusGrad {
    switch (_status) {
      case 'pending': return const [_amb1, _amb2];
      case 'accepted': return const [_sg1, _sg3];
      case 'out_for_delivery': return const [_ind1, _ind2];
      default: return const [Color(0xFF1A5C3A), Color(0xFF2ECC71)];
    }
  }

  String get _statusLabel {
    switch (_status) {
      case 'pending': return 'NEW ORDER REQUEST';
      case 'accepted': return 'ORDER ACCEPTED';
      case 'out_for_delivery': return 'OUT FOR DELIVERY';
      default: return 'DELIVERED';
    }
  }

  double _unitPrice() {
    final total = (_order['price'] as num?)?.toDouble() ?? 0;
    final qty = (_order['quantity'] as num?)?.toDouble() ?? 1;
    return qty > 0 ? total / qty : 0;
  }

  String _fmt(String? iso) {
    if (iso == null) return '';
    final dt = DateTime.tryParse(iso)?.toLocal();
    if (dt == null) return '';
    final h = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '$h:${dt.minute.toString().padLeft(2, '0')} $ampm';
  }

  @override
  Widget build(BuildContext context) {
    final buyerVisible = ['accepted', 'out_for_delivery', 'delivered'].contains(_status);
    final deliveryAddress = (_order['delivery_address'] as String?) ?? '';
    final phone = (_order['shop_owner_phone'] as String?) ?? '';
    final shopName = (_order['shopName'] as String?) ?? '';
    final ownerName = (_order['shop'] as String?) ?? '';
    final product = (_order['product'] as String?) ?? '';
    final qty = (_order['qty'] as String?) ?? '';
    final price = (_order['price'] as num?)?.toDouble() ?? 0.0;
    final createdAt = _order['created_at'] as String?;
    final acceptedAt = _order['accepted_at'] as String?;

    final stepAccepted = ['accepted', 'out_for_delivery', 'delivered'].contains(_status);
    final stepOnWay = ['out_for_delivery', 'delivered'].contains(_status);
    final stepDelivered = _status == 'delivered';

    return Scaffold(
      backgroundColor: _bg,
      body: Column(children: [
        _buildHeader(),
        Expanded(child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

            // Product details card
            _card(
              icon: Icons.shopping_bag_outlined,
              title: 'Product Details',
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(product, style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w900, color: _txt)),
                const Divider(height: 18),
                Row(children: [
                  Expanded(child: _kv('Quantity', qty)),
                  Expanded(child: _kv('Unit Price',
                      '৳${_unitPrice().toStringAsFixed(2)}/${_order['unit'] ?? ''}')),
                ]),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [_sg1, _sg3]),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(children: [
                    const Text('Total Order Value', style: TextStyle(
                        color: Colors.white70, fontSize: 13)),
                    const Spacer(),
                    Text('৳${price.toStringAsFixed(0)}', style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20)),
                  ]),
                ),
              ]),
            ),
            const SizedBox(height: 14),

            // Buyer info
            _card(
              icon: Icons.store_rounded,
              title: 'Buyer Information',
              child: buyerVisible
                  ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Container(width: 44, height: 44,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [_sg1, _sg3]),
                            shape: BoxShape.circle,
                          ),
                          child: Center(child: Text(
                            shopName.isNotEmpty ? shopName[0].toUpperCase() : 'S',
                            style: const TextStyle(color: Colors.white,
                                fontWeight: FontWeight.w900, fontSize: 18)))),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(shopName, style: const TextStyle(
                              fontWeight: FontWeight.w900, fontSize: 15, color: _txt)),
                          Text('Owner: $ownerName',
                              style: const TextStyle(color: _sub, fontSize: 12.5)),
                        ])),
                      ]),
                      if (deliveryAddress.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _infoRow(Icons.place_outlined, 'Delivery Address', deliveryAddress),
                      ],
                      if (phone.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        _infoRow(Icons.phone_outlined, 'Contact', phone),
                      ],
                    ])
                  : Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: _amb2.withOpacity(.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: _amb2.withOpacity(.3)),
                      ),
                      child: const Row(children: [
                        Icon(Icons.lock_outline, color: _amb1, size: 18),
                        SizedBox(width: 10),
                        Expanded(child: Text(
                            'Buyer info revealed after you accept the order',
                            style: TextStyle(color: _amb1, fontWeight: FontWeight.w600))),
                      ])),
            ),
            const SizedBox(height: 14),

            // OTP input — shown when out_for_delivery
            if (_status == 'out_for_delivery') ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _ind2.withOpacity(.4)),
                  boxShadow: [BoxShadow(color: _ind2.withOpacity(.15),
                      blurRadius: 16, offset: const Offset(0, 4))],
                ),
                child: Column(children: [
                  Container(width: 56, height: 56,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [_ind1, _ind2],
                          begin: Alignment.topLeft, end: Alignment.bottomRight),
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: _ind2.withOpacity(.4),
                          blurRadius: 14, offset: const Offset(0, 4))],
                    ),
                    child: const Icon(Icons.vpn_key_rounded, color: Colors.white, size: 26)),
                  const SizedBox(height: 14),
                  const Text('Enter OTP from Shop Owner', style: TextStyle(
                      fontWeight: FontWeight.w900, fontSize: 16, color: _txt)),
                  const SizedBox(height: 6),
                  const Text('Ask the shop owner for the 6-digit code to confirm delivery',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: _sub, fontSize: 12.5)),
                  const SizedBox(height: 20),
                  Row(mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(6, _otpBox)),
                  if (_otpError.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: _red2.withOpacity(.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(_otpError, style: const TextStyle(
                          color: _red2, fontSize: 13, fontWeight: FontWeight.w600))),
                  ],
                  const SizedBox(height: 18),
                  _Tap(onTap: _otpVerifying ? () {} : _verifyOtp,
                    child: Container(width: double.infinity, height: 50,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [_ind1, _ind2]),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [BoxShadow(color: _ind2.withOpacity(.35),
                            blurRadius: 14, offset: const Offset(0, 6))],
                      ),
                      child: Center(child: _otpVerifying
                          ? const SizedBox(width: 22, height: 22,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                          : const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                              Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                              SizedBox(width: 8),
                              Text('Confirm Delivery', style: TextStyle(color: Colors.white,
                                  fontSize: 15, fontWeight: FontWeight.w900)),
                            ])))),
                ]),
              ),
              const SizedBox(height: 14),
            ],

            // Timeline
            _card(
              icon: Icons.local_shipping_outlined,
              title: 'Delivery Progress',
              child: Column(children: [
                _step('Order Placed', _fmt(createdAt).isEmpty ? 'Just now' : _fmt(createdAt), true,
                    grad: const [_sg1, _sg3]),
                _step('Order Accepted', stepAccepted
                    ? (_fmt(acceptedAt).isEmpty ? 'Done' : _fmt(acceptedAt)) : 'Pending',
                    stepAccepted, grad: const [_sg1, _sg3], current: _status == 'accepted'),
                _step('Out for Delivery', stepOnWay ? 'On the way' : 'Pending',
                    stepOnWay, grad: const [_ind1, _ind2], current: _status == 'out_for_delivery'),
                _step('Delivered', stepDelivered ? 'Complete' : 'Pending',
                    stepDelivered, grad: const [Color(0xFF1A5C3A), Color(0xFF2ECC71)]),
              ]),
            ),
            const SizedBox(height: 20),

            // Action buttons
            if (_status == 'pending') ...[
              Row(children: [
                Expanded(child: _Tap(onTap: _loading ? () {} : _acceptOrder,
                  child: Container(height: 52,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [_sg1, _sg3]),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: _sg3.withOpacity(.35),
                          blurRadius: 14, offset: const Offset(0, 6))],
                    ),
                    child: Center(child: _loading
                        ? const SizedBox(width: 22, height: 22,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                        : const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Icon(Icons.check_rounded, color: Colors.white, size: 18),
                            SizedBox(width: 8),
                            Text('Accept Order', style: TextStyle(color: Colors.white,
                                fontSize: 15, fontWeight: FontWeight.w900)),
                          ]))))),
                const SizedBox(width: 10),
                Expanded(child: _Tap(onTap: _loading ? () {} : _declineOrder,
                  child: Container(height: 52,
                    decoration: BoxDecoration(
                      border: Border.all(color: _red2.withOpacity(.6), width: 1.5),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Center(child: Row(
                        mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.close_rounded, color: _red2, size: 18),
                      SizedBox(width: 8),
                      Text('Decline', style: TextStyle(color: _red2,
                          fontSize: 15, fontWeight: FontWeight.w800)),
                    ]))))),
              ]),
            ] else if (_status == 'accepted') ...[
              _Tap(onTap: _loading ? () {} : _markOutForDelivery,
                child: Container(width: double.infinity, height: 52,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [_ind1, _ind2]),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: _ind2.withOpacity(.35),
                        blurRadius: 14, offset: const Offset(0, 6))],
                  ),
                  child: Center(child: _loading
                      ? const SizedBox(width: 22, height: 22,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                      : const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Icon(Icons.local_shipping_rounded, color: Colors.white, size: 20),
                          SizedBox(width: 10),
                          Text('Mark Out for Delivery', style: TextStyle(color: Colors.white,
                              fontSize: 15, fontWeight: FontWeight.w900)),
                        ])))),
            ] else if (_status == 'delivered') ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    const Color(0xFF1A5C3A).withOpacity(.1),
                    const Color(0xFF2ECC71).withOpacity(.1)]),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _sg3.withOpacity(.4)),
                ),
                child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.check_circle_rounded, color: _sg2, size: 24),
                  SizedBox(width: 10),
                  Text('Order Delivered Successfully',
                      style: TextStyle(color: _sg1,
                          fontWeight: FontWeight.w900, fontSize: 15)),
                ]),
              ),
              const SizedBox(height: 12),
              _Tap(
                onTap: () => ReceiptService.downloadReceipt(_order),
                child: Container(
                  width: double.infinity, height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _sg1.withOpacity(.4), width: 1.5),
                    boxShadow: [BoxShadow(color: _sg1.withOpacity(.08),
                        blurRadius: 12, offset: const Offset(0, 4))],
                  ),
                  child: const Center(child: Row(
                      mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.download_rounded, color: _sg1, size: 20),
                    SizedBox(width: 10),
                    Text('Download Receipt', style: TextStyle(color: _sg1,
                        fontSize: 15, fontWeight: FontWeight.w800)),
                  ])),
                ),
              ),
            ],
          ]),
        )),
      ]),
    );
  }

  Widget _buildHeader() => Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [_statusGrad[0], _statusGrad[0], _statusGrad[1]],
        begin: Alignment.topLeft, end: Alignment.bottomRight,
      ),
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(28), bottomRight: Radius.circular(28)),
    ),
    child: SafeArea(bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 20, 20),
        child: Row(children: [
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
            Text(_status == 'pending' ? 'New Order Request' : 'Order Details',
                style: const TextStyle(color: Colors.white,
                    fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -.4)),
            const SizedBox(height: 2),
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(_statusLabel, style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w800, fontSize: 11))),
            ]),
          ])),
          if (_loading)
            const SizedBox(width: 22, height: 22,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)),
        ]),
      ),
    ),
  );

  Widget _otpBox(int index) => Container(
    width: 44, height: 52,
    margin: const EdgeInsets.symmetric(horizontal: 3),
    child: TextField(
      controller: _otpCtrl[index],
      focusNode: _otpFocus[index],
      textAlign: TextAlign.center,
      keyboardType: TextInputType.number,
      maxLength: 1,
      buildCounter: (_, {required currentLength, required isFocused, maxLength}) => null,
      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: _txt),
      decoration: InputDecoration(
        filled: true, fillColor: _bg,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: _ind2.withOpacity(.3))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: _ind2.withOpacity(.3))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _ind2, width: 2)),
        contentPadding: EdgeInsets.zero,
      ),
      onChanged: (val) {
        if (val.isNotEmpty && index < 5) _otpFocus[index + 1].requestFocus();
        else if (val.isEmpty && index > 0) _otpFocus[index - 1].requestFocus();
        setState(() => _otpError = '');
      },
    ),
  );

  Widget _card({required IconData icon, required String title, required Widget child}) =>
    Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: _sg1.withOpacity(.06), blurRadius: 16, offset: const Offset(0, 4)),
          BoxShadow(color: Colors.black.withOpacity(.03), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 30, height: 30,
            decoration: BoxDecoration(
              color: _sg3.withOpacity(.15), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, size: 16, color: _sg2)),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(
              fontWeight: FontWeight.w900, fontSize: 14, color: _txt)),
        ]),
        const SizedBox(height: 14),
        child,
      ]),
    );

  Widget _kv(String label, String value) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(label, style: const TextStyle(color: _sub, fontSize: 11.5)),
    const SizedBox(height: 3),
    Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: _txt)),
  ]);

  Widget _infoRow(IconData icon, String label, String value) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(color: _bg, borderRadius: BorderRadius.circular(10)),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, size: 16, color: _sg2),
      const SizedBox(width: 8),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(color: _sub, fontSize: 11.5)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: _txt)),
      ])),
    ]),
  );

  Widget _step(String label, String time, bool done,
      {List<Color> grad = const [_sg1, _sg3], bool current = false}) =>
    Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Row(children: [
      Container(width: 16, height: 16,
        decoration: BoxDecoration(
          gradient: done ? LinearGradient(colors: grad) : null,
          color: done ? null : const Color(0xFFE0E0E0),
          shape: BoxShape.circle,
        )),
      const SizedBox(width: 12),
      Expanded(child: Text(label, style: TextStyle(
          fontWeight: FontWeight.w800, fontSize: 13,
          color: done ? _txt : _sub))),
      Text(time, style: TextStyle(
          fontSize: 12,
          color: current ? grad.last : _sub,
          fontWeight: current ? FontWeight.w800 : FontWeight.w500)),
    ]));
}
