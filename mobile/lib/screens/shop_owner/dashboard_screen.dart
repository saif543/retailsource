import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../config/app_colors.dart';
import '../../services/auth_service.dart';
import '../../services/demand_service.dart';
import '../../services/order_service.dart';
import '../../services/profile_service.dart';
import '../../services/notification_service.dart';
import '../../services/rating_service.dart';
import 'post_demand_screen.dart';
import 'my_demands_screen.dart';
import 'demand_detail_screen.dart';
import 'browse_stocks_screen.dart';
import 'my_orders_screen.dart';
import 'order_status_screen.dart';
import 'rate_supplier_screen.dart';
import '../shared/notifications_screen.dart';
import '../shared/profile_screen.dart';
import '../../services/location_service.dart';
import '../shared/location_picker_screen.dart';

// ── palette ───────────────────────────────────────────────────────────────────
const _c0 = Color(0xFF060D28);   // deepest navy
const _c1 = Color(0xFF0E2260);   // dark blue
const _c2 = Color(0xFF1F4BD5);   // electric blue
const _c3 = Color(0xFF6C3FE8);   // indigo-violet
const _bg = Color(0xFFF2F5FF);   // page bg

const _blue1 = Color(0xFF1840AF); const _blue2 = Color(0xFF4F8EF7);
const _grn1  = Color(0xFF054F3A); const _grn2  = Color(0xFF0FBB84);
const _amb1  = Color(0xFFAD4A0A); const _amb2  = Color(0xFFF5981E);
const _ind1  = Color(0xFF2D238A); const _ind2  = Color(0xFF7C6FF5);
const _teal1 = Color(0xFF094E6A); const _teal2 = Color(0xFF17BBDD);

// ── tap wrapper ───────────────────────────────────────────────────────────────
class _Tap extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  const _Tap({required this.child, required this.onTap});
  @override State<_Tap> createState() => _TapS();
}
class _TapS extends State<_Tap> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this,
      duration: const Duration(milliseconds: 80),
      reverseDuration: const Duration(milliseconds: 220));
  late final _s = Tween<double>(begin: 1.0, end: 0.93)
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

// ── dashboard ─────────────────────────────────────────────────────────────────
class ShopOwnerDashboard extends StatefulWidget {
  final String shopName;
  final String userName;
  const ShopOwnerDashboard({super.key, this.shopName = 'My Shop', this.userName = 'Shop Owner'});
  @override State<ShopOwnerDashboard> createState() => _DS();
}

class _DS extends State<ShopOwnerDashboard> with TickerProviderStateMixin {
  int _tab = 0;
  Map<String, int> _stats = {'open_demands': 0, 'matched_demands': 0, 'active_orders': 0};
  List<Map<String, dynamic>> _demands = [], _orders = [], _unrated = [];
  int _badge = 0;
  bool _busy = false, _hasLoc = true;
  double? _lat, _lng;
  String _locAddress = '';

  late final _hC = AnimationController(vsync: this, duration: const Duration(milliseconds: 750));
  late final _lC = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
  late final _hFade = CurvedAnimation(parent: _hC, curve: Curves.easeOut);
  late final _hSlide = Tween<Offset>(begin: const Offset(0, .04), end: Offset.zero)
      .animate(CurvedAnimation(parent: _hC, curve: Curves.easeOut));

