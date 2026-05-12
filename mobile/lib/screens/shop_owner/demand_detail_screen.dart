import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/demand_service.dart';
import 'matching_suppliers_screen.dart';

// ── palette ───────────────────────────────────────────────────────────────────
const _c0  = Color(0xFF060D28);
const _c1  = Color(0xFF0E2260);
const _c2  = Color(0xFF1F4BD5);
const _c3  = Color(0xFF6C3FE8);
const _bg  = Color(0xFFF2F5FF);
const _txt = Color(0xFF212121);
const _sub = Color(0xFF757575);

const _grn1 = Color(0xFF054F3A); const _grn2 = Color(0xFF0FBB84);
const _amb1 = Color(0xFFAD4A0A); const _amb2 = Color(0xFFF5981E);
const _red1 = Color(0xFF7B1C1C); const _red2 = Color(0xFFEF5350);

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
class DemandDetailScreen extends StatefulWidget {
  final int demandId;
  const DemandDetailScreen({super.key, required this.demandId});
  @override State<DemandDetailScreen> createState() => _DDS();
}

class _DDS extends State<DemandDetailScreen> with SingleTickerProviderStateMixin {
  Map<String, dynamic>? _d;
  bool _loading = true, _busy = false;

  late final _fadeC = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 400));

  @override
  void initState() { super.initState(); _load(); }

  @override
  void dispose() { _fadeC.dispose(); super.dispose(); }

  Future<void> _load() async {
    final d = await DemandService.getDemand(widget.demandId);
    if (!mounted) return;
    setState(() { _d = d; _loading = false; });
    _fadeC.forward();
  }

  Future<void> _confirmCancel() async {
    final yes = await showDialog<bool>(context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Text('Cancel this demand?',
            style: TextStyle(fontWeight: FontWeight.w800)),
        content: const Text('Suppliers will no longer see this request.',
            style: TextStyle(color: _sub, height: 1.5)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
              child: const Text('Keep')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: _red2, foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: const Text('Cancel Demand', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (yes != true) return;
    setState(() => _busy = true);
    final res = await DemandService.cancelDemand(widget.demandId);
    if (!mounted) return;
    setState(() => _busy = false);
    if (res.ok) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          backgroundColor: Color(0xFF2E7D32),
          content: Text('Demand cancelled')));
      Navigator.pop(context, 'cancelled');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res.error ?? 'Failed to cancel')));
    }
  }

  String _timeAgo(String? iso) {
    if (iso == null) return '';
    final t = DateTime.tryParse(iso);
    if (t == null) return '';
    final diff = DateTime.now().difference(t);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours  < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  // ── status helpers ────────────────────────────────────────────────────────
  List<Color> _statusGrad(String s) {
    if (s == 'matched')   return [_amb1, _amb2];
    if (s == 'fulfilled') return [_grn1, _grn2];
    return [_c1, _c2];                          // open
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

  // ════════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: SystemUiOverlayStyle.light,
    child: Scaffold(
      backgroundColor: _bg,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _d == null
              ? _notFound()
              : FadeTransition(
                  opacity: CurvedAnimation(parent: _fadeC, curve: Curves.easeOut),
                  child: _body()),
    ),
  );

  Widget _notFound() => Scaffold(
    backgroundColor: _bg,
    appBar: AppBar(backgroundColor: _c1, foregroundColor: Colors.white,
        title: const Text('Demand Details')),
    body: const Center(child: Text('Demand not found')),
  );

  // ── main body ─────────────────────────────────────────────────────────────
  Widget _body() {
    final d      = _d!;
    final status = (d['status'] ?? 'open') as String;
    final grad   = _statusGrad(status);

    return Column(children: [
      _header(d, status, grad),
      Expanded(child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _infoCard(d),
          const SizedBox(height: 20),
          _locationCard(d),
          if ((d['additional_notes'] ?? '').toString().isNotEmpty) ...[
            const SizedBox(height: 20),
            _notesCard(d['additional_notes'] as String),
          ],
          const SizedBox(height: 28),
          _actions(d, status),
        ]),
      )),
    ]);
  }

  // ── gradient header ───────────────────────────────────────────────────────
  Widget _header(Map<String, dynamic> d, String status, List<Color> grad) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: [_c0, _c1, grad[0], grad[1]],
            stops: const [0.0, 0.35, 0.72, 1.0],
            begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(32), bottomRight: Radius.circular(32)),
      ),
      child: SafeArea(bottom: false,
        child: Stack(children: [
          Positioned(top: -20, right: -30, child: _blob(130, Colors.white, .04)),
          Positioned(top: 10,  right: 50,  child: _blob(44,  _c2, .3)),
          Positioned(top: 45,  left: -20,  child: _blob(80,  _c3, .2)),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 20, 28),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // top bar
              Row(children: [
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
                Expanded(child: Text('Demand Details',
                    style: const TextStyle(color: Colors.white, fontSize: 18,
                        fontWeight: FontWeight.w900, letterSpacing: -.3))),
                // status badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: grad),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.25)),
                    boxShadow: [BoxShadow(color: grad.last.withOpacity(.4),
                        blurRadius: 12, offset: const Offset(0, 4))],
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(_statusIcon(status), color: Colors.white, size: 13),
                    const SizedBox(width: 5),
                    Text(_statusLabel(status),
                        style: const TextStyle(color: Colors.white,
                            fontSize: 12, fontWeight: FontWeight.w800)),
                  ]),
                ),
              ]),
              const SizedBox(height: 20),
              // product row
              Row(children: [
                Container(width: 56, height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
                  ),
                  child: const Icon(Icons.shopping_basket_rounded,
                      color: Colors.white, size: 28)),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${d['product_name']}',
                      style: const TextStyle(color: Colors.white, fontSize: 19,
                          fontWeight: FontWeight.w900, letterSpacing: -.3)),
                  const SizedBox(height: 4),
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('${d['variant_name']}',
                          style: const TextStyle(color: Colors.white,
                              fontSize: 12, fontWeight: FontWeight.w600))),
                    const SizedBox(width: 6),
                    Text('${d['category_name']}',
                        style: TextStyle(color: Colors.white.withOpacity(0.65), fontSize: 12)),
                  ]),
                ])),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }

  // ── info card ─────────────────────────────────────────────────────────────
  Widget _infoCard(Map<String, dynamic> d) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDeco(),
      child: Column(children: [
        _infoRow(
          icon: Icons.scale_rounded, iconColor: _c2,
          label: 'Quantity',
          value: '${d['quantity']} ${d['unit']}',
          valueBold: true,
        ),
        _divider(),
        _infoRow(
          icon: Icons.category_rounded, iconColor: _grn2,
          label: 'Category',
          value: '${d['category_name']}',
        ),
        _divider(),
        _infoRow(
          icon: Icons.access_time_rounded, iconColor: _amb2,
          label: 'Posted',
          value: _timeAgo(d['created_at'] as String?),
        ),
      ]),
    );
  }

  // ── location card (text only — no map) ───────────────────────────────────
  Widget _locationCard(Map<String, dynamic> d) {
    final area     = (d['location_area'] ?? '') as String;
    final lat      = d['lat'] as double?;
    final lng      = d['lng'] as double?;
    final hasCoord = lat != null && lng != null;

    if (!hasCoord && area.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDeco(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // title row
        Row(children: [
          Container(width: 36, height: 36,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [_c1, _c2]),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [BoxShadow(color: _c2.withOpacity(.35),
                  blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: const Icon(Icons.location_on_rounded, color: Colors.white, size: 18)),
          const SizedBox(width: 12),
          const Text('Delivery Location',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: _txt)),
        ]),
        const SizedBox(height: 16),

        // area pill
        if (area.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: [_c1.withOpacity(.08), _c2.withOpacity(.04)]),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _c2.withOpacity(.2)),
            ),
            child: Row(children: [
              Icon(Icons.place_rounded, color: _c2, size: 18),
              const SizedBox(width: 10),
              Expanded(child: Text(area,
                  style: const TextStyle(fontSize: 14,
                      fontWeight: FontWeight.w700, color: _txt))),
            ]),
          ),

        // coordinates row
        if (hasCoord) ...[
          if (area.isNotEmpty) const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF2F5FF),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE4E8F5)),
            ),
            child: Row(children: [
              Icon(Icons.my_location_rounded, color: _sub, size: 16),
              const SizedBox(width: 10),
              Text(
                '${lat!.toStringAsFixed(5)}, ${lng!.toStringAsFixed(5)}',
                style: const TextStyle(fontSize: 13, color: _sub,
                    fontWeight: FontWeight.w500, letterSpacing: .2)),
            ]),
          ),
        ],
      ]),
    );
  }

  // ── notes card ────────────────────────────────────────────────────────────
  Widget _notesCard(String notes) => Container(
    padding: const EdgeInsets.all(20),
    decoration: _cardDeco(),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(width: 36, height: 36,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [_amb1.withOpacity(.9), _amb2]),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [BoxShadow(color: _amb2.withOpacity(.35),
              blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: const Icon(Icons.sticky_note_2_rounded, color: Colors.white, size: 18)),
      const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Notes', style: TextStyle(fontSize: 13,
            fontWeight: FontWeight.w700, color: _sub)),
        const SizedBox(height: 6),
        Text(notes, style: const TextStyle(fontSize: 14,
            color: _txt, height: 1.55)),
      ])),
    ]),
  );

  // ── action buttons ────────────────────────────────────────────────────────
  Widget _actions(Map<String, dynamic> d, String status) {
    if (status == 'fulfilled') return _fulfilledBanner(d);

    final lat = d['lat'] as double?;
    final lng = d['lng'] as double?;

    return Column(children: [
      // Find Suppliers / View Matches CTA
      _Tap(
        onTap: () async {
          final placed = await Navigator.push<bool>(context,
            MaterialPageRoute(builder: (_) => MatchingSuppliersScreen(
              demandId: widget.demandId,
              productLabel: '${d['product_name']} - ${d['variant_name']}',
              demandQuantity: (d['quantity'] as num).toDouble(),
              demandUnit: d['unit'] as String,
              deliveryArea: d['location_area'] as String?,
              deliveryLat: lat,
              deliveryLng: lng,
            )),
          );
          if (placed == true && mounted) Navigator.pop(context, 'ordered');
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: status == 'matched'
                  ? [_amb1, _amb2] : [_c0, _c1, _c2, _c3],
              stops: status == 'matched'
                  ? null : const [0.0, 0.3, 0.7, 1.0],
              begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                  color: (status == 'matched' ? _amb2 : _c2).withOpacity(.45),
                  blurRadius: 22, spreadRadius: -2, offset: const Offset(0, 10)),
            ],
            border: Border.all(color: Colors.white.withOpacity(.1)),
          ),
          child: Row(children: [
            Container(width: 52, height: 52,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(.18),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(.3)),
              ),
              child: Icon(
                status == 'matched'
                    ? Icons.handshake_rounded : Icons.travel_explore_rounded,
                color: Colors.white, size: 26)),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(status == 'matched' ? 'View Matches' : 'Find Suppliers',
                  style: const TextStyle(color: Colors.white, fontSize: 17,
                      fontWeight: FontWeight.w900, letterSpacing: -.2)),
              const SizedBox(height: 4),
              Text(status == 'matched'
                  ? 'Suppliers responded — browse and place order'
                  : 'See nearby stockholders within 10 km',
                  style: TextStyle(color: Colors.white.withOpacity(.7),
                      fontSize: 12.5, height: 1.3)),
            ])),
            Container(width: 36, height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(.18), shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withOpacity(.3))),
              child: const Icon(Icons.arrow_forward_rounded,
                  color: Colors.white, size: 18)),
          ]),
        ),
      ),

      // Cancel button (only when open)
      if (status == 'open') ...[
        const SizedBox(height: 14),
        _Tap(
          onTap: _busy ? () {} : _confirmCancel,
          child: Container(
            width: double.infinity,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _red2.withOpacity(.45), width: 1.5),
              boxShadow: [BoxShadow(color: _red2.withOpacity(.12),
                  blurRadius: 14, offset: const Offset(0, 5))],
            ),
            child: Center(child: _busy
                ? const SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(
                        color: _red2, strokeWidth: 2.5))
                : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.cancel_outlined, color: _red2, size: 20),
                    const SizedBox(width: 8),
                    const Text('Cancel Demand',
                        style: TextStyle(color: _red2, fontSize: 15,
                            fontWeight: FontWeight.w800)),
                  ])),
          ),
        ),
      ],
    ]);
  }

  // ── fulfilled completion banner ───────────────────────────────────────────
  Widget _fulfilledBanner(Map<String, dynamic> d) => Column(children: [
    // green completion card
    Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [_grn1, _grn2],
            begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [BoxShadow(color: _grn2.withOpacity(.4),
            blurRadius: 22, spreadRadius: -2, offset: const Offset(0, 10))],
      ),
      child: Column(children: [
        Row(children: [
          Container(width: 56, height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.2),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(.35), width: 2),
            ),
            child: const Icon(Icons.check_circle_rounded,
                color: Colors.white, size: 30)),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Delivery Completed',
                style: TextStyle(color: Colors.white,
                    fontSize: 18, fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            Text('${d['product_name']} · ${d['variant_name']}',
                style: TextStyle(color: Colors.white.withOpacity(.8),
                    fontSize: 13, fontWeight: FontWeight.w600)),
          ])),
        ]),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(.15),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withOpacity(.25)),
          ),
          child: Row(children: [
            _completionStat(Icons.scale_rounded,
                '${d['quantity']} ${d['unit']}', 'Ordered'),
            _completionDivider(),
            _completionStat(Icons.place_rounded,
                (d['location_area'] ?? '').toString().isNotEmpty
                    ? d['location_area'] as String : 'Your location',
                'Delivered to'),
            _completionDivider(),
            _completionStat(Icons.access_time_rounded,
                _timeAgo(d['created_at'] as String?), 'Posted'),
          ]),
        ),
      ]),
    ),
    const SizedBox(height: 14),
    // "View My Orders" shortcut
    _Tap(
      onTap: () => Navigator.pop(context),
      child: Container(
        width: double.infinity, height: 52,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _grn2.withOpacity(.4), width: 1.5),
          boxShadow: [BoxShadow(color: _grn2.withOpacity(.12),
              blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.receipt_long_rounded, color: _grn1, size: 18),
          const SizedBox(width: 8),
          const Text('Back to My Demands',
              style: TextStyle(color: _grn1, fontSize: 14,
                  fontWeight: FontWeight.w800)),
        ]),
      ),
    ),
  ]);

  Widget _completionStat(IconData icon, String value, String label) =>
    Expanded(child: Column(children: [
      Icon(icon, color: Colors.white70, size: 15),
      const SizedBox(height: 5),
      Text(value, maxLines: 1, overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white,
              fontSize: 12.5, fontWeight: FontWeight.w800)),
      const SizedBox(height: 2),
      Text(label, style: TextStyle(
          color: Colors.white.withOpacity(.65), fontSize: 10.5)),
    ]));

  Widget _completionDivider() => Container(
      width: 1, height: 44,
      color: Colors.white.withOpacity(.25),
      margin: const EdgeInsets.symmetric(horizontal: 4));

  // ── helpers ───────────────────────────────────────────────────────────────
  BoxDecoration _cardDeco() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(22),
    boxShadow: [
      BoxShadow(color: _c1.withOpacity(.08), blurRadius: 20, offset: const Offset(0, 6)),
      BoxShadow(color: Colors.black.withOpacity(.03), blurRadius: 4, offset: const Offset(0, 2)),
    ],
  );

  Widget _infoRow({
    required IconData icon, required Color iconColor,
    required String label, required String value, bool valueBold = false,
  }) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(children: [
      Container(width: 34, height: 34,
        decoration: BoxDecoration(
          color: iconColor.withOpacity(.1),
          borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: iconColor, size: 17)),
      const SizedBox(width: 12),
      SizedBox(width: 80,
        child: Text(label, style: const TextStyle(
            fontSize: 13, color: _sub, fontWeight: FontWeight.w500))),
      Expanded(child: Text(value, style: TextStyle(
          fontSize: 14, color: _txt,
          fontWeight: valueBold ? FontWeight.w800 : FontWeight.w600))),
    ]),
  );

  Widget _divider() => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Divider(height: 1, color: Colors.grey.shade100),
  );

  Widget _blob(double sz, Color c, double op) =>
      Container(width: sz, height: sz,
          decoration: BoxDecoration(shape: BoxShape.circle,
              color: c.withOpacity(op)));
}
