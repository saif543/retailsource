import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/order_service.dart';

const _sg0 = Color(0xFF012B1E);
const _sg1 = Color(0xFF054F3A);
const _sg2 = Color(0xFF0A7A56);
const _sg3 = Color(0xFF0FBB84);
const _bg  = Color(0xFFF0FBF6);
const _txt = Color(0xFF212121);
const _sub = Color(0xFF757575);
const _ind1 = Color(0xFF2D238A);
const _ind2 = Color(0xFF7C6FF5);
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
class VerifyOtpScreen extends StatefulWidget {
  final Map<String, dynamic> order;
  const VerifyOtpScreen({super.key, required this.order});
  @override State<VerifyOtpScreen> createState() => _VOS();
}

class _VOS extends State<VerifyOtpScreen> {
  final List<TextEditingController> _ctrls =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _nodes = List.generate(6, (_) => FocusNode());
  bool _confirming = false;
  String _error = '';

  @override
  void dispose() {
    for (final c in _ctrls) c.dispose();
    for (final n in _nodes) n.dispose();
    super.dispose();
  }

  String get _otp => _ctrls.map((c) => c.text).join();

  Future<void> _confirm() async {
    if (_otp.length != 6) {
      setState(() => _error = 'Enter all 6 digits'); return;
    }
    final orderId = widget.order['order_id'] as int?;
    if (orderId == null) {
      setState(() => _error = 'Order ID missing'); return;
    }
    HapticFeedback.mediumImpact();
    setState(() { _confirming = true; _error = ''; });
    final result = await OrderService.verifyOtp(orderId, _otp);
    if (!mounted) return;
    setState(() => _confirming = false);
    if (result.ok) {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          child: Padding(padding: const EdgeInsets.all(28), child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 72, height: 72,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [_sg1, _sg3],
                    begin: Alignment.topLeft, end: Alignment.bottomRight),
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: _sg3.withOpacity(.4),
                    blurRadius: 18, offset: const Offset(0, 6))],
              ),
              child: const Icon(Icons.check_rounded, color: Colors.white, size: 38)),
            const SizedBox(height: 18),
            const Text('Delivered!', style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.w900, color: _txt)),
            const SizedBox(height: 8),
            const Text('OTP verified. Order has been successfully delivered.',
                textAlign: TextAlign.center,
                style: TextStyle(color: _sub, fontSize: 13.5)),
            const SizedBox(height: 24),
            _Tap(onTap: () { Navigator.pop(context); Navigator.pop(context, 'delivered'); },
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
    } else {
      setState(() => _error = result.error ?? 'Invalid or expired OTP');
    }
  }

  @override
  Widget build(BuildContext context) {
    final o = widget.order;
    return Scaffold(
      backgroundColor: _bg,
      body: Column(children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [_ind1, _ind1, _ind2],
              begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.only(
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
                const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Confirm Delivery', style: TextStyle(color: Colors.white,
                      fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -.4)),
                  SizedBox(height: 2),
                  Text('Enter OTP from shop owner',
                      style: TextStyle(color: Colors.white54, fontSize: 12.5)),
                ])),
              ]),
            ),
          ),
        ),
        Expanded(child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(children: [
            const SizedBox(height: 16),
            Container(width: 72, height: 72,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [_ind1, _ind2],
                    begin: Alignment.topLeft, end: Alignment.bottomRight),
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: _ind2.withOpacity(.4),
                    blurRadius: 18, offset: const Offset(0, 6))],
              ),
              child: const Icon(Icons.vpn_key_rounded, color: Colors.white, size: 34)),
            const SizedBox(height: 20),
            const Text('Enter 6-Digit OTP', style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.w900, color: _txt)),
            const SizedBox(height: 8),
            const Text('Ask the shop owner for their delivery OTP code',
                textAlign: TextAlign.center,
                style: TextStyle(color: _sub, fontSize: 13.5)),
            const SizedBox(height: 28),
            // order summary
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(18),
                boxShadow: [BoxShadow(color: _sg1.withOpacity(.06),
                    blurRadius: 14, offset: const Offset(0, 4))],
              ),
              child: Row(children: [
                Container(width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: _sg3.withOpacity(.15), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.inventory_2_rounded, color: _sg2, size: 22)),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text((o['product'] as String?) ?? '', style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 14, color: _txt)),
                  Text('${o['qty']} • ৳${(o['price'] as num?)?.toStringAsFixed(0) ?? '0'}',
                      style: const TextStyle(color: _sub, fontSize: 12.5)),
                ])),
              ]),
            ),
            const SizedBox(height: 28),
            Row(mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(6, _otpBox)),
            if (_error.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: _red2.withOpacity(.08), borderRadius: BorderRadius.circular(10)),
                child: Text(_error, style: const TextStyle(
                    color: _red2, fontSize: 13, fontWeight: FontWeight.w600))),
            ],
            const SizedBox(height: 28),
            _Tap(onTap: _confirming ? () {} : _confirm,
              child: Container(width: double.infinity, height: 56,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [_ind1, _ind2]),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [BoxShadow(color: _ind2.withOpacity(.35),
                      blurRadius: 18, offset: const Offset(0, 8))],
                ),
                child: Center(child: _confirming
                    ? const SizedBox(width: 22, height: 22,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                    : const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                        SizedBox(width: 10),
                        Text('Confirm Delivery', style: TextStyle(color: Colors.white,
                            fontSize: 16, fontWeight: FontWeight.w900)),
                      ])))),
          ]),
        )),
      ]),
    );
  }

  Widget _otpBox(int i) => Container(
    width: 44, height: 52,
    margin: const EdgeInsets.symmetric(horizontal: 3),
    child: TextField(
      controller: _ctrls[i], focusNode: _nodes[i],
      textAlign: TextAlign.center,
      keyboardType: TextInputType.number,
      maxLength: 1,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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
      onChanged: (v) {
        if (v.isNotEmpty && i < 5) _nodes[i + 1].requestFocus();
        else if (v.isEmpty && i > 0) _nodes[i - 1].requestFocus();
        setState(() => _error = '');
      },
    ),
  );
}
