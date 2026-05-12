import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../config/language.dart';
import '../../services/auth_service.dart';
import 'shop_owner_register_screen.dart';
import 'stockholder_register_screen.dart';

const _c0  = Color(0xFF060D28);
const _c1  = Color(0xFF0E2260);
const _c2  = Color(0xFF1F4BD5);
const _c3  = Color(0xFF6C3FE8);
const _bg  = Color(0xFFF2F5FF);
const _txt = Color(0xFF212121);
const _sub = Color(0xFF757575);
const _errC = Color(0xFF7B1C1C);

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
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override State<LoginScreen> createState() => _LS();
}

class _LS extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _idCtrl  = TextEditingController();
  final _pwCtrl  = TextEditingController();
  bool _obscure  = true;
  bool _loading  = false;

  late final _slideC = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 500));
  late final _slideA = Tween<Offset>(
      begin: const Offset(0, .08), end: Offset.zero)
      .animate(CurvedAnimation(parent: _slideC, curve: Curves.easeOut));

  @override
  void initState() {
    super.initState();
    _slideC.forward();
    appLang.addListener(_onLangChange);
  }

  void _onLangChange() => setState(() {});

  @override
  void dispose() {
    appLang.removeListener(_onLangChange);
    _idCtrl.dispose(); _pwCtrl.dispose(); _slideC.dispose(); super.dispose();
  }

  Future<void> _login() async {
    final id = _idCtrl.text.trim();
    final pw = _pwCtrl.text;
    if (id.isEmpty || pw.isEmpty) { _err(S('fill_all_fields')); return; }
    HapticFeedback.mediumImpact();
    setState(() => _loading = true);
    try {
      final r = await AuthService.login(emailOrPhone: id, password: pw);
      if (!mounted) return;
      if (r['statusCode'] == 200) {
        final role = r['user']['role'] as String?;
        if (role == 'shop_owner') {
          Navigator.pushNamedAndRemoveUntil(context, '/shop-dashboard', (_) => false);
        } else if (role == 'stockholder') {
          Navigator.pushNamedAndRemoveUntil(context, '/stock-dashboard', (_) => false);
        } else {
          Navigator.pushNamedAndRemoveUntil(context, '/admin-dashboard', (_) => false);
        }
      } else {
        _err(r['error']?.toString() ?? S('login_failed'));
      }
    } catch (_) {
      if (mounted) _err(S('server_error'));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _err(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: _errC, content: Text(msg,
          style: const TextStyle(fontWeight: FontWeight.w600))));

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: SystemUiOverlayStyle.light,
    child: Scaffold(
      backgroundColor: _bg,
      resizeToAvoidBottomInset: true,
      body: Column(children: [
        // ── gradient header ──────────────────────────────────────────────
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
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 36),
                child: Column(children: [
                  Row(children: [
                    if (Navigator.canPop(context))
                      _Tap(onTap: () => Navigator.pop(context),
                        child: Container(width: 40, height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(.14),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withOpacity(.25)),
                          ),
                          child: const Icon(Icons.arrow_back_ios_new_rounded,
                              color: Colors.white, size: 16))),
                  ]),
                  const SizedBox(height: 20),
                  Container(width: 72, height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(colors: [_c2, _c3],
                          begin: Alignment.topLeft, end: Alignment.bottomRight),
                      border: Border.all(color: Colors.white.withOpacity(.3), width: 2.5),
                      boxShadow: [BoxShadow(color: _c3.withOpacity(.45),
                          blurRadius: 24, spreadRadius: -4, offset: const Offset(0, 8))],
                    ),
                    child: const Icon(Icons.handshake_rounded,
                        color: Colors.white, size: 34)),
                  const SizedBox(height: 16),
                  Text(S('welcome_back'), style: const TextStyle(color: Colors.white,
                      fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -.5)),
                  const SizedBox(height: 5),
                  Text(S('sign_in_subtitle'),
                      style: TextStyle(color: Colors.white.withOpacity(.6), fontSize: 14)),
                ]),
              ),
            ]),
          ),
        ),

        // ── form card ────────────────────────────────────────────────────
        Expanded(
          child: SlideTransition(
            position: _slideA,
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFFF2F5FF),
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(color: _c1.withOpacity(.08),
                            blurRadius: 24, offset: const Offset(0, 8)),
                      ],
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      _label(S('email_or_phone')),
                      _field(controller: _idCtrl, hint: S('email_phone_hint'),
                          icon: Icons.person_outline_rounded,
                          type: TextInputType.emailAddress),
                      const SizedBox(height: 16),
                      _label(S('password')),
                      _fieldObscure(),
                    ]),
                  ),
                  const SizedBox(height: 28),

                  // sign in button
                  _Tap(onTap: _loading ? () {} : _login,
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
                                const Icon(Icons.login_rounded, color: Colors.white, size: 20),
                                const SizedBox(width: 10),
                                Text(S('sign_in'), style: const TextStyle(color: Colors.white,
                                    fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: .3)),
                              ])),
                      ]),
                    ),
                  ),

                  const SizedBox(height: 28),

                  Row(children: [
                    Expanded(child: Divider(color: Colors.grey.shade300)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Text(S('no_account'),
                          style: TextStyle(color: _sub.withOpacity(.7), fontSize: 13))),
                    Expanded(child: Divider(color: Colors.grey.shade300)),
                  ]),

                  const SizedBox(height: 20),

                  Row(children: [
                    Expanded(child: _Tap(
                      onTap: () => Navigator.pushReplacement(context,
                          MaterialPageRoute(builder: (_) => const ShopOwnerRegisterScreen())),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: _c2.withOpacity(.3)),
                          boxShadow: [BoxShadow(color: _c1.withOpacity(.06),
                              blurRadius: 12, offset: const Offset(0, 4))],
                        ),
                        child: Column(children: [
                          const Icon(Icons.storefront_rounded, color: _c2, size: 24),
                          const SizedBox(height: 6),
                          Text(S('shop_owner'), style: const TextStyle(color: _c1,
                              fontSize: 12.5, fontWeight: FontWeight.w800)),
                          Text(S('sign_up'), style: const TextStyle(
                              color: _sub, fontSize: 11.5)),
                        ]),
                      ),
                    )),
                    const SizedBox(width: 12),
                    Expanded(child: _Tap(
                      onTap: () => Navigator.pushReplacement(context,
                          MaterialPageRoute(builder: (_) => const StockholderRegisterScreen())),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFF0FBB84).withOpacity(.3)),
                          boxShadow: [BoxShadow(color: const Color(0xFF054F3A).withOpacity(.06),
                              blurRadius: 12, offset: const Offset(0, 4))],
                        ),
                        child: Column(children: [
                          const Icon(Icons.warehouse_rounded,
                              color: Color(0xFF0A7A56), size: 24),
                          const SizedBox(height: 6),
                          Text(S('stockholder_supplier').split(' /').first,
                              style: const TextStyle(
                                  color: Color(0xFF054F3A),
                                  fontSize: 12.5, fontWeight: FontWeight.w800)),
                          Text(S('sign_up'), style: const TextStyle(
                              color: _sub, fontSize: 11.5)),
                        ]),
                      ),
                    )),
                  ]),
                ]),
              ),
            ),
          ),
        ),
      ]),
    ),
  );

  Widget _label(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 8, left: 2),
    child: Text(t, style: const TextStyle(fontSize: 13,
        fontWeight: FontWeight.w800, color: _txt)),
  );

  Widget _field({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType type = TextInputType.text,
  }) => TextField(
    controller: controller,
    keyboardType: type,
    style: const TextStyle(fontSize: 14.5, color: _txt, fontWeight: FontWeight.w600),
    decoration: InputDecoration(
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
    ),
  );

  Widget _fieldObscure() => StatefulBuilder(
    builder: (_, set) => TextField(
      controller: _pwCtrl,
      obscureText: _obscure,
      style: const TextStyle(fontSize: 14.5, color: _txt, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        hintText: S('password_hint'),
        hintStyle: const TextStyle(color: Color(0xFFBBC0D4), fontSize: 14),
        prefixIcon: const Icon(Icons.lock_outline_rounded, color: _sub, size: 20),
        suffixIcon: IconButton(
          icon: Icon(_obscure
              ? Icons.visibility_outlined : Icons.visibility_off_outlined,
              color: _sub, size: 20),
          onPressed: () => setState(() => _obscure = !_obscure),
        ),
        filled: true, fillColor: _bg,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE4E8F5))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: _c2.withOpacity(.5), width: 1.5)),
      ),
    ),
  );

  Widget _blob(double sz, Color c, double op) =>
      Container(width: sz, height: sz,
          decoration: BoxDecoration(shape: BoxShape.circle, color: c.withOpacity(op)));
}
