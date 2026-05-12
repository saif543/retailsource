import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/auth_service.dart';
import '../../services/stock_service.dart';
import '../../services/order_service.dart';
import '../../services/profile_service.dart';
import '../../services/notification_service.dart';
import '../../services/location_service.dart';
import '../../config/language.dart';
import '../shared/notifications_screen.dart';
import '../shared/profile_screen.dart';
import '../shared/location_picker_screen.dart';
import 'post_stock_screen.dart';
import 'my_stock_screen.dart';
import 'order_inbox_screen.dart';
import 'order_detail_screen.dart';
import 'nearby_demands_screen.dart';

// ── palette ───────────────────────────────────────────────────────────────────
const _sp0 = Color(0xFF16002E);
const _sp1 = Color(0xFF3B0D6B);
const _sp2 = Color(0xFF7B2FD4);
const _sp3 = Color(0xFFBB6BF7);
const _bg  = Color(0xFFF8F0FF);
const _txt = Color(0xFF212121);
const _sub = Color(0xFF757575);

const _amb1 = Color(0xFFAD4A0A);
const _amb2 = Color(0xFFF5981E);
const _red1 = Color(0xFF7B1C1C);
const _red2 = Color(0xFFEF5350);
const _ind1 = Color(0xFF2D238A);
const _ind2 = Color(0xFF7C6FF5);

// ── tap wrapper ───────────────────────────────────────────────────────────────
class _Tap extends StatefulWidget {
  final Widget child; final VoidCallback onTap;
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
class StockholderDashboard extends StatefulWidget {
  final String companyName;
  final String userName;
  const StockholderDashboard({
    super.key,
    this.companyName = 'My Warehouse',
    this.userName = 'Stockholder',
  });
  @override State<StockholderDashboard> createState() => _SD();
}

class _SD extends State<StockholderDashboard> with TickerProviderStateMixin {
  int _tab = 0;
  Map<String, int> _stats = {'active_stock': 0, 'new_orders': 0, 'delivered': 0};
  List<Map<String, dynamic>> _newOrders = [], _activeOrders = [];
  int _badge = 0;
  bool _busy = false, _hasLoc = true;
  double? _lat, _lng;
  String _locAddress = '';
  String _companyName = '';
  String _userName = '';

  late final _hC = AnimationController(vsync: this, duration: const Duration(milliseconds: 750));
  late final _lC = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
  late final _pulseC = AnimationController(vsync: this, duration: const Duration(milliseconds: 850));
  late final _hFade = CurvedAnimation(parent: _hC, curve: Curves.easeOut);
  late final _hSlide = Tween<Offset>(begin: const Offset(0, .04), end: Offset.zero)
      .animate(CurvedAnimation(parent: _hC, curve: Curves.easeOut));

