import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/rating_service.dart';

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
class RateSupplierScreen extends StatefulWidget {
  final Map<String, dynamic> order;
  const RateSupplierScreen({super.key, required this.order});
  @override State<RateSupplierScreen> createState() => _RSS();
}

class _RSS extends State<RateSupplierScreen> with SingleTickerProviderStateMixin {
  int _rating = 0;
  final _reviewCtrl = TextEditingController();
  bool _submitting = false;

  late final _fadeC = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 400));

  @override
  void initState() {
    super.initState();
    _fadeC.forward();
    _reviewCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() { _reviewCtrl.dispose(); _fadeC.dispose(); super.dispose(); }

  bool get _canSubmit => _rating > 0 && _reviewCtrl.text.trim().length >= 10;

  String get _ratingLabel {
    switch (_rating) {
      case 1: return 'Poor';
      case 2: return 'Fair';
      case 3: return 'Good';
      case 4: return 'Very Good';
      case 5: return 'Excellent!';
      default: return 'Tap a star to rate';
    }
  }

  List<Color> get _ratingGrad {
    if (_rating <= 2) return [const Color(0xFF7B1C1C), const Color(0xFFEF5350)];
    if (_rating == 3) return [_amb1, _amb2];
    return [_grn1, _grn2];
  }

  Future<void> _submit() async {
    if (!_canSubmit) return;
    final orderId = widget.order['order_id'] as int?;
    if (orderId == null) return;
    HapticFeedback.mediumImpact();
    setState(() => _submitting = true);
    final res = await RatingService.submitRating(
      orderId: orderId,
      score: _rating,
      review: _reviewCtrl.text.trim(),
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (!res.ok) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: const Color(0xFF7B1C1C),
          content: Text(res.error ?? 'Failed to submit rating',
              style: const TextStyle(fontWeight: FontWeight.w600))));
      return;
    }
    _showSuccess();
  }

  void _showSuccess() => showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 72, height: 72,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [_grn1, _grn2],
                  begin: Alignment.topLeft, end: Alignment.bottomRight),
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: _grn2.withOpacity(.4),
                  blurRadius: 16, offset: const Offset(0, 6))],
            ),
            child: const Icon(Icons.check_rounded, color: Colors.white, size: 36)),
          const SizedBox(height: 18),
          const Text('Thank You!', style: TextStyle(fontSize: 22,
              fontWeight: FontWeight.w900, color: _txt)),
          const SizedBox(height: 8),
          const Text('Your review has been submitted and will help other shop owners.',
              textAlign: TextAlign.center,
              style: TextStyle(color: _sub, fontSize: 13.5)),
          const SizedBox(height: 24),
          _Tap(
            onTap: () {
              Navigator.pop(context); // close dialog
              Navigator.pushNamedAndRemoveUntil(context, '/shop-dashboard', (_) => false);
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [_grn1, _grn2]),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Center(child: Text('Done',
                  style: TextStyle(color: Colors.white,
                      fontSize: 15, fontWeight: FontWeight.w900))),
            ),
          ),
        ]),
      ),
    ),
  );

  // ════════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final o         = widget.order;
    final supplier  = o['supplier'] as String? ?? o['stockholder_name'] as String? ?? '';
    final product   = o['product'] as String? ??
        '${o['product_name'] ?? ''}${o['variant_name'] != null ? ' - ${o['variant_name']}' : ''}';
    final qty       = o['qty'] as String? ??
        '${(o['quantity'] as num?)?.toStringAsFixed(0) ?? ''} ${o['unit'] ?? ''}';
    final price     = (o['price'] as num?)?.toDouble() ??
        (o['total_price'] as num?)?.toDouble() ?? 0.0;
    final initials  = supplier.isNotEmpty
        ? supplier.trim().split(' ').map((s) => s[0]).take(2).join().toUpperCase()
        : '?';

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _bg,
        body: FadeTransition(
          opacity: CurvedAnimation(parent: _fadeC, curve: Curves.easeOut),
          child: Column(children: [
            _header(),
            Expanded(child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
              child: Column(children: [
                // supplier hero
                _supplierHero(supplier, initials),
                const SizedBox(height: 20),
                // order summary
                _orderSummary(product, qty, price),
                const SizedBox(height: 20),
                // star rating
                _starCard(),
                const SizedBox(height: 20),
                // review text
                _reviewCard(),
                const SizedBox(height: 32),
                // submit
                _submitBtn(),
                if (!_canSubmit) ...[
                  const SizedBox(height: 10),
                  Text(
                    _rating == 0 ? 'Select a star rating to continue'
                        : 'Write at least 10 characters (${_reviewCtrl.text.trim().length}/10)',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: _sub, fontSize: 12.5)),
                ],
              ]),
            )),
          ]),
        ),
      ),
    );
  }

  // ── gradient header ───────────────────────────────────────────────────────
  Widget _header() => Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
          colors: [Color(0xFF3D0000), Color(0xFF7C1A00),
                   Color(0xFFD03800), Color(0xFFFF9500)],
          stops: [0.0, 0.3, 0.65, 1.0],
          begin: Alignment.topLeft, end: Alignment.bottomRight),
      borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32), bottomRight: Radius.circular(32)),
    ),
    child: SafeArea(bottom: false,
      child: Stack(children: [
        Positioned(top: -20, right: -30, child: _blob(130, Colors.white, .04)),
        Positioned(top: 8,   right: 50,  child: _blob(44, const Color(0xFFD03800), .3)),
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 20, 22),
          child: Row(children: [
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
              Text('Rate Supplier', style: TextStyle(color: Colors.white,
                  fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -.4)),
              SizedBox(height: 2),
              Text('Share your delivery experience',
                  style: TextStyle(color: Colors.white54, fontSize: 12.5)),
            ])),
            // star badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(.25)),
              ),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.star_rounded, color: Colors.white, size: 14),
                SizedBox(width: 4),
                Text('5 Stars', style: TextStyle(color: Colors.white,
                    fontSize: 12, fontWeight: FontWeight.w700)),
              ])),
          ]),
        ),
      ]),
    ),
  );

  // ── supplier hero ─────────────────────────────────────────────────────────
  Widget _supplierHero(String name, String initials) => Container(
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      boxShadow: [
        BoxShadow(color: _c1.withOpacity(.08), blurRadius: 20, offset: const Offset(0, 6)),
        BoxShadow(color: Colors.black.withOpacity(.03), blurRadius: 4, offset: const Offset(0, 2)),
      ],
    ),
    child: Column(children: [
      Container(width: 76, height: 76,
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [_c1, _c3],
              begin: Alignment.topLeft, end: Alignment.bottomRight),
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: _c2.withOpacity(.35),
              blurRadius: 16, offset: const Offset(0, 6))],
        ),
        child: Center(child: Text(initials,
            style: const TextStyle(color: Colors.white,
                fontSize: 26, fontWeight: FontWeight.w900)))),
      const SizedBox(height: 14),
      Text(name.isNotEmpty ? name : 'Supplier',
          style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: _txt)),
      const SizedBox(height: 6),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [_grn1, _grn2]),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.verified_rounded, size: 13, color: Colors.white),
          SizedBox(width: 5),
          Text('Verified Supplier', style: TextStyle(color: Colors.white,
              fontSize: 11.5, fontWeight: FontWeight.w800)),
        ])),
    ]),
  );

  // ── order summary ─────────────────────────────────────────────────────────
  Widget _orderSummary(String product, String qty, double price) => Container(
    padding: const EdgeInsets.all(20),
    decoration: _cardDeco(),
    child: Column(children: [
      _infoRow(Icons.shopping_basket_rounded, _c2,   'Product',  product),
      _divider(),
      _infoRow(Icons.scale_rounded,           _sub,  'Quantity', qty),
      _divider(),
      _infoRow(Icons.payments_rounded,        _grn1, 'Total',
          '৳${price.toStringAsFixed(0)}', valueBold: true),
    ]),
  );

  // ── star rating card ──────────────────────────────────────────────────────
  Widget _starCard() => Container(
    padding: const EdgeInsets.all(22),
    decoration: _cardDeco(),
    child: Column(children: [
      const Text('How was your experience?', style: TextStyle(fontSize: 15,
          fontWeight: FontWeight.w900, color: _txt, letterSpacing: -.2)),
      const SizedBox(height: 4),
      const Text('Rate your overall experience with this supplier',
          textAlign: TextAlign.center,
          style: TextStyle(color: _sub, fontSize: 12.5)),
      const SizedBox(height: 22),
      Row(mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(5, (i) {
          final filled = i < _rating;
          return _Tap(onTap: () {
            HapticFeedback.lightImpact();
            setState(() => _rating = i + 1);
          }, child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: filled ? 0.8 : 1.0, end: filled ? 1.0 : 0.8),
              duration: const Duration(milliseconds: 200),
              curve: Curves.elasticOut,
              builder: (_, scale, __) => Transform.scale(
                scale: scale,
                child: Icon(
                  filled ? Icons.star_rounded : Icons.star_outline_rounded,
                  size: 46,
                  color: filled ? const Color(0xFFFFB300) : Colors.grey.shade300),
              ),
            ),
          ));
        }),
      ),
      const SizedBox(height: 12),
      AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: _rating > 0
            ? Container(
                key: ValueKey(_rating),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: _ratingGrad),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(_ratingLabel, style: const TextStyle(
                    color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800)))
            : Text(_ratingLabel, key: const ValueKey(0),
                style: const TextStyle(color: _sub, fontSize: 13.5)),
      ),
    ]),
  );

  // ── review text card ──────────────────────────────────────────────────────
  Widget _reviewCard() => Container(
    padding: const EdgeInsets.all(20),
    decoration: _cardDeco(),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(width: 32, height: 32,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [_c1, _c3],
                begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(9),
          ),
          child: const Icon(Icons.rate_review_rounded, color: Colors.white, size: 15)),
        const SizedBox(width: 10),
        const Text('Write your review', style: TextStyle(fontSize: 15,
            fontWeight: FontWeight.w800, color: _txt, letterSpacing: -.2)),
      ]),
      const SizedBox(height: 14),
      TextField(
        controller: _reviewCtrl,
        maxLines: 5,
        style: const TextStyle(fontSize: 14, color: _txt),
        decoration: InputDecoration(
          hintText: 'Was the product quality good? Was delivery on time? '
              'How was the supplier\'s communication?',
          hintStyle: const TextStyle(color: Color(0xFFBBC0D4), fontSize: 13),
          filled: true,
          fillColor: _bg,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: _c2.withOpacity(.4), width: 1.5)),
          contentPadding: const EdgeInsets.all(14),
        ),
      ),
      const SizedBox(height: 8),
      Row(children: [
        const Spacer(),
        Text('${_reviewCtrl.text.trim().length}/10 min characters',
            style: TextStyle(
                fontSize: 11.5,
                color: _reviewCtrl.text.trim().length >= 10 ? _grn2 : _sub,
                fontWeight: FontWeight.w600)),
      ]),
    ]),
  );

  // ── submit button ─────────────────────────────────────────────────────────
  Widget _submitBtn() => _Tap(
    onTap: (_canSubmit && !_submitting) ? _submit : () {},
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: double.infinity, height: 58,
      decoration: BoxDecoration(
        gradient: _canSubmit
            ? const LinearGradient(
                colors: [Color(0xFF7C1A00), Color(0xFFD03800),
                         Color(0xFFF06000), Color(0xFFFF9500)],
                stops: [0.0, 0.32, 0.68, 1.0],
                begin: Alignment.topLeft, end: Alignment.bottomRight)
            : null,
        color: _canSubmit ? null : const Color(0xFFDDE0F0),
        borderRadius: BorderRadius.circular(18),
        boxShadow: _canSubmit ? [BoxShadow(
            color: const Color(0xFFF06000).withOpacity(.45),
            blurRadius: 22, spreadRadius: -2, offset: const Offset(0, 10))] : null,
      ),
      child: Stack(children: [
        if (_canSubmit)
          Positioned.fill(child: ClipRRect(borderRadius: BorderRadius.circular(18),
            child: Align(alignment: Alignment.topCenter,
              child: FractionallySizedBox(heightFactor: .45, widthFactor: 1,
                child: Container(decoration: BoxDecoration(
                  gradient: LinearGradient(begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.white.withOpacity(.2), Colors.transparent]))))))),
        Center(child: _submitting
            ? const SizedBox(width: 22, height: 22,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
            : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.send_rounded,
                    color: _canSubmit ? Colors.white : _sub, size: 20),
                const SizedBox(width: 10),
                Text('Submit Review', style: TextStyle(
                    color: _canSubmit ? Colors.white : _sub,
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

  Widget _infoRow(IconData icon, Color c, String label, String value,
      {bool valueBold = false}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(children: [
      Container(width: 34, height: 34,
        decoration: BoxDecoration(
            color: c.withOpacity(.1), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: c, size: 16)),
      const SizedBox(width: 12),
      SizedBox(width: 75, child: Text(label, style: const TextStyle(
          fontSize: 13, color: _sub, fontWeight: FontWeight.w500))),
      Expanded(child: Text(value, style: TextStyle(fontSize: 13.5, color: _txt,
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
