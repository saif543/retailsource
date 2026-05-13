import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/auth_service.dart';
import '../../config/language.dart';
import 'login_screen.dart';

const _c0  = Color(0xFF060D28);
const _c1  = Color(0xFF0E2260);
const _c2  = Color(0xFF1F4BD5);
const _c3  = Color(0xFF6C3FE8);
const _bg  = Color(0xFFF2F5FF);
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
  late final _s = Tween<double>(begin: 1.0, end: 0.96)
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
class ShopOwnerRegisterScreen extends StatefulWidget {
  const ShopOwnerRegisterScreen({super.key});
  @override State<ShopOwnerRegisterScreen> createState() => _SORS();
}

class _SORS extends State<ShopOwnerRegisterScreen>
    with SingleTickerProviderStateMixin {
  final _nameCtrl  = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _shopCtrl  = TextEditingController();
  final _pwCtrl    = TextEditingController();
  String? _category;
  bool _obscure  = true;
  bool _loading  = false;

  late final _slideC = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 450));
  late final _slideA = Tween<Offset>(
      begin: const Offset(0, .06), end: Offset.zero)
      .animate(CurvedAnimation(parent: _slideC, curve: Curves.easeOut));

  static const _cats = ['Grocery', 'Pharmacy', 'Stationary', 'Hardware'];
  static const _catIcons = {
    'Grocery':    Icons.shopping_basket_rounded,
    'Pharmacy':   Icons.local_pharmacy_rounded,
    'Stationary': Icons.edit_rounded,
    'Hardware':   Icons.hardware_rounded,
  };

  @override
  void initState() { super.initState(); appLang.addListener(_onLangChange); _slideC.forward(); }
  void _onLangChange() => setState(() {});
  @override
  void dispose() {
    appLang.removeListener(_onLangChange);
    _nameCtrl.dispose(); _phoneCtrl.dispose();
    _shopCtrl.dispose(); _pwCtrl.dispose();
    _slideC.dispose(); super.dispose();
  }

  Future<void> _register() async {
    if (_nameCtrl.text.isEmpty || _phoneCtrl.text.isEmpty ||
        _shopCtrl.text.isEmpty || _category == null || _pwCtrl.text.isEmpty) {
      _err(S('fill_all_fields')); return;
    }
    if (_pwCtrl.text.length < 6) {
      _err(S('password_min_length')); return;
    }
    HapticFeedback.mediumImpact();
    setState(() => _loading = true);
    try {
      final r = await AuthService.registerShopOwner(
        name: _nameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        password: _pwCtrl.text,
        shopName: _shopCtrl.text.trim(),
        shopCategory: _category!,
      );
      if (!mounted) return;
      if (r['statusCode'] == 201) {
        Navigator.pushReplacementNamed(context, '/shop-dashboard');
      } else {
        _err(r['error']?.toString() ?? 'Registration failed');
      }
    } catch (_) {
      if (mounted) _err(S('cannot_connect'));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _err(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: const Color(0xFF7B1C1C),
      content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600))));

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: SystemUiOverlayStyle.light,
    child: Scaffold(
      backgroundColor: _bg,
      resizeToAvoidBottomInset: true,
      body: Column(children: [
        // ── header ───────────────────────────────────────────────────────
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
                colors: [_c0, _c1, _c2, _c3],
                stops: [0.0, 0.35, 0.7, 1.0],
                begin: Alignment.topLeft, end: Alignment.bottomRight),
          ),
          child: SafeArea(bottom: false,
            child: Stack(children: [
              Positioned(top: -30, right: -40, child: _blob(160, Colors.white, .04)),
              Positioned(top: 20, right: 60,   child: _blob(50, _c3, .3)),
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
                      Text(S('shop_owner_signup'), style: const TextStyle(color: Colors.white,
                          fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -.4)),
                      const SizedBox(height: 2),
                      Text(S('create_account_subtitle'),
                          style: const TextStyle(color: Colors.white54, fontSize: 12.5)),
                    ])),
                  ]),
                  const SizedBox(height: 20),
                  Center(child: Container(width: 68, height: 68,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(.18),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withOpacity(.3), width: 2),
                    ),
                    child: const Icon(Icons.storefront_rounded,
                        color: Colors.white, size: 34))),
                ]),
              ),
            ]),
          ),
        ),

        // ── form ─────────────────────────────────────────────────────────
        Expanded(
          child: SlideTransition(
            position: _slideA,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _card(child: Column(children: [
                  _label(S('full_name')),
                  _field(_nameCtrl, 'e.g. Karim Uddin', Icons.person_outline_rounded),
                  const SizedBox(height: 14),
                  _label(S('phone_number')),
                  _field(_phoneCtrl, '01XXXXXXXXX',
                      Icons.phone_outlined, type: TextInputType.phone),
                  const SizedBox(height: 14),
                  _label(S('shop_name')),
                  _field(_shopCtrl, 'e.g. Al-Amin Grocery', Icons.store_outlined),
                ])),
                const SizedBox(height: 16),

                _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _label(S('what_do_you_sell')),
                  const SizedBox(height: 12),
                  Wrap(spacing: 10, runSpacing: 10,
                    children: _cats.map((cat) {
                      final sel = _category == cat;
                      return _Tap(onTap: () {
                        HapticFeedback.lightImpact();
                        setState(() => _category = sel ? null : cat);
                      }, child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                        decoration: BoxDecoration(
                          gradient: sel ? const LinearGradient(colors: [_c1, _c3]) : null,
                          color: sel ? null : const Color(0xFFEEF0FA),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: sel ? Colors.transparent : const Color(0xFFD8DCF0)),
                          boxShadow: sel ? [BoxShadow(color: _c2.withOpacity(.3),
                              blurRadius: 8, offset: const Offset(0, 3))] : null,
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(_catIcons[cat]!,
                              color: sel ? Colors.white : _sub, size: 16),
                          const SizedBox(width: 7),
                          Text(cat, style: TextStyle(
                              color: sel ? Colors.white : _txt,
                              fontSize: 13.5, fontWeight: FontWeight.w700)),
                        ]),
                      ));
                    }).toList()),
                ])),
                const SizedBox(height: 16),

                _card(child: Column(children: [
                  _label(S('password')),
                  _obscureField(),
                  const SizedBox(height: 6),
                  Align(alignment: Alignment.centerLeft,
                    child: Text(S('min_6_chars'),
                        style: const TextStyle(color: _sub, fontSize: 11.5))),
                ])),
                const SizedBox(height: 28),

                // register button
                _Tap(onTap: _loading ? () {} : _register,
                  child: Container(
                    width: double.infinity, height: 56,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [_c0, _c2, _c3],
                          stops: [0.0, 0.5, 1.0],
                          begin: Alignment.topLeft, end: Alignment.bottomRight),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [BoxShadow(color: _c2.withOpacity(.45),
                          blurRadius: 22, spreadRadius: -2, offset: const Offset(0, 10))],
                    ),
                    child: Stack(children: [
                      Positioned.fill(child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Align(alignment: Alignment.topCenter,
                          child: FractionallySizedBox(heightFactor: .45, widthFactor: 1,
                            child: Container(decoration: BoxDecoration(
                              gradient: LinearGradient(begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [Colors.white.withOpacity(.18), Colors.transparent]))))))),
                      Center(child: _loading
                          ? const SizedBox(width: 22, height: 22,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2.5))
                          : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                              const SizedBox(width: 10),
                              Text(S('create_account'), style: const TextStyle(color: Colors.white,
                                  fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: .2)),
                            ])),
                    ]),
                  ),
                ),

                const SizedBox(height: 20),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(S('already_have_account'),
                      style: const TextStyle(color: _sub, fontSize: 14)),
                  _Tap(onTap: () => Navigator.pushReplacement(context,
                      MaterialPageRoute(builder: (_) => const LoginScreen())),
                    child: Text(S('sign_in'), style: const TextStyle(color: _c2,
                        fontSize: 14, fontWeight: FontWeight.w800))),
                ]),
              ]),
            ),
          ),
        ),
      ]),
    ),
  );

  Widget _card({required Widget child}) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      boxShadow: [
        BoxShadow(color: _c1.withOpacity(.07), blurRadius: 20, offset: const Offset(0, 6)),
        BoxShadow(color: Colors.black.withOpacity(.03), blurRadius: 4, offset: const Offset(0, 2)),
      ],
    ),
    child: child,
  );

  Widget _label(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 8, left: 2),
    child: Text(t, style: const TextStyle(fontSize: 13,
        fontWeight: FontWeight.w800, color: _txt)),
  );

  Widget _field(TextEditingController c, String hint, IconData icon,
      {TextInputType type = TextInputType.text}) => TextField(
    controller: c, keyboardType: type,
    style: const TextStyle(fontSize: 14.5, color: _txt, fontWeight: FontWeight.w600),
    decoration: _deco(hint, icon),
  );

  Widget _obscureField() => StatefulBuilder(
    builder: (_, set) => TextField(
      controller: _pwCtrl, obscureText: _obscure,
      style: const TextStyle(fontSize: 14.5, color: _txt, fontWeight: FontWeight.w600),
      decoration: _deco('Create a password', Icons.lock_outline_rounded).copyWith(
        suffixIcon: IconButton(
          icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
              color: _sub, size: 20),
          onPressed: () => setState(() => _obscure = !_obscure),
        ),
      ),
    ),
  );

  InputDecoration _deco(String hint, IconData icon) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: Color(0xFFBBC0D4), fontSize: 14),
    prefixIcon: Icon(icon, color: _sub, size: 20),
    filled: true, fillColor: _bg,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE4E8F5))),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: _c2.withOpacity(.5), width: 1.5)),
  );

  Widget _blob(double sz, Color c, double op) =>
      Container(width: sz, height: sz,
          decoration: BoxDecoration(shape: BoxShape.circle, color: c.withOpacity(op)));
}
