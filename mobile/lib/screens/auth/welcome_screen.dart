import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'login_screen.dart';
import 'shop_owner_register_screen.dart';
import 'stockholder_register_screen.dart';

const _c0  = Color(0xFF060D28);
const _c1  = Color(0xFF0E2260);
const _c2  = Color(0xFF1F4BD5);
const _c3  = Color(0xFF6C3FE8);
const _grn1 = Color(0xFF054F3A);
const _grn2 = Color(0xFF0FBB84);

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
    onTapUp:   (_) { _c.reverse(); widget.onTap(); },
    onTapCancel: () => _c.reverse(),
    child: AnimatedBuilder(animation: _s,
      builder: (_, ch) => Transform.scale(scale: _s.value, child: ch),
      child: widget.child),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});
  @override State<WelcomeScreen> createState() => _WS();
}

class _WS extends State<WelcomeScreen> with SingleTickerProviderStateMixin {
  late final _entryC = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 900));

  @override
  void initState() {
    super.initState();
    _entryC.forward();
  }

  @override void dispose() { _entryC.dispose(); super.dispose(); }

  void _go(Widget screen) => Navigator.push(context,
      PageRouteBuilder(
        pageBuilder: (_, a, __) => screen,
        transitionDuration: const Duration(milliseconds: 320),
        transitionsBuilder: (_, a, __, ch) => FadeTransition(
            opacity: CurvedAnimation(parent: a, curve: Curves.easeOut),
            child: SlideTransition(
              position: Tween<Offset>(
                  begin: const Offset(0, .04), end: Offset.zero)
                  .animate(CurvedAnimation(parent: a, curve: Curves.easeOut)),
              child: ch)),
      ));

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: SystemUiOverlayStyle.light,
    child: Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
              colors: [_c0, _c1, _c2, _c3],
              stops: [0.0, 0.35, 0.7, 1.0],
              begin: Alignment.topLeft, end: Alignment.bottomRight),
        ),
        child: Stack(children: [
          // decorative blobs
          Positioned(top: -60, right: -60, child: _blob(220, Colors.white, .03)),
          Positioned(top: 80, left: -40,   child: _blob(120, _c3, .2)),
          Positioned(bottom: 160, right: -40, child: _blob(160, _c2, .15)),
          Positioned(bottom: -40, left: -20,  child: _blob(200, Colors.white, .03)),

          SafeArea(
            child: FadeTransition(
              opacity: CurvedAnimation(parent: _entryC, curve: Curves.easeOut),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(children: [
                  const SizedBox(height: 24),

                  // ── logo ──────────────────────────────────────────────────
                  SlideTransition(
                    position: Tween<Offset>(
                        begin: const Offset(0, -.1), end: Offset.zero)
                        .animate(CurvedAnimation(parent: _entryC,
                            curve: const Interval(.0, .6, curve: Curves.easeOut))),
                    child: Column(children: [
                      // icon ring
                      Container(width: 96, height: 96,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                              colors: [_c2, _c3],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight),
                          border: Border.all(color: Colors.white.withOpacity(.25), width: 2.5),
                          boxShadow: [
                            BoxShadow(color: _c3.withOpacity(.5),
                                blurRadius: 30, spreadRadius: -5, offset: const Offset(0, 10)),
                          ],
                        ),
                        child: const Icon(Icons.handshake_rounded,
                            color: Colors.white, size: 46)),
                      const SizedBox(height: 22),
                      // name
                      const Text('SupplyLink',
                          style: TextStyle(color: Colors.white,
                              fontSize: 34, fontWeight: FontWeight.w900,
                              letterSpacing: -1.2)),
                      const SizedBox(height: 8),
                      Text('Connect · Source · Grow',
                          style: TextStyle(
                              color: Colors.white.withOpacity(.55),
                              fontSize: 14, letterSpacing: 2.5,
                              fontWeight: FontWeight.w500)),
                    ]),
                  ),

                  const Spacer(),

                  // ── feature pills ─────────────────────────────────────────
                  SlideTransition(
                    position: Tween<Offset>(
                        begin: const Offset(0, .08), end: Offset.zero)
                        .animate(CurvedAnimation(parent: _entryC,
                            curve: const Interval(.25, .8, curve: Curves.easeOut))),
                    child: Column(children: [
                      const Text('Direct sourcing for Bangladeshi\nshop owners & suppliers',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white70,
                              fontSize: 15.5, height: 1.55)),
                      const SizedBox(height: 20),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 8, runSpacing: 8,
                        children: [
                          _pill(Icons.block_rounded, 'No Middlemen'),
                          _pill(Icons.location_on_rounded, 'Near You'),
                          _pill(Icons.star_rounded, 'Rated'),
                        ],
                      ),
                    ]),
                  ),

                  const Spacer(),

                  // ── role cards ────────────────────────────────────────────
                  SlideTransition(
                    position: Tween<Offset>(
                        begin: const Offset(0, .12), end: Offset.zero)
                        .animate(CurvedAnimation(parent: _entryC,
                            curve: const Interval(.35, 1.0, curve: Curves.easeOut))),
                    child: Column(children: [
                      _roleCard(
                        icon: Icons.storefront_rounded,
                        title: 'Shop Owner',
                        sub: 'Post demands, find suppliers, track orders',
                        grad: const [_c1, _c2, _c3],
                        onTap: () => _go(const ShopOwnerRegisterScreen()),
                      ),
                      const SizedBox(height: 14),
                      _roleCard(
                        icon: Icons.warehouse_rounded,
                        title: 'Stockholder / Supplier',
                        sub: 'List your stock, accept orders, deliver',
                        grad: const [_grn1, Color(0xFF0A7A56), _grn2],
                        onTap: () => _go(const StockholderRegisterScreen()),
                      ),
                    ]),
                  ),

                  const SizedBox(height: 28),

                  // ── sign in link ──────────────────────────────────────────
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text('Already have an account? ',
                        style: TextStyle(color: Colors.white.withOpacity(.6),
                            fontSize: 14)),
                    _Tap(onTap: () => _go(const LoginScreen()),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(.14),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withOpacity(.25)),
                        ),
                        child: const Text('Sign In',
                            style: TextStyle(color: Colors.white,
                                fontSize: 13.5, fontWeight: FontWeight.w800)),
                      )),
                  ]),

                  const SizedBox(height: 28),
                ]),
              ),
            ),
          ),
        ]),
      ),
    ),
  );

  Widget _roleCard({
    required IconData icon,
    required String title,
    required String sub,
    required List<Color> grad,
    required VoidCallback onTap,
  }) => _Tap(onTap: () { HapticFeedback.lightImpact(); onTap(); },
    child: ClipRRect(borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
                colors: [Colors.white.withOpacity(.14),
                         Colors.white.withOpacity(.07)],
                begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.white.withOpacity(.2)),
          ),
          child: Row(children: [
            Container(width: 52, height: 52,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: grad,
                    begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(15),
                boxShadow: [BoxShadow(color: grad.last.withOpacity(.45),
                    blurRadius: 14, offset: const Offset(0, 5))],
              ),
              child: Icon(icon, color: Colors.white, size: 26)),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(color: Colors.white,
                  fontSize: 16, fontWeight: FontWeight.w900)),
              const SizedBox(height: 3),
              Text(sub, style: TextStyle(
                  color: Colors.white.withOpacity(.6), fontSize: 12.5)),
            ])),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(.15),
                shape: BoxShape.circle),
              child: const Icon(Icons.arrow_forward_rounded,
                  color: Colors.white, size: 16)),
          ]),
        ),
      ),
    ),
  );

  Widget _pill(IconData icon, String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(.1),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.white.withOpacity(.15)),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, color: Colors.white70, size: 13),
      const SizedBox(width: 5),
      Text(label, style: const TextStyle(
          color: Colors.white70, fontSize: 11.5, fontWeight: FontWeight.w600)),
    ]),
  );

  Widget _blob(double sz, Color c, double op) =>
      Container(width: sz, height: sz,
          decoration: BoxDecoration(
              shape: BoxShape.circle, color: c.withOpacity(op)));
}
