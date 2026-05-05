import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/stock_service.dart';
import '../../services/profile_service.dart';
import '../../services/location_service.dart';
import '../shared/location_picker_screen.dart';

const _sg0 = Color(0xFF012B1E);
const _sg1 = Color(0xFF054F3A);
const _sg2 = Color(0xFF0A7A56);
const _sg3 = Color(0xFF0FBB84);
const _bg  = Color(0xFFF0FBF6);
const _txt = Color(0xFF212121);
const _sub = Color(0xFF757575);
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
class NearbyDemandsScreen extends StatefulWidget {
  const NearbyDemandsScreen({super.key});
  @override State<NearbyDemandsScreen> createState() => _NDS();
}

class _NDS extends State<NearbyDemandsScreen> {
  int _filter = 0;
  bool _loading = true;
  bool _hasLocation = true;
  double? _currentLat;
  double? _currentLng;
  String _locLabel = '';
  List<Map<String, dynamic>> _demands = [];

  final _cats = ['All', 'Grocery', 'Pharmacy', 'Stationary', 'Hardware'];

  @override
  void initState() { super.initState(); _checkLocationThenLoad(); }

  Future<void> _checkLocationThenLoad() async {
    setState(() => _loading = true);
    final profile = await ProfileService.getProfile();
    if (!mounted) return;
    final prof = (profile?['profile'] as Map<String, dynamic>?) ?? {};
    final lat = (prof['lat'] as num?)?.toDouble();
    final lng = (prof['lng'] as num?)?.toDouble();
    final area = (prof['area'] as String?) ?? '';
    final dist = (prof['district'] as String?) ?? '';
    final locationSet = lat != null && lat != 0.0 && lng != null && lng != 0.0;
    setState(() {
      _hasLocation = locationSet;
      _currentLat = lat;
      _currentLng = lng;
      _locLabel = [area, if (dist.isNotEmpty && dist != area) dist].join(', ');
    });
    if (locationSet) {
      await _load();
    } else {
      setState(() => _loading = false);
    }
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = await StockService.getNearbyDemands();
    if (!mounted) return;
    setState(() { _demands = list; _loading = false; });
  }

