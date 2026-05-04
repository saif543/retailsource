import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/demand_service.dart';
import 'post_demand_screen.dart';
import 'demand_detail_screen.dart';

const _c0  = Color(0xFF060D28);
const _c1  = Color(0xFF0E2260);
const _c2  = Color(0xFF1F4BD5);
const _c3  = Color(0xFF6C3FE8);
const _bg  = Color(0xFFF2F5FF);
const _txt = Color(0xFF212121);
const _sub = Color(0xFF757575);
const _amb1 = Color(0xFFAD4A0A); const _amb2 = Color(0xFFF5981E);
const _grn1 = Color(0xFF054F3A); const _grn2 = Color(0xFF0FBB84);

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

class MyDemandsScreen extends StatefulWidget {
  const MyDemandsScreen({super.key});
  @override State<MyDemandsScreen> createState() => _MDS();
}

class _MDS extends State<MyDemandsScreen> with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _demands = [];
  bool _loading = true;
  String _filter = 'all';

  late final _fadeC = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 380));

  @override
  void initState() { super.initState(); _load(); }
  @override
  void dispose() { _fadeC.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = await DemandService.getMyDemands();
    if (!mounted) return;
    setState(() { _demands = list; _loading = false; });
    _fadeC.forward(from: 0);
  }

  List<Map<String, dynamic>> get _filtered =>
      _filter == 'all' ? _demands : _demands.where((d) => d['status'] == _filter).toList();

  int _cnt(String s) => s == 'all'
      ? _demands.length
      : _demands.where((d) => d['status'] == s).length;

  String _timeAgo(String? iso) {
    if (iso == null) return '';
    final t = DateTime.tryParse(iso); if (t == null) return '';
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 60) return '${d.inMinutes}m ago';
    if (d.inHours   < 24) return '${d.inHours}h ago';
    return '${d.inDays}d ago';
  }

  List<Color> _statusGrad(String s) {
    if (s == 'matched')   return [_amb1, _amb2];
    if (s == 'fulfilled') return [_grn1, _grn2];
    return [_c1, _c2];
  }
  IconData _statusIcon(String s) {
    if (s == 'matched')   return Icons.handshake_rounded;
    if (s == 'fulfilled') return Icons.check_circle_rounded;
    return Icons.access_time_rounded;
  }
  String _statusLabel(String s) {
    if (s == 'matched')   return 'Matched';
    if (s == 'fulfilled') return 'Fulfilled';
    return 'Open';
  }
  String _actionLabel(String s) {
    if (s == 'matched')   return 'View Matches';
    if (s == 'fulfilled') return 'View Detail';
    return 'Find Suppliers';
  }

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: SystemUiOverlayStyle.light,
    child: Scaffold(
      backgroundColor: _bg,
      body: Column(children: [
        _header(),
        Expanded(child: _loading
            ? const Center(child: CircularProgressIndicator())
            : FadeTransition(
                opacity: CurvedAnimation(parent: _fadeC, curve: Curves.easeOut),
                child: RefreshIndicator(
                  onRefresh: _load, color: _c2,
                  child: _filtered.isEmpty
                      ? _empty()
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                          itemCount: _filtered.length,
                          itemBuilder: (_, i) => _card(_filtered[i]),
                        ),
                ),
              )),
      ]),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final posted = await Navigator.push(context,
              MaterialPageRoute(builder: (_) => const PostDemandScreen()));
          if (posted == true) _load();
        },
        backgroundColor: const Color(0xFFD03800),
        foregroundColor: Colors.white,
        elevation: 6,
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Demand', style: TextStyle(fontWeight: FontWeight.w800)),
      ),
    ),
  );

  // ── gradient header ───────────────────────────────────────────────────────
  Widget _header() => Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
          colors: [_c0, _c1, _c2, _c3],
          stops: [0.0, 0.35, 0.72, 1.0],
          begin: Alignment.topLeft, end: Alignment.bottomRight),
      borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32), bottomRight: Radius.circular(32)),
    ),
    child: SafeArea(bottom: false,
      child: Stack(children: [
        Positioned(top: -20, right: -30, child: _blob(130, Colors.white, .04)),
        Positioned(top: 8,   right: 50,  child: _blob(44,  _c2, .3)),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // top row
            Row(children: [
              const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('My Demands', style: TextStyle(color: Colors.white,
                    fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -.4)),
                SizedBox(height: 2),
                Text('Track all your posted demands',
                    style: TextStyle(color: Colors.white54, fontSize: 12.5)),
              ])),
              // refresh glass btn
              ClipRRect(borderRadius: BorderRadius.circular(12),
                child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: _Tap(onTap: _load,
                    child: Container(width: 42, height: 42,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.14),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withOpacity(0.25)),
                      ),
                      child: const Icon(Icons.refresh_rounded, color: Colors.white, size: 19)),
                  ),
                ),
              ),
            ]),
            const SizedBox(height: 18),
            // filter chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: [
                _chip('all',       'All',       _cnt('all')),
                _chip('open',      'Open',      _cnt('open')),
                _chip('matched',   'Matched',   _cnt('matched')),
                _chip('fulfilled', 'Done',      _cnt('fulfilled')),
              ]),
            ),
          ]),
        ),
      ]),
    ),
  );

  Widget _chip(String key, String label, int count) {
    final sel = _filter == key;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: _Tap(onTap: () { HapticFeedback.lightImpact(); setState(() => _filter = key); },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: sel ? Colors.white : Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
                color: sel ? Colors.white : Colors.white.withOpacity(0.3)),
            boxShadow: sel ? [BoxShadow(color: _c1.withOpacity(.3),
                blurRadius: 8, offset: const Offset(0, 3))] : null,
          ),
          child: Text('$label  $count',
              style: TextStyle(
                  color: sel ? _c1 : Colors.white,
                  fontWeight: FontWeight.w800, fontSize: 13)),
        ),
      ),
    );
  }

  // ── demand card ───────────────────────────────────────────────────────────
  Widget _card(Map<String, dynamic> d) {
    final status = (d['status'] ?? 'open') as String;
    final grad   = _statusGrad(status);

    return _Tap(
      onTap: () async {
        final r = await Navigator.push(context, _route(
            DemandDetailScreen(demandId: d['demand_id'] as int)));
        if (r == 'cancelled' || r == 'ordered') _load();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(color: _c1.withOpacity(.08), blurRadius: 20, offset: const Offset(0, 6)),
            BoxShadow(color: Colors.black.withOpacity(.03), blurRadius: 4, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(children: [
          // top section
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(children: [
              // icon
              Container(width: 50, height: 50,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: grad,
                      begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [BoxShadow(color: grad.last.withOpacity(.38),
                      blurRadius: 12, offset: const Offset(0, 4))],
                ),
                child: Icon(_statusIcon(status), color: Colors.white, size: 24)),
              const SizedBox(width: 14),
              // product info
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${d['product_name']}',
                    style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800,
                        color: _txt, letterSpacing: -.2),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _c2.withOpacity(.09), borderRadius: BorderRadius.circular(6)),
                    child: Text('${d['variant_name']}',
                        style: const TextStyle(color: _c2, fontSize: 11.5,
                            fontWeight: FontWeight.w700))),
                  const SizedBox(width: 6),
                  Text('${d['category_name']}',
                      style: const TextStyle(color: _sub, fontSize: 12)),
                ]),
              ])),
              // status badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: grad),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [BoxShadow(color: grad.last.withOpacity(.35),
                      blurRadius: 8, offset: const Offset(0, 3))],
                ),
                child: Text(_statusLabel(status),
                    style: const TextStyle(color: Colors.white,
                        fontSize: 11, fontWeight: FontWeight.w800))),
            ]),
          ),
          // meta row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: Row(children: [
              _metaPill(Icons.scale_rounded, '${d['quantity']} ${d['unit']}', _c2),
              const SizedBox(width: 8),
              _metaPill(Icons.access_time_rounded,
                  _timeAgo(d['created_at'] as String?), _sub),
              if ((d['location_area'] ?? '').toString().isNotEmpty) ...[
                const SizedBox(width: 8),
                Expanded(child: _metaPill(Icons.place_rounded,
                    d['location_area'] as String, _sub, expand: true)),
              ],
            ]),
          ),
          // action strip
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: [grad[0].withOpacity(.06), grad[1].withOpacity(.03)]),
              borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(22),
                  bottomRight: Radius.circular(22)),
              border: Border(top: BorderSide(color: grad[1].withOpacity(.12))),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            child: Row(children: [
              Icon(_statusIcon(status), color: grad.last, size: 15),
              const SizedBox(width: 7),
              Text(_actionLabel(status),
                  style: TextStyle(color: grad.last,
                      fontWeight: FontWeight.w800, fontSize: 13)),
              const Spacer(),
              Icon(Icons.arrow_forward_ios_rounded, size: 12, color: grad.last),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _metaPill(IconData icon, String text, Color c, {bool expand = false}) {
    final w = Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: c.withOpacity(.08),
        borderRadius: BorderRadius.circular(8)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 12, color: c),
        const SizedBox(width: 5),
        expand
            ? Flexible(child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: TextStyle(color: c, fontSize: 11.5, fontWeight: FontWeight.w600)))
            : Text(text, style: TextStyle(color: c, fontSize: 11.5, fontWeight: FontWeight.w600)),
      ]),
    );
    return expand ? Expanded(child: w) : w;
  }

  Widget _empty() => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
    Container(width: 90, height: 90,
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [_c1, _c3]),
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: _c2.withOpacity(.3), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: const Icon(Icons.inbox_rounded, size: 44, color: Colors.white)),
    const SizedBox(height: 20),
    const Text('No demands yet',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _txt)),
    const SizedBox(height: 8),
    Text(_filter == 'all'
        ? 'Tap "New Demand" to find suppliers'
        : 'No ${_filter} demands',
        style: const TextStyle(color: _sub, fontSize: 14)),
  ]));

  Widget _blob(double sz, Color c, double op) =>
      Container(width: sz, height: sz,
          decoration: BoxDecoration(shape: BoxShape.circle, color: c.withOpacity(op)));

  PageRoute _route(Widget w) => PageRouteBuilder(
    pageBuilder: (_, a, __) => w,
    transitionDuration: const Duration(milliseconds: 260),
    transitionsBuilder: (_, a, __, ch) => SlideTransition(
      position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
          .animate(CurvedAnimation(parent: a, curve: Curves.easeInOut)), child: ch),
  );
}