  Animation<double> _fd(int i) => Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
      parent: _lC, curve: Interval((i * .1).clamp(0, .7), ((i * .1) + .45).clamp(0, 1), curve: Curves.easeOut)));
  Animation<Offset> _sl(int i) => Tween<Offset>(begin: const Offset(0, .08), end: Offset.zero)
      .animate(CurvedAnimation(parent: _lC,
        curve: Interval((i * .1).clamp(0, .7), ((i * .1) + .45).clamp(0, 1), curve: Curves.easeOut)));

  @override
  void initState() { super.initState(); appLang.addListener(_onLangChange); _hC.forward(); _load(); }
  void _onLangChange() => setState(() {});
  @override
  void dispose() { appLang.removeListener(_onLangChange); _hC.dispose(); _lC.dispose(); _pulseC.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() => _busy = true);
    _lC.reset();
    try {
      final fs = StockService.getDashboard();
      final fo = OrderService.getIncomingOrders();
      final fp = ProfileService.getProfile();
      final fn = NotificationService.getNotifications();
      final stats = await fs; final orders = await fo;
      final profile = await fp; final notifs = await fn;
      if (!mounted) return;
      final prof = (profile?['profile'] as Map?) ?? {};
      final lat = (prof['lat'] as num?)?.toDouble();
      final lng = (prof['lng'] as num?)?.toDouble();
      final addrParts = <String>[];
      final area = (prof['area'] as String?) ?? '';
      final dist = (prof['district'] as String?) ?? '';
      if (area.isNotEmpty) addrParts.add(area);
      if (dist.isNotEmpty && dist != area) addrParts.add(dist);
      setState(() {
        _stats = stats;
        _newOrders = orders.where((o) => o['status'] == 'pending').toList();
        _activeOrders = orders.where((o) =>
            o['status'] == 'accepted' || o['status'] == 'out_for_delivery').toList();
        final hasOFD = _activeOrders.any((o) => o['status'] == 'out_for_delivery');
        if (hasOFD) { if (!_pulseC.isAnimating) _pulseC.repeat(reverse: true); }
        else { _pulseC.stop(); _pulseC.reset(); }
        _badge = notifs.unread;
        _lat = lat; _lng = lng;
        _hasLoc = lat != null && lat != 0.0 && lng != null && lng != 0.0;
        _locAddress = addrParts.join(', ');
        _companyName = (profile?['profile'] as Map?)?['company_name'] as String?
            ?? (profile?['name'] as String?) ?? widget.companyName;
        _userName = (profile?['name'] as String?) ?? widget.userName;
        _busy = false;
      });
      _lC.forward();
    } catch (_) {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _setLocation() async {
    final result = await Navigator.push<LocationResult>(
      context,
      MaterialPageRoute(builder: (_) => LocationPickerScreen(
        title: 'Set Warehouse Location',
        initialLat: _lat, initialLng: _lng,
      )),
    );
    if (result == null || !mounted) return;
    await ProfileService.saveLocation(result);
    _load();
  }

  Future<void> _accept(Map<String, dynamic> o) async {
    final orderId = o['order_id'] as int?;
    if (orderId == null) return;
    HapticFeedback.mediumImpact();
    final result = await OrderService.acceptOrder(orderId);
    if (!mounted) return;
    if (result.ok) {
      setState(() => _newOrders.remove(o));
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => StockholderOrderDetailScreen(order: {...o, 'status': 'accepted'}),
      )).then((_) => _load());
    } else {
      _snack(result.error ?? 'Failed to accept order', error: true);
    }
  }

  Future<void> _decline(Map<String, dynamic> o) async {
    final orderId = o['order_id'] as int?;
    if (orderId == null) return;
    HapticFeedback.mediumImpact();
    final result = await OrderService.declineOrder(orderId);
    if (!mounted) return;
    if (result.ok) {
      setState(() => _newOrders.remove(o));
    } else {
      _snack(result.error ?? 'Failed to decline order', error: true);
    }
  }

  Future<void> _logout() async {
    HapticFeedback.mediumImpact();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 56, height: 56,
              decoration: BoxDecoration(
                color: _red2.withOpacity(.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.logout_rounded, color: _red2, size: 28)),
            const SizedBox(height: 16),
            Text(S('log_out_title'),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: _txt)),
            const SizedBox(height: 8),
            Text(S('log_out_subtitle'),
                textAlign: TextAlign.center,
                style: const TextStyle(color: _sub, fontSize: 13)),
            const SizedBox(height: 24),
            Row(children: [
              Expanded(child: _Tap(onTap: () => Navigator.pop(context, false),
                child: Container(height: 46,
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFE0E0E0)),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(child: Text(S('cancel'),
                      style: const TextStyle(fontWeight: FontWeight.w700, color: _sub)))))),
              const SizedBox(width: 12),
              Expanded(child: _Tap(onTap: () => Navigator.pop(context, true),
                child: Container(height: 46,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [_red1, _red2]),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(child: Text(S('log_out'),
                      style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.white)))))),
            ]),
          ]),
        ),
      ),
    );
    if (confirm == true && mounted) {
      await ProfileService.clearCachedLocation();
      await AuthService.logout();
      if (mounted) Navigator.pushReplacementNamed(context, '/welcome');
    }
  }

  void _snack(String msg, {bool error = false}) =>
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: error ? _red1 : _sp1,
      content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600))));

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: SystemUiOverlayStyle.light,
    child: Scaffold(
      backgroundColor: _bg,
      body: _buildTabBody(),
      bottomNavigationBar: _buildBottomNav(),
    ),
  );

  Widget _buildTabBody() {
    switch (_tab) {
      case 1: return const MyStockScreen();
      case 2: return const OrderInboxScreen();
      case 3: return const ProfileScreen(role: 'stockholder');
      default: return SafeArea(bottom: false,
        child: Stack(fit: StackFit.expand, children: [
          Column(children: [
            _buildHeader(),
            Expanded(child: RefreshIndicator(
              color: _sp2,
              onRefresh: _load,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  if (!_hasLoc) ...[_buildLocationBanner(), const SizedBox(height: 14)],
                  _buildCTA(),
                  const SizedBox(height: 20),
                  _sectionHeader(S('quick_actions')),
                  const SizedBox(height: 12),
                  _buildQuickActions(),
                  const SizedBox(height: 24),
                  _sectionRow(S('active_orders'), '${_activeOrders.length} in progress', () => setState(() => _tab = 2)),
                  const SizedBox(height: 10),
                  if (_activeOrders.isEmpty)
                    _emptyCard(Icons.local_shipping_outlined, 'No active deliveries')
                  else ..._activeOrders.asMap().entries.map((e) =>
                      FadeTransition(opacity: _fd(e.key + 2),
                        child: SlideTransition(position: _sl(e.key + 2),
                          child: _activeOrderCard(e.value)))),
                  const SizedBox(height: 20),
                  _sectionRow(S('new_orders'), '${_newOrders.length} pending', () => setState(() => _tab = 2)),
                  const SizedBox(height: 12),
                  if (_newOrders.isEmpty)
                    _emptyCard(Icons.inbox_rounded, 'No new orders right now')
                  else ..._newOrders.asMap().entries.map((e) =>
                      FadeTransition(opacity: _fd(e.key),
                        child: SlideTransition(position: _sl(e.key),
                          child: _newOrderCard(e.value)))),
                  const SizedBox(height: 8),
                  _tipCard(),
                ]),
              ),
            )),
          ]),
          if (_activeOrders.isNotEmpty)
            Positioned(right: 20, bottom: 20, child: _deliveryFab()),
        ]),
      );
    }
  }

  // ── header ────────────────────────────────────────────────────────────────
  Widget _buildHeader() => FadeTransition(opacity: _hFade,
    child: SlideTransition(position: _hSlide,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [_sp0, _sp1, _sp2, _sp3],
            stops: [0.0, 0.35, 0.7, 1.0],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(32), bottomRight: Radius.circular(32),
          ),
        ),
        child: Stack(children: [
          Positioned(top: -20, right: -30, child: _blob(140, Colors.white, .04)),
          Positioned(top: 14, right: 50,   child: _blob(50, _sp3, .25)),
          SafeArea(bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(children: [
                Row(children: [
                  Container(width: 50, height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(.18),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(.25)),
                    ),
                    child: const Icon(Icons.warehouse_rounded, color: Colors.white, size: 26)),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(_hasLoc && _locAddress.isNotEmpty ? _locAddress : 'Warehouse',
                        style: const TextStyle(color: Colors.white60, fontSize: 12.5),
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(_companyName.isEmpty ? widget.companyName : _companyName,
                        style: const TextStyle(color: Colors.white,
                            fontSize: 18, fontWeight: FontWeight.w800),
                        overflow: TextOverflow.ellipsis),
                  ])),
                  _circleBtn(Icons.notifications_outlined, _badge > 0 ? '$_badge' : null,
                      () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen()))),
                  const SizedBox(width: 8),
                  _circleBtn(_busy ? Icons.hourglass_top_rounded : Icons.refresh_rounded, null,
                      _busy ? null : _load),
                  const SizedBox(width: 8),
                  _circleBtn(Icons.logout_rounded, null, _logout),
                ]),
                const SizedBox(height: 20),
                Row(children: [
                  _statTile('${_stats['active_stock']}', 'Active\nStock', Icons.inventory_2_outlined),
                  const SizedBox(width: 10),
                  _statTile('${_stats['new_orders']}', 'New\nOrders', Icons.inbox_rounded),
                  const SizedBox(width: 10),
                  _statTile('${_stats['delivered']}', 'Delivered', Icons.check_circle_outline),
                ]),
                if (_hasLoc && _locAddress.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _Tap(onTap: _setLocation,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withOpacity(.2)),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.edit_location_alt_rounded, color: Colors.white70, size: 14),
                        const SizedBox(width: 6),
                        Flexible(child: Text(_locAddress,
                            style: const TextStyle(color: Colors.white70, fontSize: 12),
                            overflow: TextOverflow.ellipsis)),
                        const SizedBox(width: 6),
                        const Text('Change', style: TextStyle(color: Colors.white,
                            fontSize: 11.5, fontWeight: FontWeight.w700)),
                      ]),
                    )),
                ],
              ]),
            ),
          ),
        ]),
      ),
    ),
  );

  Widget _circleBtn(IconData icon, String? badge, VoidCallback? onTap) => _Tap(
    onTap: onTap ?? () {},
    child: Stack(clipBehavior: Clip.none, children: [
      Container(width: 40, height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(.18), shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(.25)),
        ),
        child: Icon(icon, color: Colors.white, size: 20)),
      if (badge != null && badge != '0')
        Positioned(top: -2, right: -2,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(color: _amb2, shape: BoxShape.circle),
            constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
            child: Text(badge, textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)))),
    ]),
  );

  Widget _statTile(String count, String label, IconData icon) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(.2)),
      ),
      child: Column(children: [
        Icon(icon, color: Colors.white70, size: 18),
        const SizedBox(height: 5),
        Text(count, style: const TextStyle(color: Colors.white,
            fontSize: 22, fontWeight: FontWeight.w900)),
        const SizedBox(height: 2),
        Text(label, textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white60, fontSize: 10.5, height: 1.2)),
      ]),
    ),
  );

  // ── location banner ───────────────────────────────────────────────────────
  Widget _buildLocationBanner() => _Tap(onTap: _setLocation,
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _amb2.withOpacity(.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _amb2.withOpacity(.4)),
      ),
      child: Row(children: [
        Container(width: 44, height: 44,
          decoration: BoxDecoration(
            color: _amb2.withOpacity(.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.location_off_rounded, color: _amb2, size: 22)),
        const SizedBox(width: 12),
        const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Set Warehouse Location', style: TextStyle(
              fontWeight: FontWeight.w800, fontSize: 14, color: _txt)),
          SizedBox(height: 2),
          Text('Required to appear in nearby shop searches and see demands',
              style: TextStyle(fontSize: 12, color: _sub)),
        ])),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [_amb1, _amb2]),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Text('Set Now', style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12))),
      ]),
    ),
  );

  // ── CTA post stock card ───────────────────────────────────────────────────
  Widget _buildCTA() => _Tap(onTap: () async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => const PostStockScreen()));
    _load();
  },
    child: Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_sp0, _sp1, _sp2, _sp3],
          stops: [0, .35, .7, 1],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: _sp3.withOpacity(.35),
            blurRadius: 20, spreadRadius: -4, offset: const Offset(0, 10))],
      ),
      child: Stack(children: [
        Positioned.fill(child: ClipRRect(borderRadius: BorderRadius.circular(20),
          child: Align(alignment: Alignment.topCenter,
            child: FractionallySizedBox(heightFactor: .5, widthFactor: 1,
              child: Container(decoration: BoxDecoration(
                gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  colors: [Colors.white.withOpacity(.12), Colors.transparent]))))))),
        Row(children: [
          Container(width: 56, height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(.25)),
            ),
            child: const Icon(Icons.add_box_rounded, color: Colors.white, size: 30)),
          const SizedBox(width: 14),
          const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Got stock to sell?', style: TextStyle(color: Colors.white,
                fontSize: 17, fontWeight: FontWeight.w800)),
            SizedBox(height: 3),
            Text('Post stock — nearby shops find you instantly',
                style: TextStyle(color: Colors.white70, fontSize: 12.5)),
          ])),
          Container(width: 32, height: 32,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.2), shape: BoxShape.circle),
            child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 16)),
        ]),
      ]),
    ),
  );

  // ── quick actions ─────────────────────────────────────────────────────────
  Widget _buildQuickActions() {
    final actions = <(String, IconData, List<Color>, VoidCallback)>[
      (S('post_stock_action'), Icons.add_box_rounded, [_sp1, _sp3], () async {
        await Navigator.push(context, MaterialPageRoute(builder: (_) => const PostStockScreen()));
        _load();
      }),
      (S('my_stock_action'), Icons.inventory_2_rounded, [Color(0xFF0E4470), Color(0xFF2196F3)], () async {
        await Navigator.push(context, MaterialPageRoute(builder: (_) => const MyStockScreen()));
        _load();
      }),
      (S('orders_action'), Icons.receipt_long_rounded, [_amb1, _amb2], () async {
        await Navigator.push(context, MaterialPageRoute(builder: (_) => const OrderInboxScreen()));
        _load();
      }),
      (S('nearby_demands_action'), Icons.near_me_rounded, [_ind1, _ind2], () async {
        await Navigator.push(context, MaterialPageRoute(builder: (_) => const NearbyDemandsScreen()));
      }),
    ];
    return Row(children: actions.map((a) => Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: _Tap(onTap: a.$4, child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(.05),
                blurRadius: 8, offset: const Offset(0, 3))],
          ),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(width: 40, height: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: a.$3,
                    begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: a.$3.last.withOpacity(.35),
                    blurRadius: 8, offset: const Offset(0, 3))],
              ),
              child: Icon(a.$2, color: Colors.white, size: 20)),
            const SizedBox(height: 8),
            Text(a.$1, textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 10.5,
                    fontWeight: FontWeight.w700, color: _txt, height: 1.2)),
          ]),
        )),
      ),
    )).toList());
  }

  // ── section helpers ───────────────────────────────────────────────────────
  Widget _sectionHeader(String t) => Text(t,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: _txt));

  Widget _sectionRow(String title, String badge, VoidCallback onMore) => Row(children: [
    Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: _txt)),
    const Spacer(),
    _Tap(onTap: onMore, child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _sp3.withOpacity(.12), borderRadius: BorderRadius.circular(20)),
      child: Text(badge,
          style: const TextStyle(color: _sp2, fontWeight: FontWeight.w800, fontSize: 11.5)))),
  ]);

  Widget _emptyCard(IconData icon, String msg) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(.04), blurRadius: 8, offset: const Offset(0, 2))]),
    child: Row(children: [
      Icon(icon, color: _sub, size: 22),
      const SizedBox(width: 12),
      Text(msg, style: const TextStyle(color: _sub)),
    ]),
  );

  // ── new order card ────────────────────────────────────────────────────────
  Widget _newOrderCard(Map<String, dynamic> o) {
    final shop = (o['shop'] as String?) ?? 'Shop';
    final initials = shop.split(' ').where((s) => s.isNotEmpty).take(2).map((s) => s[0]).join();
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _amb2.withOpacity(.3)),
        boxShadow: [BoxShadow(color: _amb2.withOpacity(.1),
            blurRadius: 14, offset: const Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
          child: Row(children: [
            Container(width: 40, height: 40,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [_sp1, _sp3],
                    begin: Alignment.topLeft, end: Alignment.bottomRight),
                shape: BoxShape.circle),
              child: Center(child: Text(initials.isEmpty ? '?' : initials,
                  style: const TextStyle(color: Colors.white,
                      fontWeight: FontWeight.w900, fontSize: 14)))),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(shop, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: _txt)),
              Text('${o['shopName'] ?? ''} • ${o['area'] ?? ''}',
                  style: const TextStyle(color: _sub, fontSize: 12)),
            ])),
            Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [_amb1, _amb2]),
                borderRadius: BorderRadius.circular(8)),
              child: const Text('NEW', style: TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w900, fontSize: 10))),
          ]),
        ),
        Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: _bg, borderRadius: BorderRadius.circular(12)),
          child: Row(children: [
            Expanded(child: Text((o['product'] as String?) ?? '',
                style: const TextStyle(fontWeight: FontWeight.w800, color: _txt))),
            Text('${o['qty']}',
                style: const TextStyle(fontWeight: FontWeight.w700, color: _sub)),
            const SizedBox(width: 10),
            Text('৳${(o['price'] as num?)?.toStringAsFixed(0) ?? '0'}',
                style: const TextStyle(color: _sp2, fontWeight: FontWeight.w900, fontSize: 15)),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          child: Row(children: [
            Expanded(child: _Tap(onTap: () => _accept(o).then((_) => _load()),
              child: Container(height: 42,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [_sp1, _sp3]),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: _sp3.withOpacity(.3),
                      blurRadius: 8, offset: const Offset(0, 3))],
                ),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.check_rounded, color: Colors.white, size: 16),
                  const SizedBox(width: 6),
                  Text(S('accept'), style: const TextStyle(color: Colors.white,
                      fontWeight: FontWeight.w800, fontSize: 13)),
                ])))),
            const SizedBox(width: 10),
            Expanded(child: _Tap(onTap: () => _decline(o).then((_) => _load()),
              child: Container(height: 42,
                decoration: BoxDecoration(
                  border: Border.all(color: _red2.withOpacity(.6)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.close_rounded, color: _red2, size: 16),
                  const SizedBox(width: 6),
                  Text(S('decline'), style: const TextStyle(color: _red2,
                      fontWeight: FontWeight.w800, fontSize: 13)),
                ])))),
          ]),
        ),
      ]),
    );
  }

  // ── active order card ─────────────────────────────────────────────────────
  Widget _activeOrderCard(Map<String, dynamic> o) {
    final st = o['status'] as String;
    final isOnWay = st == 'out_for_delivery';
    final grad = isOnWay
        ? const [_ind1, _ind2]
        : const [_sp1, _sp3] as List<Color>;
    final label = isOnWay ? 'ON WAY' : 'ACCEPTED';
    return _Tap(
      onTap: () async {
        await Navigator.push(context, MaterialPageRoute(
            builder: (_) => StockholderOrderDetailScreen(order: o)));
        _load();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(16),
          border: Border.all(color: grad.last.withOpacity(.25)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(.04),
              blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(children: [
          Container(width: 46, height: 46,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: grad,
                  begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(13)),
            child: Icon(isOnWay ? Icons.local_shipping_rounded : Icons.check_circle_outline,
                color: Colors.white, size: 22)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text((o['product'] as String?) ?? '',
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: _txt)),
            Text('${o['shopName'] ?? ''} • ${o['qty']}',
                style: const TextStyle(color: _sub, fontSize: 12)),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: grad),
                borderRadius: BorderRadius.circular(8)),
              child: Text(label, style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w900, fontSize: 10))),
            const SizedBox(height: 4),
            Text('৳${(o['price'] as num?)?.toStringAsFixed(0) ?? '0'}',
                style: const TextStyle(color: _sp2, fontWeight: FontWeight.w900, fontSize: 14)),
          ]),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right, color: _sub, size: 20),
        ]),
      ),
    );
  }

  // ── tip ───────────────────────────────────────────────────────────────────
  Widget _tipCard() => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: _sp3.withOpacity(.1),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: _sp3.withOpacity(.2)),
    ),
    child: const Row(children: [
      Icon(Icons.lightbulb_rounded, color: _sp2, size: 20),
      SizedBox(width: 10),
      Expanded(child: Text(
          'Tip: Keep your stock fresh — shops nearby will see it instantly.',
          style: TextStyle(fontSize: 12, color: _sp1, fontWeight: FontWeight.w600))),
    ]),
  );

  // ── delivery status FAB ───────────────────────────────────────────────────
  Widget _deliveryFab() {
    final hasOFD = _activeOrders.any((o) => o['status'] == 'out_for_delivery');
    return AnimatedBuilder(
      animation: _pulseC,
      builder: (_, __) {
        final scale = hasOFD ? (1.0 + 0.09 * _pulseC.value) : 1.0;
        return Transform.scale(
          scale: scale,
          child: GestureDetector(
            onTap: _showDeliverySheet,
            child: Container(
              width: 60, height: 60,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: hasOFD ? [_ind1, _ind2] : [_sp1, _sp3],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(
                  color: (hasOFD ? _ind2 : _sp3).withOpacity(hasOFD ? .65 : .45),
                  blurRadius: hasOFD ? 24 : 14, offset: const Offset(0, 6),
                )],
              ),
              child: Stack(children: [
                Center(child: Icon(
                  hasOFD ? Icons.local_shipping_rounded : Icons.receipt_long_rounded,
                  color: Colors.white, size: 26)),
                if (hasOFD)
                  Positioned(top: 8, right: 8,
                    child: Container(width: 12, height: 12,
                      decoration: const BoxDecoration(
                        color: Color(0xFFEF5350), shape: BoxShape.circle))),
              ]),
            ),
          ),
        );
      },
    );
  }

  void _showDeliverySheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.52,
        minChildSize: 0.3,
        maxChildSize: 0.85,
        builder: (ctx, sc) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(28), topRight: Radius.circular(28)),
          ),
          child: Column(children: [
            const SizedBox(height: 12),
            Center(child: Container(width: 40, height: 4,
              decoration: BoxDecoration(color: const Color(0xFFE0E0E0),
                  borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(children: [
                Container(width: 38, height: 38,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [_sp1, _sp3]),
                    borderRadius: BorderRadius.circular(11)),
                  child: const Icon(Icons.local_shipping_rounded,
                      color: Colors.white, size: 19)),
                const SizedBox(width: 12),
                const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Active Deliveries', style: TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w900, color: _sp0)),
                  Text('Tap to manage or enter OTP',
                      style: TextStyle(fontSize: 12, color: _sub)),
                ])),
                _Tap(onTap: () => Navigator.pop(context),
                  child: Container(width: 34, height: 34,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5), shape: BoxShape.circle),
                    child: const Icon(Icons.close_rounded, size: 17, color: _sub))),
              ]),
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                controller: sc,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                itemCount: _activeOrders.length,
                itemBuilder: (_, i) => _sheetOrderTile(_activeOrders[i]),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _sheetOrderTile(Map<String, dynamic> o) {
    final status  = o['status'] as String? ?? '';
    final isOFD   = status == 'out_for_delivery';
    final product = (o['product'] as String?) ?? '';
    final price   = (o['price'] as num?)?.toDouble() ?? 0;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (isOFD) Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: _ind2.withOpacity(.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _ind2.withOpacity(.35)),
        ),
        child: const Row(children: [
          Icon(Icons.vpn_key_rounded, color: _ind1, size: 14),
          SizedBox(width: 8),
          Expanded(child: Text('Waiting for OTP — parcel is on the way',
              style: TextStyle(color: _ind1, fontWeight: FontWeight.w700, fontSize: 12))),
        ]),
      ),
      _Tap(
        onTap: () {
          Navigator.pop(context);
          Navigator.push(context, MaterialPageRoute(
              builder: (_) => StockholderOrderDetailScreen(order: o)))
            .then((_) => _load());
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isOFD ? _ind2.withOpacity(.04) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: isOFD ? _ind2.withOpacity(.35) : Colors.grey.shade200),
            boxShadow: isOFD ? [BoxShadow(
                color: _ind2.withOpacity(.12), blurRadius: 10, offset: const Offset(0, 3))] : null,
          ),
          child: Row(children: [
            Container(width: 44, height: 44,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                    colors: isOFD ? [_ind1, _ind2] : [_sp1, _sp3],
                    begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(12)),
              child: Icon(isOFD ? Icons.local_shipping_rounded : Icons.check_circle_outline,
                  color: Colors.white, size: 22)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(product,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: _txt),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 3),
              Text('৳${price.toStringAsFixed(0)}  ·  ${isOFD ? 'Awaiting OTP' : 'Accepted'}',
                  style: TextStyle(
                      fontSize: 12,
                      color: isOFD ? _ind1 : _sub,
                      fontWeight: isOFD ? FontWeight.w700 : FontWeight.w500)),
            ])),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400, size: 20),
          ]),
        ),
      ),
    ]);
  }

  // ── bottom nav ────────────────────────────────────────────────────────────
  Widget _buildBottomNav() {
    final items = [
      (Icons.home_rounded, Icons.home_outlined, S('nav_home')),
      (Icons.inventory_2_rounded, Icons.inventory_2_outlined, S('nav_my_stock')),
      (Icons.receipt_long_rounded, Icons.receipt_long_outlined, S('nav_orders')),
      (Icons.person_rounded, Icons.person_outline_rounded, S('nav_profile')),
    ];
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(.07),
            blurRadius: 20, offset: const Offset(0, -4))],
      ),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SafeArea(top: false,
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(items.length, (i) {
            final sel = _tab == i;
            return _Tap(onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _tab = i);
            },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: sel ? 40 : 0, height: 3,
                    decoration: BoxDecoration(
                      gradient: sel ? const LinearGradient(colors: [_sp2, _sp3]) : null,
                      borderRadius: BorderRadius.circular(2)),
                  ),
                  const SizedBox(height: 4),
                  Icon(sel ? items[i].$1 : items[i].$2,
                      color: sel ? _sp2 : _sub, size: 24),
                  const SizedBox(height: 2),
                  Text(items[i].$3, style: TextStyle(
                      fontSize: 10.5, fontWeight: FontWeight.w700,
                      color: sel ? _sp2 : _sub)),
                ]),
              ));
          }),
        ),
      ),
    );
  }

  Widget _blob(double sz, Color c, double op) =>
      Container(width: sz, height: sz,
          decoration: BoxDecoration(shape: BoxShape.circle, color: c.withOpacity(op)));
}