  Future<void> _pickLocation() async {
    final result = await Navigator.push<LocationResult>(
      context,
      MaterialPageRoute(builder: (_) => LocationPickerScreen(
        title: 'Set Warehouse Location',
        initialLat: _currentLat,
        initialLng: _currentLng,
      )),
    );
    if (result == null || !mounted) return;
    await ProfileService.saveLocation(result);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: _sg1,
      content: const Text('Location saved. Loading nearby demands...',
          style: TextStyle(fontWeight: FontWeight.w600))));
    _checkLocationThenLoad();
  }

  List<Map<String, dynamic>> get _filtered {
    if (_filter == 0) return _demands;
    return _demands.where((d) => d['category'] == _cats[_filter]).toList();
  }

  void _open(Map<String, dynamic> d) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(width: 44, height: 44,
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [_sg1, _sg3]),
                shape: BoxShape.circle),
              child: const Icon(Icons.shopping_basket_rounded, color: Colors.white, size: 22)),
            const SizedBox(width: 12),
            Expanded(child: Text((d['product'] as String?) ?? '',
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: _txt))),
          ]),
          const SizedBox(height: 16),
          _dRow(Icons.store_outlined, 'Shop', '${d['shop']}'),
          const SizedBox(height: 8),
          _dRow(Icons.person_outline, 'Owner', '${d['owner']}'),
          const SizedBox(height: 8),
          _dRow(Icons.scale_rounded, 'Needed', '${d['qty']}'),
          const SizedBox(height: 8),
          _dRow(Icons.near_me_rounded, 'Distance', '${(d['distance'] as num?)?.toStringAsFixed(1) ?? '?'} km away'),
          if (((d['notes'] ?? '') as String).isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: _bg, borderRadius: BorderRadius.circular(10)),
              child: Text('"${d['notes']}"',
                  style: const TextStyle(fontSize: 12.5,
                      fontStyle: FontStyle.italic, color: _sub))),
          ],
          const SizedBox(height: 20),
          _Tap(onTap: () {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              backgroundColor: _sg1,
              content: const Text('Post matching stock to fulfill this demand.',
                  style: TextStyle(fontWeight: FontWeight.w600))));
          },
            child: Container(width: double.infinity, height: 48,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [_sg1, _sg3]),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: _sg3.withOpacity(.3),
                    blurRadius: 12, offset: const Offset(0, 4))],
              ),
              child: const Center(child: Text('Post Matching Stock',
                  style: TextStyle(color: Colors.white,
                      fontWeight: FontWeight.w900, fontSize: 14))))),
        ])),
      ),
    );
  }

  Widget _dRow(IconData icon, String label, String value) => Row(children: [
    Icon(icon, size: 16, color: _sg2),
    const SizedBox(width: 8),
    Text('$label: ', style: const TextStyle(color: _sub, fontSize: 13)),
    Expanded(child: Text(value, style: const TextStyle(
        fontWeight: FontWeight.w700, fontSize: 13, color: _txt))),
  ]);

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _bg,
    body: Column(children: [
      _buildHeader(),
      // category chips
      SizedBox(height: 50,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          itemCount: _cats.length,
          itemBuilder: (_, i) {
            final sel = _filter == i;
            return _Tap(onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _filter = i);
            },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  gradient: sel ? const LinearGradient(colors: [_sg1, _sg3]) : null,
                  color: sel ? null : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: sel ? Colors.transparent : const Color(0xFFD0EDE0)),
                  boxShadow: sel ? [BoxShadow(color: _sg3.withOpacity(.25),
                      blurRadius: 6, offset: const Offset(0, 2))] : null,
                ),
                child: Text(_cats[i], style: TextStyle(
                    fontSize: 12.5, fontWeight: FontWeight.w700,
                    color: sel ? Colors.white : _txt)),
              ));
          },
        )),
      Expanded(child: _loading
          ? const Center(child: CircularProgressIndicator(color: _sg2))
          : !_hasLocation
              ? _noLocation()
              : RefreshIndicator(
                  color: _sg2,
                  onRefresh: _load,
                  child: _filtered.isEmpty
                      ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                          Container(width: 64, height: 64,
                            decoration: BoxDecoration(color: _sg3.withOpacity(.1), shape: BoxShape.circle),
                            child: const Icon(Icons.search_off_rounded, color: _sg2, size: 30)),
                          const SizedBox(height: 14),
                          const Text('No demands in this category',
                              style: TextStyle(color: _sub, fontSize: 13)),
                        ]))
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                          itemCount: _filtered.length,
                          itemBuilder: (_, i) => _card(_filtered[i])),
                )),
    ]),
  );

  Widget _buildHeader() => Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        colors: [_sg0, _sg1, _sg2, _sg3],
        stops: [0.0, 0.35, 0.7, 1.0],
        begin: Alignment.topLeft, end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.only(
        bottomLeft: Radius.circular(28), bottomRight: Radius.circular(28)),
    ),
    child: SafeArea(bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 20, 16),
        child: Column(children: [
          Row(children: [
            _Tap(onTap: () => Navigator.maybePop(context),
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
              Text('Nearby Demands', style: TextStyle(color: Colors.white,
                  fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -.4)),
              SizedBox(height: 2),
              Text('Open demands within 10 km',
                  style: TextStyle(color: Colors.white54, fontSize: 12.5)),
            ])),
            _Tap(onTap: _pickLocation,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(.18),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(.25)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.edit_location_alt_rounded, color: Colors.white, size: 14),
                  const SizedBox(width: 5),
                  Text(_hasLocation ? 'Change' : 'Set Location',
                      style: const TextStyle(color: Colors.white,
                          fontWeight: FontWeight.w800, fontSize: 12)),
                ]))),
          ]),
          if (_hasLocation) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(children: [
                const Icon(Icons.info_outline, color: Colors.white70, size: 16),
                const SizedBox(width: 8),
                Expanded(child: Text(
                    _loading ? 'Loading nearby demands...'
                        : 'Showing ${_demands.length} open demands',
                    style: const TextStyle(color: Colors.white70, fontSize: 12.5))),
                if (_locLabel.isNotEmpty)
                  Text(_locLabel, style: const TextStyle(
                      color: Colors.white54, fontSize: 11)),
              ]),
            ),
          ],
        ]),
      ),
    ),
  );

  Widget _noLocation() => Center(child: Padding(
    padding: const EdgeInsets.all(32),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 84, height: 84,
        decoration: BoxDecoration(color: _amb2.withOpacity(.1), shape: BoxShape.circle),
        child: const Icon(Icons.location_off_rounded, color: _amb1, size: 40)),
      const SizedBox(height: 20),
      const Text('Location Not Set', style: TextStyle(
          fontSize: 19, fontWeight: FontWeight.w900, color: _txt)),
      const SizedBox(height: 10),
      const Text(
          'Set your warehouse location to see open demands from nearby shops within 10 km.',
          textAlign: TextAlign.center,
          style: TextStyle(color: _sub, fontSize: 13.5, height: 1.5)),
      const SizedBox(height: 28),
      _Tap(onTap: _pickLocation,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [_sg1, _sg3]),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: _sg3.withOpacity(.35),
                blurRadius: 14, offset: const Offset(0, 6))],
          ),
          child: const Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.my_location_rounded, color: Colors.white, size: 18),
            SizedBox(width: 10),
            Text('Set My Location', style: TextStyle(color: Colors.white,
                fontSize: 15, fontWeight: FontWeight.w900)),
          ]))),
    ]),
  ));

  Widget _card(Map<String, dynamic> d) => _Tap(
    onTap: () => _open(d),
    child: Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: _sg1.withOpacity(.06), blurRadius: 14, offset: const Offset(0, 4)),
          BoxShadow(color: Colors.black.withOpacity(.03), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(width: 46, height: 46,
              decoration: BoxDecoration(
                color: _sg3.withOpacity(.15), borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.shopping_basket_rounded, color: _sg2, size: 24)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text((d['product'] as String?) ?? '',
                  style: const TextStyle(fontSize: 15,
                      fontWeight: FontWeight.w800, color: _txt)),
              Text('${d['shop']} • ${d['category']}',
                  style: const TextStyle(fontSize: 12, color: _sub)),
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text((d['qty'] as String?) ?? '',
                  style: const TextStyle(fontSize: 16,
                      fontWeight: FontWeight.w900, color: _sg2)),
              const Text('needed', style: TextStyle(fontSize: 11, color: _sub)),
            ]),
          ]),
          const SizedBox(height: 12),
          Wrap(spacing: 6, runSpacing: 6, children: [
            _pill(Icons.near_me_rounded,
                '${(d['distance'] as num?)?.toStringAsFixed(1) ?? '?'} km', _sg2),
            _pill(Icons.place_outlined, (d['area'] as String?) ?? '', _sub),
            _pill(Icons.access_time_rounded, (d['time'] as String?) ?? '', _sub),
          ]),
          if (((d['notes'] ?? '') as String).isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: _bg, borderRadius: BorderRadius.circular(8)),
              child: Text('"${d['notes']}"',
                  style: const TextStyle(fontSize: 12,
                      fontStyle: FontStyle.italic, color: _sub))),
          ],
          const SizedBox(height: 12),
          _Tap(onTap: () => _open(d),
            child: Container(width: double.infinity, height: 38,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [_sg1, _sg3]),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [BoxShadow(color: _sg3.withOpacity(.25),
                    blurRadius: 8, offset: const Offset(0, 3))],
              ),
              child: const Center(child: Text('View Details',
                  style: TextStyle(color: Colors.white,
                      fontWeight: FontWeight.w800, fontSize: 13))))),
        ]),
      ),
    ),
  );

  Widget _pill(IconData icon, String text, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
    decoration: BoxDecoration(
      color: color.withOpacity(.1), borderRadius: BorderRadius.circular(8)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 12, color: color),
      const SizedBox(width: 4),
      Text(text, style: TextStyle(
          fontSize: 11, fontWeight: FontWeight.w700, color: color)),
    ]),
  );
}
