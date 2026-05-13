import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/auth_service.dart';
import '../../services/profile_service.dart';
import '../../services/rating_service.dart';
import '../../services/location_service.dart';
import 'edit_profile_screen.dart';
import 'location_picker_screen.dart';
import '../../config/language.dart';

// ── palette ───────────────────────────────────────────────────────────────────
const _c0  = Color(0xFF060D28);
const _c1  = Color(0xFF0E2260);
const _c2  = Color(0xFF1F4BD5);
const _c3  = Color(0xFF6C3FE8);
const _bg  = Color(0xFFF2F5FF);
const _txt = Color(0xFF212121);
const _sub = Color(0xFF757575);
const _grn1 = Color(0xFF3B0D6B);
const _grn2 = Color(0xFFBB6BF7);
const _amb1 = Color(0xFFAD4A0A);
const _amb2 = Color(0xFFF5981E);
const _red1 = Color(0xFF7B1C1C);
const _red2 = Color(0xFFEF5350);

// stockholder gradient (purple)
const _sg0 = Color(0xFF16002E);
const _sg1 = Color(0xFF3B0D6B);
const _sg2 = Color(0xFF7B2FD4);
const _sg3 = Color(0xFFBB6BF7);

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
class ProfileScreen extends StatefulWidget {
  final String role;
  const ProfileScreen({super.key, this.role = 'shop_owner'});
  @override State<ProfileScreen> createState() => _PS();
}