  Animation<double> _fd(int i) => Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
      parent: _lC, curve: Interval((i*.1).clamp(0,.7), ((i*.1)+.45).clamp(0,1), curve: Curves.easeOut)));
  Animation<Offset> _sl(int i) => Tween<Offset>(begin: const Offset(0,.08), end: Offset.zero)
      .animate(CurvedAnimation(parent: _lC,
        curve: Interval((i*.1).clamp(0,.7), ((i*.1)+.45).clamp(0,1), curve: Curves.easeOut)));

  @override
  void initState() { super.initState(); _hC.forward(); _load(); }
  @override
  void dispose() { _hC.dispose(); _lC.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() => _busy = true);
    _lC.reset();
    try {
      final fs = DemandService.getShopStats();
      final fo = OrderService.getMyOrders();
      final fd = DemandService.getMyDemands();
      final fp = ProfileService.getProfile();
      final fn = NotificationService.getNotifications();
      final fu = RatingService.getUnratedOrders();
      final stats = await fs; final orders = await fo;
      final demands = await fd; final profile = await fp;
      final notifs = await fn; final unrated = await fu;
      if (!mounted) return;
      final prof = (profile?['profile'] as Map?) ?? {};
      final lat = (prof['lat'] as num?)?.toDouble();
      final lng = (prof['lng'] as num?)?.toDouble();
      Color oc(String s) { switch (s) {
        case 'pending': return _amb2; case 'accepted': return _blue2;
        case 'out_for_delivery': return _ind2; default: return _grn2; } }
      IconData oi(String s) { switch (s) {
        case 'pending': return Icons.hourglass_top_rounded;
        case 'out_for_delivery': return Icons.local_shipping_rounded;
        case 'delivered': return Icons.check_circle_rounded;
        default: return Icons.check_circle_outline; } }
      String ol(String s) { switch (s) {
        case 'pending': return 'Waiting'; case 'accepted': return 'Accepted';
        case 'out_for_delivery': return 'On the Way'; default: return 'Delivered'; } }
      setState(() {
        _lat = lat; _lng = lng;
        _hasLoc = lat != null && lat != 0 && lng != null && lng != 0;
        _locAddress = (prof['shop_address'] as String?) ?? '';
        _stats = stats; _badge = notifs.unread; _busy = false;
        _unrated = unrated.take(5).toList();
        _demands = demands.where((d) => d['status']=='open'||d['status']=='matched').take(4).toList();
        _orders = orders.where((o) => o['status']!='delivered').take(3).map((o) {
          final st = o['status'] as String;
          return {...o, 'sc': oc(st), 'ic': oi(st), 'lb': ol(st)};
        }).toList();
      });
      _lC.forward();
    } catch (_) { if (mounted) setState(() => _busy = false); }
  }

  PageRoute _push(Widget w) => PageRouteBuilder(
    pageBuilder: (_, a, __) => w,
    transitionDuration: const Duration(milliseconds: 280),
    transitionsBuilder: (_, a, __, ch) => SlideTransition(
      position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
          .animate(CurvedAnimation(parent: a, curve: Curves.easeInOut)), child: ch),
  );

  Future<void> _go(Widget w) async { await Navigator.push(context, _push(w)); _load(); }

  // ── scaffold ──────────────────────────────────────────
  @override
  Widget build(BuildContext ctx) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: SystemUiOverlayStyle.light,
    child: Scaffold(
      backgroundColor: _bg,
      body: _tabBody(),
      bottomNavigationBar: _nav(),
    ),
  );

  Widget _tabBody() { switch (_tab) {
    case 1: return const MyDemandsScreen();
    case 2: return const MyOrdersScreen();
    case 3: return const ProfileScreen(role: 'shop_owner');
    default: return _home();
  } }

  // ══════════════════════════════════════════════════════
  //  HOME
  // ══════════════════════════════════════════════════════
  Widget _home() {
    return ColoredBox(
      color: _bg,
      child: RefreshIndicator(
        onRefresh: _load,
        color: _blue2,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── gradient header (topBar + stats card inside) ──
              SlideTransition(
                position: _hSlide,
                child: FadeTransition(
                  opacity: _hFade,
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [_c0, _c1, _c2, _c3],
                        stops: [0.0, 0.38, 0.72, 1.0],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(36),
                        bottomRight: Radius.circular(36),
                      ),
                    ),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned(top: -50, right: -40, child: _blob(190, Colors.white, .04)),
                        Positioned(top: 10,  right: 55,  child: _blob(60,  _c2,         .3)),
                        Positioned(top: 55,  left: 40,   child: _blob(30,  Colors.white, .06)),
                        Positioned(top: 120, left: -30,  child: _blob(120, _c3,         .25)),
                        Positioned(top: 130, right: 100, child: _blob(22,  Colors.white, .08)),
                        SafeArea(
                          bottom: false,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _topBar(),
                                const SizedBox(height: 20),
                                _animI(0, _overviewCard()),
                                const SizedBox(height: 8),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ── body content ──
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 108),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _locationSection(),
                    const SizedBox(height: 20),
                    _animI(1, _hero()),
                    const SizedBox(height: 20),
                    _animI(2, _actions()),
                    const SizedBox(height: 28),
                    _secRow('Active Demands', Icons.shopping_basket_rounded, _blue2,
                        count: _demands.length, onAll: () => setState(() => _tab = 1)),
                    const SizedBox(height: 14),
                    _animI(3, _demandsLane()),
                    const SizedBox(height: 28),
                    _secRow('Active Orders', Icons.local_shipping_rounded, _amb1,
                        count: _orders.length, onAll: () => setState(() => _tab = 2)),
                    const SizedBox(height: 14),
                    if (_orders.isEmpty)
                      _animI(4, _empty('No active orders',
                          'Your placed orders will be tracked here.',
                          Icons.receipt_long_outlined, _amb1))
                    else
                      ...List.generate(_orders.length,
                          (i) => _animI(i + 4, _orderCard(_orders[i]))),
                    if (_unrated.isNotEmpty) ...[
                      const SizedBox(height: 28),
                      _animI(7, _secRow('Pending Reviews', Icons.star_outline_rounded,
                          const Color(0xFFE65100), count: _unrated.length)),
                      const SizedBox(height: 6),
                      _animI(7, _ratingBanner()),
                      const SizedBox(height: 14),
                      ..._unrated.asMap().entries.map(
                          (e) => _animI(e.key + 8, _ratingCard(e.value))),
                    ],
                    const SizedBox(height: 24),
                    _animI(_unrated.isEmpty ? 7 : _unrated.length + 9, _tip()),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _animI(int i, Widget child) => AnimatedBuilder(
    animation: _lC,
    builder: (_, ch) => FadeTransition(opacity: _fd(i),
        child: SlideTransition(position: _sl(i), child: ch)),
    child: child,
  );

  Widget _blob(double sz, Color c, double op) =>
      Container(width: sz, height: sz,
          decoration: BoxDecoration(shape: BoxShape.circle, color: c.withOpacity(op)));

  // ══════════════════════════════════════════════════════
  //  TOP BAR  (minimal — lives on gradient)
  // ══════════════════════════════════════════════════════
  Widget _topBar() {
    return Row(children: [
      // avatar with first letter
      Container(
        width: 46, height: 46,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
              colors: [Color(0xFFFFD54F), Color(0xFFFF8C00)],
              begin: Alignment.topLeft, end: Alignment.bottomRight),
          border: Border.all(color: Colors.white.withOpacity(0.5), width: 2),
          boxShadow: [BoxShadow(color: Colors.orange.withOpacity(0.55),
              blurRadius: 14, offset: const Offset(0, 4))],
        ),
        child: Center(child: Text(
          widget.shopName.isNotEmpty ? widget.shopName[0].toUpperCase() : 'S',
          style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w900),
        )),
      ),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Assalamu Alaikum 👋',
            style: TextStyle(color: Colors.white54, fontSize: 11.5)),
        const SizedBox(height: 1),
        Text(widget.shopName,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white, fontSize: 17,
                fontWeight: FontWeight.w800, letterSpacing: -.4)),
      ])),
      _glassBtn(Icons.notifications_outlined, () =>
          Navigator.push(context, _push(const NotificationsScreen())),
          badge: _badge > 0 ? '$_badge' : null),
      const SizedBox(width: 8),
      _glassBtn(_busy ? Icons.hourglass_empty_rounded : Icons.refresh_rounded,
          _busy ? () {} : _load),
      const SizedBox(width: 8),
      _glassBtn(Icons.logout_rounded, _logout),
    ]);
  }

  Widget _glassBtn(IconData icon, VoidCallback onTap, {String? badge}) {
    return _Tap(onTap: onTap, child: Stack(clipBehavior: Clip.none, children: [
      ClipRRect(borderRadius: BorderRadius.circular(13),
        child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(width: 40, height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.14),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: Colors.white.withOpacity(0.25), width: 1),
            ),
            child: Icon(icon, color: Colors.white, size: 19),
          ),
        ),
      ),
      if (badge != null)
        Positioned(top: -3, right: -3,
          child: Container(
            padding: const EdgeInsets.all(3),
            constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
            decoration: const BoxDecoration(color: _amb2, shape: BoxShape.circle),
            child: Text(badge, textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w800)),
          )),
    ]));
  }

  // ══════════════════════════════════════════════════════
  //  OVERVIEW CARD — white card that straddles
  //  the gradient/bg boundary (overlap design)
  // ══════════════════════════════════════════════════════
  Widget _overviewCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.13),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.22), width: 1),
          ),
          child: Row(children: [
            _oStat(_stats['open_demands']   ?? 0, 'Open\nDemands', Colors.white, Icons.assignment_outlined),
            _vDiv(),
            _oStat(_stats['matched_demands']?? 0, 'Matched',       const Color(0xFF6EF5C0), Icons.handshake_outlined),
            _vDiv(),
            _oStat(_stats['active_orders']  ?? 0, 'Active\nOrders', const Color(0xFFFFD080), Icons.shopping_cart_outlined),
          ]),
        ),
      ),
    );
  }

  Widget _oStat(int val, String label, Color c, IconData icon) {
    return Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(width: 40, height: 40,
        decoration: BoxDecoration(
          color: c.withOpacity(0.15),
          shape: BoxShape.circle,
          border: Border.all(color: c.withOpacity(0.3), width: 1),
        ),
        child: Icon(icon, color: c, size: 19)),
      const SizedBox(height: 8),
      TweenAnimationBuilder<int>(
        tween: IntTween(begin: 0, end: val),
        duration: const Duration(milliseconds: 900),
        curve: Curves.easeOut,
        builder: (_, v, __) => Text('$v',
            style: TextStyle(color: c, fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: -.5)),
      ),
      const SizedBox(height: 3),
      Text(label, textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white.withOpacity(0.65), fontSize: 11, height: 1.35)),
    ]));
  }

  Widget _vDiv() => Container(width: 1, height: 56, color: Colors.white.withOpacity(0.18));

  // ══════════════════════════════════════════════════════
  //  LOCATION SECTION — always visible; two states
  // ══════════════════════════════════════════════════════
  Widget _locationSection() {
    return _Tap(
      onTap: () async {
        final r = await Navigator.push<LocationResult>(context, MaterialPageRoute(
          builder: (_) => LocationPickerScreen(
              title: _hasLoc ? 'Update Shop Location' : 'Set Shop Location',
              initialLat: _lat, initialLng: _lng)));
        if (r == null || !mounted) return;
        await ProfileService.saveLocation(r);
        _load();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: _hasLoc
              ? LinearGradient(colors: [_blue1.withOpacity(0.08), _blue2.withOpacity(0.04)])
              : LinearGradient(colors: [_amb1.withOpacity(0.13), _amb2.withOpacity(0.06)]),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: _hasLoc ? _blue2.withOpacity(0.3) : _amb2.withOpacity(0.35)),
        ),
        child: Row(children: [
          // icon
          Container(width: 46, height: 46,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: _hasLoc ? [_blue1, _blue2] : [_amb1, _amb2]),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(
                  color: (_hasLoc ? _blue2 : _amb2).withOpacity(0.4),
                  blurRadius: 12, offset: const Offset(0, 4))],
            ),
            child: Icon(
                _hasLoc ? Icons.location_on_rounded : Icons.location_off_rounded,
                color: Colors.white, size: 22)),
          const SizedBox(width: 14),
          // text
          Expanded(child: _hasLoc
              ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Shop Location',
                      style: TextStyle(fontWeight: FontWeight.w800,
                          fontSize: 12, color: AppColors.textGrey)),
                  const SizedBox(height: 2),
                  Text(
                    _locAddress.isNotEmpty ? _locAddress
                        : '${_lat?.toStringAsFixed(5)}, ${_lng?.toStringAsFixed(5)}',
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700,
                        fontSize: 13.5, color: AppColors.textDark)),
                ])
              : const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Set your shop location',
                      style: TextStyle(fontWeight: FontWeight.w800,
                          fontSize: 14, color: AppColors.textDark)),
                  SizedBox(height: 3),
                  Text('Required to find nearby suppliers',
                      style: TextStyle(fontSize: 12, color: AppColors.textGrey)),
                ])),
          // action button
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: _hasLoc ? [_blue1, _blue2] : [_amb1, _amb2]),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [BoxShadow(
                  color: (_hasLoc ? _blue2 : _amb2).withOpacity(0.35),
                  blurRadius: 8, offset: const Offset(0, 3))],
            ),
            child: Text(_hasLoc ? 'Change' : 'Set Now',
                style: const TextStyle(color: Colors.white,
                    fontWeight: FontWeight.w800, fontSize: 12))),
        ]),
      ),
    );
  }

  // ══════════════════════════════════════════════════════
  //  HERO CTA
  // ══════════════════════════════════════════════════════
  Widget _hero() {
    return _Tap(onTap: () => _go(const PostDemandScreen()), child: Container(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7C1A00), Color(0xFFD03800), Color(0xFFF06000), Color(0xFFFF9500)],
          stops: [0.0, 0.32, 0.68, 1.0],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        // only downward shadow — nothing bleeds upward toward the white card
        boxShadow: [
          BoxShadow(color: const Color(0xFFD03800).withOpacity(0.42),
              blurRadius: 22, spreadRadius: -2, offset: const Offset(0, 10)),
        ],
        // thin top-edge highlight simulates light hitting the surface — no white overlay
        border: Border.all(color: Colors.white.withOpacity(0.12), width: 1),
      ),
      child: Stack(children: [
        // watermark
        Positioned(right: -10, bottom: -16,
            child: Icon(Icons.storefront_rounded, size: 105, color: Colors.white.withOpacity(.07))),
        Row(children: [
          Container(width: 58, height: 58,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.2),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withOpacity(.35), width: 1.5),
            ),
            child: const Icon(Icons.add_shopping_cart_rounded, color: Colors.white, size: 28)),
          const SizedBox(width: 16),
          const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Need stock for your shop?',
                style: TextStyle(color: Colors.white, fontSize: 17,
                    fontWeight: FontWeight.w900, letterSpacing: -.3)),
            SizedBox(height: 5),
            Text('Post a demand — suppliers near you respond instantly.',
                style: TextStyle(color: Colors.white70, fontSize: 12.5, height: 1.4)),
          ])),
          const SizedBox(width: 10),
          Container(width: 36, height: 36,
            decoration: BoxDecoration(
                color: Colors.white.withOpacity(.2), shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withOpacity(.3), width: 1)),
            child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18)),
        ]),
      ]),
    ));
  }

  // ══════════════════════════════════════════════════════
  //  QUICK ACTIONS — 3 tall gradient cards in a row
  // ══════════════════════════════════════════════════════
  Widget _actions() {
    return Row(children: [
      Expanded(child: _aBtn('Post\nDemand',   Icons.post_add_rounded,       [_ind1, _ind2],  () => _go(const PostDemandScreen()))),
      const SizedBox(width: 12),
      Expanded(child: _aBtn('Browse\nStocks', Icons.manage_search_rounded,  [_teal1, _teal2],() => _go(const BrowseStocksScreen()))),
      const SizedBox(width: 12),
      Expanded(child: _aBtn('My\nOrders',     Icons.local_shipping_rounded, [_grn1, _grn2],  () => _go(const MyOrdersScreen()))),
    ]);
  }

  Widget _aBtn(String label, IconData icon, List<Color> g, VoidCallback fn) {
    return _Tap(onTap: fn, child: Container(
      height: 108,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: g, begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(color: g.last.withOpacity(.5), blurRadius: 20, spreadRadius: -3, offset: const Offset(0, 9)),
          BoxShadow(color: g.last.withOpacity(.18), blurRadius: 5, offset: const Offset(0, 2)),
        ],
      ),
      child: Stack(children: [
        Positioned.fill(child: ClipRRect(borderRadius: BorderRadius.circular(22),
          child: Align(alignment: Alignment.topCenter,
            child: FractionallySizedBox(heightFactor: .45, widthFactor: 1,
              child: Container(decoration: BoxDecoration(
                gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  colors: [Colors.white.withOpacity(.32), Colors.transparent]))))))),
        Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(width: 44, height: 44,
            decoration: BoxDecoration(color: Colors.white.withOpacity(.2), shape: BoxShape.circle),
            child: Icon(icon, color: Colors.white, size: 22)),
          const SizedBox(height: 9),
          Text(label, textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 11.5,
                  fontWeight: FontWeight.w700, height: 1.3)),
        ])),
      ]),
    ));
  }

  // ══════════════════════════════════════════════════════
  //  SECTION ROW
  // ══════════════════════════════════════════════════════
  Widget _secRow(String title, IconData icon, Color c,
      {VoidCallback? onAll, int count = 0}) {
    return Row(children: [
      Container(width: 34, height: 34,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [c.withOpacity(.18), c.withOpacity(.07)]),
          borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: c, size: 17)),
      const SizedBox(width: 10),
      Text(title, style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800,
          color: AppColors.textDark, letterSpacing: -.3)),
      if (count > 0) ...[
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(color: c.withOpacity(.14), borderRadius: BorderRadius.circular(20)),
          child: Text('$count', style: TextStyle(color: c, fontSize: 11, fontWeight: FontWeight.w800))),
      ],
      const Spacer(),
      if (onAll != null)
        _Tap(onTap: onAll, child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
          decoration: BoxDecoration(
            color: c.withOpacity(.1), borderRadius: BorderRadius.circular(20),
            border: Border.all(color: c.withOpacity(.3), width: 1)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text('See All', style: TextStyle(color: c, fontWeight: FontWeight.w700, fontSize: 12)),
            const SizedBox(width: 3),
            Icon(Icons.arrow_forward_ios_rounded, size: 10, color: c),
          ]),
        )),
    ]);
  }

  // ══════════════════════════════════════════════════════
  //  DEMANDS LANE — horizontal scroll cards  ← NEW ARCH
  // ══════════════════════════════════════════════════════
  Widget _demandsLane() {
    if (_demands.isEmpty) {
      return _empty('No active demands',
          'Post a demand — nearby suppliers will respond.', Icons.inbox_rounded, _blue1);
    }
    return SizedBox(
      height: 136,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        itemCount: _demands.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) {
          if (i == _demands.length) return _addDemandCard();
          return _demandHCard(_demands[i]);
        },
      ),
    );
  }

  Widget _demandHCard(Map<String, dynamic> d) {
    final matched = d['status'] == 'matched';
    final c = matched ? _amb2 : _blue2;
    final cDark = matched ? _amb1 : _blue1;
    return _Tap(
      onTap: () async {
        await Navigator.push(context, _push(DemandDetailScreen(demandId: d['demand_id'] as int)));
        _load();
      },
      child: Container(
        width: 158,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: cDark.withOpacity(.12), blurRadius: 18, offset: const Offset(0, 6)),
            BoxShadow(color: Colors.black.withOpacity(.04), blurRadius: 4, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(width: 34, height: 34,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [c.withOpacity(.2), c.withOpacity(.08)]),
                borderRadius: BorderRadius.circular(10)),
              child: Icon(Icons.shopping_basket_rounded, color: c, size: 17)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                  color: c.withOpacity(.14), borderRadius: BorderRadius.circular(6)),
              child: Text(matched ? 'MATCHED' : 'OPEN',
                  style: TextStyle(color: c, fontWeight: FontWeight.w900, fontSize: 9.5))),
          ]),
          const Spacer(),
          Text('${d['product_name'] ?? ''}',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.textDark),
              maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 3),
          Text('${d['quantity']} ${d['unit']}',
              style: TextStyle(color: AppColors.textGrey.withOpacity(.8), fontSize: 12)),
        ]),
      ),
    );
  }

  Widget _addDemandCard() {
    return _Tap(
      onTap: () => _go(const PostDemandScreen()),
      child: Container(
        width: 110,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [_blue1.withOpacity(.08), _blue2.withOpacity(.04)]),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _blue2.withOpacity(.25), width: 1.5),
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(width: 40, height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [_blue1, _blue2]),
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: _blue2.withOpacity(.4), blurRadius: 12, offset: const Offset(0, 4))],
            ),
            child: const Icon(Icons.add_rounded, color: Colors.white, size: 22)),
          const SizedBox(height: 10),
          const Text('Post New\nDemand', textAlign: TextAlign.center,
              style: TextStyle(color: _blue1, fontWeight: FontWeight.w700, fontSize: 11.5, height: 1.35)),
        ]),
      ),
    );
  }

  // ══════════════════════════════════════════════════════
  //  ORDER CARD  (vertical list, refined)
  // ══════════════════════════════════════════════════════
  Widget _orderCard(Map<String, dynamic> o) {
    final c = o['sc'] as Color? ?? _blue2;
    final ic = o['ic'] as IconData? ?? Icons.shopping_bag_outlined;
    final lb = o['lb'] as String? ?? '';
    final price = o['price'] as num? ?? 0;
    return _Tap(
      onTap: () => Navigator.push(context, _push(OrderStatusScreen(order: o))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: _c1.withOpacity(.08), blurRadius: 18, offset: const Offset(0, 6)),
            BoxShadow(color: Colors.black.withOpacity(.03), blurRadius: 4, offset: const Offset(0, 2)),
          ],
        ),
        child: Row(children: [
          Container(width: 52, height: 52,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [c.withOpacity(.2), c.withOpacity(.08)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(16)),
            child: Icon(ic, color: c, size: 24)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(o['product'] as String? ?? '',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textDark),
                maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 3),
            Text('${o['qty']}  ·  ${o['supplier']}',
                style: const TextStyle(fontSize: 12, color: AppColors.textGrey),
                maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [c.withOpacity(.18), c.withOpacity(.07)]),
                borderRadius: BorderRadius.circular(8)),
              child: Text(lb.toUpperCase(),
                  style: TextStyle(color: c, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: .5))),
          ])),
          Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text('৳${price.toStringAsFixed(0)}',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: c)),
            const SizedBox(height: 4),
            Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400, size: 20),
          ]),
        ]),
      ),
    );
  }

  // ══════════════════════════════════════════════════════
  //  EMPTY STATE
  // ══════════════════════════════════════════════════════
  Widget _empty(String t, String s, IconData ic, Color c) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 18),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: _c1.withOpacity(.06), blurRadius: 16, offset: const Offset(0, 5))],
      ),
      child: Row(children: [
        Container(width: 50, height: 50,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [c.withOpacity(.14), c.withOpacity(.05)]),
            borderRadius: BorderRadius.circular(14)),
          child: Icon(ic, color: c.withOpacity(.45), size: 24)),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(t, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.textDark)),
          const SizedBox(height: 4),
          Text(s, style: const TextStyle(fontSize: 12, color: AppColors.textGrey, height: 1.45)),
        ])),
      ]),
    );
  }

  // ══════════════════════════════════════════════════════
  //  PENDING RATINGS
  // ══════════════════════════════════════════════════════
  Widget _ratingBanner() => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      gradient: LinearGradient(colors: [
        const Color(0xFFE65100).withOpacity(.1),
        const Color(0xFFFF9500).withOpacity(.05)]),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFFF9500).withOpacity(.3)),
    ),
    child: Row(children: [
      Container(width: 38, height: 38,
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFFE65100), Color(0xFFFF9500)]),
          borderRadius: BorderRadius.circular(10)),
        child: const Icon(Icons.star_rounded, color: Colors.white, size: 18)),
      const SizedBox(width: 12),
      const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Rate your suppliers', style: TextStyle(fontWeight: FontWeight.w800,
            fontSize: 13, color: Color(0xFFAD4A0A))),
        SizedBox(height: 2),
        Text('Your feedback helps other shop owners find the best suppliers.',
            style: TextStyle(fontSize: 11.5, color: AppColors.textGrey, height: 1.4)),
      ])),
    ]),
  );

  Widget _ratingCard(Map<String, dynamic> o) {
    final supplier = o['stockholder_name'] as String? ?? '';
    final product  = '${o['product_name'] ?? ''} - ${o['variant_name'] ?? ''}';
    final total    = (o['total_price'] as num?)?.toDouble() ?? 0.0;
    final initials = supplier.isNotEmpty
        ? supplier.trim().split(' ').map((s) => s[0]).take(2).join().toUpperCase()
        : 'S';
    return _Tap(
      onTap: () async {
        final result = await Navigator.push(context,
            _push(RateSupplierScreen(order: {
              ...o,
              'supplier': supplier,
              'product': product,
              'qty': '${(o['quantity'] as num?)?.toStringAsFixed(1) ?? '-'} ${o['unit'] ?? ''}',
              'price': total,
            })));
        if (result == true) _load();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(color: const Color(0xFFE65100).withOpacity(.08),
                blurRadius: 16, offset: const Offset(0, 5)),
            BoxShadow(color: Colors.black.withOpacity(.03),
                blurRadius: 4, offset: const Offset(0, 2)),
          ],
        ),
        child: Row(children: [
          Container(width: 46, height: 46,
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Color(0xFFE65100), Color(0xFFFF9500)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight),
              shape: BoxShape.circle,
            ),
            child: Center(child: Text(initials,
                style: const TextStyle(color: Colors.white,
                    fontWeight: FontWeight.w900, fontSize: 14)))),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(supplier, style: const TextStyle(fontWeight: FontWeight.w800,
                fontSize: 13.5, color: AppColors.textDark),
                maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text(product, style: const TextStyle(fontSize: 12, color: AppColors.textGrey),
                maxLines: 1, overflow: TextOverflow.ellipsis),
          ])),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Color(0xFFE65100), Color(0xFFFF9500)]),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: const Color(0xFFFF9500).withOpacity(.4),
                  blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.star_rounded, color: Colors.white, size: 14),
              SizedBox(width: 5),
              Text('Rate', style: TextStyle(color: Colors.white,
                  fontWeight: FontWeight.w800, fontSize: 12)),
            ]),
          ),
        ]),
      ),
    );
  }

  // ══════════════════════════════════════════════════════
  //  TIP
  // ══════════════════════════════════════════════════════
  Widget _tip() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [_c1.withOpacity(.09), _c2.withOpacity(.04)]),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _c2.withOpacity(.18)),
      ),
      child: Row(children: [
        Container(width: 36, height: 36,
          decoration: BoxDecoration(color: _blue2.withOpacity(.14), shape: BoxShape.circle),
          child: const Icon(Icons.lightbulb_rounded, color: _blue2, size: 18)),
        const SizedBox(width: 12),
        const Expanded(child: Text(
          'Tip: Post your demand once — multiple suppliers will compete on price for you.',
          style: TextStyle(fontSize: 12.5, color: AppColors.textDark, height: 1.5))),
      ]),
    );
  }

  // ══════════════════════════════════════════════════════
  //  BOTTOM NAV
  // ══════════════════════════════════════════════════════
  Widget _nav() {
    const items = [
      (Icons.home_rounded,         Icons.home_outlined,          'Home'),
      (Icons.list_alt_rounded,     Icons.list_alt_outlined,      'Demands'),
      (Icons.receipt_long_rounded, Icons.receipt_long_outlined,  'Orders'),
      (Icons.person_rounded,       Icons.person_outline_rounded, 'Profile'),
    ];
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
        boxShadow: [
          BoxShadow(color: _c1.withOpacity(.14), blurRadius: 28, offset: const Offset(0, -8)),
          BoxShadow(color: Colors.black.withOpacity(.04), blurRadius: 6, offset: const Offset(0, -2)),
        ],
      ),
      child: SafeArea(top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (i) {
              final sel = _tab == i;
              return _Tap(
                onTap: () { HapticFeedback.lightImpact(); setState(() => _tab = i); },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeInOut,
                  padding: EdgeInsets.symmetric(horizontal: sel ? 18 : 14, vertical: 9),
                  decoration: BoxDecoration(
                    gradient: sel ? const LinearGradient(
                      colors: [_c0, _c1, _c3],
                      begin: Alignment.topLeft, end: Alignment.bottomRight) : null,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: sel ? [BoxShadow(color: _c1.withOpacity(.45),
                        blurRadius: 14, offset: const Offset(0, 5))] : null,
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Icon(sel ? items[i].$1 : items[i].$2,
                        key: ValueKey('n${i}_$sel'),
                        color: sel ? Colors.white : AppColors.textGrey, size: 22)),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 260), curve: Curves.easeInOut,
                      child: sel ? Row(children: [
                        const SizedBox(width: 6),
                        Text(items[i].$3,
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                      ]) : const SizedBox.shrink()),
                  ]),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════
  //  LOGOUT
  // ══════════════════════════════════════════════════════
  Future<void> _logout() async {
    HapticFeedback.mediumImpact();
    final yes = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Text('Log out?', style: TextStyle(fontWeight: FontWeight.w800)),
        content: const Text('You will need to sign in again.',
            style: TextStyle(color: AppColors.textGrey)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.errorRed,
                foregroundColor: Colors.white, elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: const Text('Log out', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (yes == true) {
      await AuthService.logout();
      if (mounted) Navigator.pushReplacementNamed(context, '/welcome');
    }
  }
}