class _PS extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  bool _loading = true;
  Map<String, dynamic>? _data;
  List<Map<String, dynamic>> _ratings = [];

  late final _fadeC = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 400));

  bool get _isSH => widget.role == 'stockholder';

  List<Color> get _grad => _isSH
      ? const [_sg0, _sg1, _sg2, _sg3]
      : const [_c0, _c1, _c2, _c3];

  @override
  void initState() {
    super.initState();
    appLang.addListener(_onLangChange);
    _load();
  }

  void _onLangChange() => setState(() {});

  @override
  void dispose() {
    appLang.removeListener(_onLangChange);
    _fadeC.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final p = await ProfileService.getProfile();
    if (!mounted) return;
    final ratings = _isSH ? await RatingService.getMyRatings() : <Map<String, dynamic>>[];
    if (!mounted) return;
    setState(() { _data = p; _ratings = ratings; _loading = false; });
    _fadeC.forward(from: 0);
  }

  Future<void> _editProfile() async {
    final saved = await Navigator.push<bool>(context,
        MaterialPageRoute(builder: (_) => EditProfileScreen(
            role: widget.role, profileData: _data)));
    if (saved == true) _load();
  }

  Future<void> _changeLocation() async {
    final prof = (_data?['profile'] as Map?) ?? {};
    final lat = (prof['lat'] as num?)?.toDouble();
    final lng = (prof['lng'] as num?)?.toDouble();
    final r = await Navigator.push<LocationResult>(context,
        MaterialPageRoute(builder: (_) => LocationPickerScreen(
          title: _isSH ? 'Warehouse Location' : 'Shop Location',
          initialLat: lat, initialLng: lng)));
    if (r == null || !mounted) return;
    setState(() => _loading = true);
    await ProfileService.saveLocation(r);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: _isSH ? _grn1 : _c1,
        content: const Text('Location updated',
            style: TextStyle(fontWeight: FontWeight.w600))));
    _load();
  }

  Future<void> _logout() async {
    final yes = await showDialog<bool>(context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 60, height: 60,
              decoration: BoxDecoration(
                color: _red2.withOpacity(.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.logout_rounded, color: _red1, size: 28)),
            const SizedBox(height: 16),
            Text(S('log_out_title'), style: const TextStyle(fontSize: 18,
                fontWeight: FontWeight.w900, color: _txt)),
            const SizedBox(height: 8),
            const Text('You will need to sign in again.',
                style: TextStyle(color: _sub, fontSize: 13.5)),
            const SizedBox(height: 24),
            Row(children: [
              Expanded(child: _Tap(onTap: () => Navigator.pop(context, false),
                child: Container(height: 46,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF0FA),
                    borderRadius: BorderRadius.circular(12)),
                  child: Center(child: Text(S('cancel'),
                      style: const TextStyle(fontWeight: FontWeight.w700, color: _sub)))))),
              const SizedBox(width: 10),
              Expanded(child: _Tap(onTap: () => Navigator.pop(context, true),
                child: Container(height: 46,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [_red1, _red2]),
                    borderRadius: BorderRadius.circular(12)),
                  child: Center(child: Text(S('log_out'),
                      style: const TextStyle(fontWeight: FontWeight.w800,
                          color: Colors.white)))))),
            ]),
          ]),
        ),
      ),
    );
    if (yes == true && mounted) {
      await AuthService.logout();
      await ProfileService.clearCachedLocation();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/welcome', (_) => false);
      }
    }
  }

  String _initials(String name) {
    final parts = name.trim().split(' ').where((s) => s.isNotEmpty).toList();
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return parts.isEmpty ? '?' : parts[0][0].toUpperCase();
  }

  String _sinceDate(String? iso) {
    if (iso == null) return '';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '';
    const m = ['','Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${m[dt.month]} ${dt.year}';
  }

  // ════════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final prof       = (_data?['profile'] as Map?) ?? {};
    final name       = (_data?['name'] as String?) ?? '';
    final phone      = (_data?['phone'] as String?) ?? '';
    final email      = (_data?['email'] as String?) ?? '';
    final since      = _sinceDate(_data?['created_at'] as String?);
    final isVerified = prof['is_verified'] == true || prof['is_verified'] == 1;
    final rating     = (prof['rating_avg'] as num?)?.toStringAsFixed(1) ?? '—';
    final bizName    = _isSH
        ? (prof['company_name'] as String?) ?? ''
        : (prof['shop_name'] as String?) ?? '';
    final address    = _isSH
        ? (prof['warehouse_address'] as String?) ?? ''
        : (prof['shop_address'] as String?) ?? '';
    final area       = (prof['area'] as String?) ?? '';
    final lat        = (prof['lat'] as num?)?.toDouble() ?? 0.0;
    final lng        = (prof['lng'] as num?)?.toDouble() ?? 0.0;
    final hasGps     = lat != 0 && lng != 0;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _bg,
        body: _loading
            ? Column(children: [
                _headerShell(),
                const Expanded(child: Center(child: CircularProgressIndicator())),
              ])
            : FadeTransition(
                opacity: CurvedAnimation(parent: _fadeC, curve: Curves.easeOut),
                child: RefreshIndicator(
                  onRefresh: _load, color: _isSH ? _grn2 : _c2,
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(child: _header(
                          name, bizName, since, rating, isVerified)),
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
                        sliver: SliverList(delegate: SliverChildListDelegate([
                          // quick actions
                          _sectionTitle(S('quick_actions')),
                          const SizedBox(height: 12),
                          _quickActions(),
                          const SizedBox(height: 24),
                          // account info
                          _sectionTitle('Account Info'),
                          const SizedBox(height: 12),
                          _infoCard(phone, email, bizName, address, area,
                              lat, lng, hasGps),
                          if (_isSH) ...[
                            const SizedBox(height: 24),
                            _sectionTitle('Ratings & Reviews'),
                            const SizedBox(height: 12),
                            _ratingsSection(rating),
                          ],
                          const SizedBox(height: 32),
                          // logout
                          _logoutBtn(),
                        ])),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  // ── gradient header ───────────────────────────────────────────────────────
  Widget _headerShell() => Container(
    height: 200,
    decoration: BoxDecoration(
      gradient: LinearGradient(colors: _grad,
          stops: const [0.0, 0.35, 0.72, 1.0],
          begin: Alignment.topLeft, end: Alignment.bottomRight),
      borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(36), bottomRight: Radius.circular(36)),
    ),
  );

  Widget _header(String name, String bizName, String since,
      String rating, bool verified) {
    final initials = _initials(name);
    final tag = _isSH ? 'Stockholder' : 'Shop Owner';
    final accentGrad = _isSH ? const [_sg2, _sg3] : const [_c2, _c3];

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: _grad,
            stops: const [0.0, 0.35, 0.72, 1.0],
            begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(36), bottomRight: Radius.circular(36)),
      ),
      child: SafeArea(bottom: false,
        child: Stack(children: [
          Positioned(top: -20, right: -30, child: _blob(140, Colors.white, .04)),
          Positioned(top: 10,  right: 60,  child: _blob(48, Colors.white, .06)),
          Positioned(top: 60,  left: -25,  child: _blob(90, _c3, .15)),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
            child: Column(children: [
              // top row
              Row(children: [
                Text(S('profile_title'), style: const TextStyle(color: Colors.white,
                    fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -.4)),
                const Spacer(),
                // refresh btn
                ClipRRect(borderRadius: BorderRadius.circular(12),
                  child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                    child: _Tap(onTap: _load,
                      child: Container(width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.14),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withOpacity(0.25)),
                        ),
                        child: const Icon(Icons.refresh_rounded,
                            color: Colors.white, size: 18)),
                    ),
                  ),
                ),
              ]),
              const SizedBox(height: 22),
              // avatar
              Container(width: 80, height: 80,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: accentGrad,
                      begin: Alignment.topLeft, end: Alignment.bottomRight),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withOpacity(.35), width: 3),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(.25),
                      blurRadius: 16, offset: const Offset(0, 6))],
                ),
                child: Center(child: Text(initials,
                    style: const TextStyle(color: Colors.white,
                        fontSize: 28, fontWeight: FontWeight.w900)))),
              const SizedBox(height: 14),
              Text(name.isEmpty ? 'Loading...' : name,
                  style: const TextStyle(color: Colors.white, fontSize: 20,
                      fontWeight: FontWeight.w900, letterSpacing: -.3)),
              if (bizName.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(bizName, style: TextStyle(
                    color: Colors.white.withOpacity(.7), fontSize: 13.5),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
              const SizedBox(height: 12),
              // badges row
              Wrap(alignment: WrapAlignment.center, spacing: 8, children: [
                _badge(tag, Icons.badge_rounded),
                if (verified)
                  _badge(S('verified_badge'), Icons.verified_rounded,
                      color: _isSH ? _grn2 : _amb2),
                if (rating != '—')
                  _badge('★  $rating', null),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _badge(String text, IconData? icon, {Color? color}) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(.18),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.white.withOpacity(.25)),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      if (icon != null) ...[
        Icon(icon, color: color ?? Colors.white, size: 13),
        const SizedBox(width: 5),
      ],
      Text(text, style: TextStyle(
          color: color ?? Colors.white,
          fontSize: 12, fontWeight: FontWeight.w700)),
    ]),
  );

  // ── section title ─────────────────────────────────────────────────────────
  Widget _sectionTitle(String t) => Text(t, style: const TextStyle(
      fontSize: 13, fontWeight: FontWeight.w800,
      color: _sub, letterSpacing: .5));

  // ── quick actions 2×2 ─────────────────────────────────────────────────────
  Widget _quickActions() {
    final accent1 = _isSH ? _grn1 : _c1;
    final accent2 = _isSH ? _grn2 : _c2;
    return Row(children: [
      Expanded(child: _actionCard(
          icon: Icons.edit_rounded,
          label: S('edit_profile_btn'),
          sub: 'Name & details',
          grad: [accent1, accent2],
          onTap: _editProfile)),
      const SizedBox(width: 12),
      Expanded(child: _actionCard(
          icon: Icons.edit_location_alt_rounded,
          label: 'Change Location',
          sub: 'Update your address',
          grad: [_amb1, _amb2],
          onTap: _changeLocation)),
    ]);
  }

  Widget _actionCard({
    required IconData icon,
    required String label,
    required String sub,
    required List<Color> grad,
    required VoidCallback onTap,
  }) => _Tap(onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: grad[0].withOpacity(.1),
              blurRadius: 16, offset: const Offset(0, 6)),
          BoxShadow(color: Colors.black.withOpacity(.03),
              blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(width: 44, height: 44,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: grad,
                begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(13),
            boxShadow: [BoxShadow(color: grad.last.withOpacity(.35),
                blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Icon(icon, color: Colors.white, size: 20)),
        const SizedBox(height: 12),
        Text(label, style: const TextStyle(fontSize: 13.5,
            fontWeight: FontWeight.w800, color: _txt)),
        const SizedBox(height: 2),
        Text(sub, style: const TextStyle(fontSize: 11.5, color: _sub)),
      ]),
    ),
  );

  // ── info card ─────────────────────────────────────────────────────────────
  Widget _infoCard(String phone, String email, String bizName, String address,
      String area, double lat, double lng, bool hasGps) {
    final accent = _isSH ? _grn2 : _c2;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(color: _c1.withOpacity(.07), blurRadius: 20, offset: const Offset(0, 6)),
          BoxShadow(color: Colors.black.withOpacity(.03), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(children: [
        if (phone.isNotEmpty)
          _infoRow(Icons.phone_rounded, _sub, 'Phone', phone),
        if (email.isNotEmpty) ...[
          _divider(),
          _infoRow(Icons.email_rounded, _sub, 'Email', email),
        ],
        if (bizName.isNotEmpty) ...[
          _divider(),
          _infoRow(
            _isSH ? Icons.business_rounded : Icons.store_rounded,
            accent,
            _isSH ? 'Company' : 'Shop Name',
            bizName),
        ],
        if (address.isNotEmpty) ...[
          _divider(),
          _infoRow(Icons.home_rounded, _sub, 'Address', address),
        ],
        if (area.isNotEmpty) ...[
          _divider(),
          _infoRow(Icons.place_rounded, accent, 'Area', area),
        ],
        _divider(),
        // GPS status
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
          child: Row(children: [
            Container(width: 34, height: 34,
              decoration: BoxDecoration(
                color: (hasGps ? _grn2 : _amb2).withOpacity(.12),
                borderRadius: BorderRadius.circular(10)),
              child: Icon(
                hasGps ? Icons.my_location_rounded : Icons.location_off_rounded,
                color: hasGps ? _grn2 : _amb2, size: 16)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('GPS Location', style: TextStyle(
                  fontSize: 11.5, color: _sub, fontWeight: FontWeight.w500)),
              const SizedBox(height: 2),
              Text(
                hasGps ? '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}'
                    : 'Not set — tap Change Location',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                    color: hasGps ? _txt : _amb1),
                maxLines: 1, overflow: TextOverflow.ellipsis),
            ])),
            if (!hasGps)
              _Tap(onTap: _changeLocation,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [_amb1, _amb2]),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text('Set Now', style: TextStyle(
                      color: Colors.white, fontSize: 11.5,
                      fontWeight: FontWeight.w800)))),
          ]),
        ),
      ]),
    );
  }

  Widget _infoRow(IconData icon, Color c, String label, String value) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
    child: Row(children: [
      Container(width: 34, height: 34,
        decoration: BoxDecoration(
            color: c.withOpacity(.1), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: c, size: 16)),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(
            fontSize: 11.5, color: _sub, fontWeight: FontWeight.w500)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 13.5,
            fontWeight: FontWeight.w700, color: _txt),
            maxLines: 2, overflow: TextOverflow.ellipsis),
      ])),
    ]),
  );

  Widget _divider() => const Padding(
    padding: EdgeInsets.only(left: 62, top: 12),
    child: Divider(height: 1, color: Color(0xFFF0F2FA)),
  );

  // ── ratings section (stockholder only) ───────────────────────────────────
  Widget _ratingsSection(String avgRating) {
    if (_ratings.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: _sg1.withOpacity(.07), blurRadius: 16, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(children: [
          Container(width: 52, height: 52,
            decoration: BoxDecoration(color: _grn2.withOpacity(.1), shape: BoxShape.circle),
            child: const Icon(Icons.star_outline_rounded, color: _grn1, size: 26)),
          const SizedBox(height: 12),
          const Text('No reviews yet', style: TextStyle(
              fontSize: 15, fontWeight: FontWeight.w800, color: _txt)),
          const SizedBox(height: 4),
          const Text('Reviews from shop owners will appear here',
              textAlign: TextAlign.center,
              style: TextStyle(color: _sub, fontSize: 12.5)),
        ]),
      );
    }

    final avg = double.tryParse(avgRating) ?? 0;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: _sg1.withOpacity(.07), blurRadius: 16, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(children: [
        // summary row
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            Container(width: 64, height: 64,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [_sg1, _sg3],
                    begin: Alignment.topLeft, end: Alignment.bottomRight),
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: _sg3.withOpacity(.3),
                    blurRadius: 12, offset: const Offset(0, 4))],
              ),
              child: Center(child: Text(
                  avgRating == '—' ? '?' : avgRating,
                  style: const TextStyle(color: Colors.white,
                      fontSize: 22, fontWeight: FontWeight.w900)))),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: List.generate(5, (i) => Icon(
                  i < avg.round() ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: const Color(0xFFFFB300), size: 20))),
              const SizedBox(height: 4),
              Text('${_ratings.length} review${_ratings.length == 1 ? '' : 's'}',
                  style: const TextStyle(color: _sub, fontSize: 13)),
            ])),
          ]),
        ),
        // review list
        ..._ratings.take(5).map((r) {
          final score = (r['score'] as num?)?.toInt() ?? 0;
          final review = (r['review'] as String?) ?? '';
          final giverName = (r['given_by_name'] as String?) ?? 'Shop Owner';
          final shopName = (r['shop_name'] as String?) ?? '';
          final dateStr = (r['created_at'] as String?) ?? '';
          DateTime? dt;
          try { dt = DateTime.parse(dateStr).toLocal(); } catch (_) {}
          final dateLabel = dt != null
              ? '${dt.day}/${dt.month}/${dt.year}'
              : '';
          return Column(children: [
            const Divider(height: 1, color: Color(0xFFF0F2FA)),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(width: 36, height: 36,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [_sg1, _sg3]),
                    shape: BoxShape.circle),
                  child: Center(child: Text(
                      giverName.isNotEmpty ? giverName[0].toUpperCase() : 'S',
                      style: const TextStyle(color: Colors.white,
                          fontWeight: FontWeight.w900, fontSize: 14)))),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(child: Text(giverName, style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 13.5, color: _txt))),
                    Text(dateLabel, style: const TextStyle(color: _sub, fontSize: 11)),
                  ]),
                  if (shopName.isNotEmpty) ...[
                    const SizedBox(height: 1),
                    Text(shopName, style: const TextStyle(color: _sub, fontSize: 12)),
                  ],
                  const SizedBox(height: 5),
                  Row(children: List.generate(5, (i) => Icon(
                      i < score ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: const Color(0xFFFFB300), size: 15))),
                  if (review.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F0FF),
                        borderRadius: BorderRadius.circular(10)),
                      child: Text(review, style: const TextStyle(
                          fontSize: 13, color: _txt, height: 1.4))),
                  ],
                ])),
              ]),
            ),
          ]);
        }),
        if (_ratings.length > 5)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: Text('+${_ratings.length - 5} more reviews',
                style: const TextStyle(color: _sub, fontSize: 12))),
        const SizedBox(height: 4),
      ]),
    );
  }

  // ── logout ────────────────────────────────────────────────────────────────
  Widget _logoutBtn() => _Tap(
    onTap: _logout,
    child: Container(
      width: double.infinity, height: 54,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _red2.withOpacity(.3)),
        boxShadow: [BoxShadow(color: _red1.withOpacity(.05),
            blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.logout_rounded, color: _red1, size: 20),
        const SizedBox(width: 10),
        Text(S('log_out'), style: const TextStyle(color: _red1,
            fontSize: 15, fontWeight: FontWeight.w800)),
      ]),
    ),
  );

  Widget _blob(double sz, Color c, double op) =>
      Container(width: sz, height: sz,
          decoration: BoxDecoration(shape: BoxShape.circle, color: c.withOpacity(op)));
}
