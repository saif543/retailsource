import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/stock_service.dart';
import '../../services/location_service.dart';
import '../shared/location_picker_screen.dart';

const _sp0 = Color(0xFF16002E);
const _sp1 = Color(0xFF3B0D6B);
const _sp2 = Color(0xFF7B2FD4);
const _sp3 = Color(0xFFBB6BF7);
const _bg  = Color(0xFFF8F0FF);
const _txt = Color(0xFF212121);
const _sub = Color(0xFF757575);
const _red1 = Color(0xFF7B1C1C);
const _red2 = Color(0xFFEF5350);

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
class EditStockScreen extends StatefulWidget {
  final Map<String, dynamic> stock;
  const EditStockScreen({super.key, required this.stock});
  @override State<EditStockScreen> createState() => _ESS();
}

class _ESS extends State<EditStockScreen> {
  late final TextEditingController _qty;
  late final TextEditingController _price;
  late final TextEditingController _notes;
  late String _status;
  LocationResult? _loc;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final s = widget.stock;
    _qty   = TextEditingController(text: (s['qty']   as String? ?? '').replaceAll(RegExp(r'\D'), ''));
    _price = TextEditingController(text: (s['price'] as String? ?? '').replaceAll(RegExp(r'[^0-9.]'), ''));
    _notes = TextEditingController(text: (s['notes'] as String?) ?? '');
    _status = (s['status'] as String?) ?? 'Available';

    final lat = (s['lat'] as num?)?.toDouble();
    final lng = (s['lng'] as num?)?.toDouble();
    final loc = (s['loc'] as String?) ?? '';
    if (lat != null && lat != 0 && lng != null && lng != 0) {
      _loc = LocationResult(lat: lat, lng: lng,
          address: loc.isNotEmpty ? loc : '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}',
          area: loc, district: '');
    }
  }

  @override
  void dispose() {
    _qty.dispose(); _price.dispose(); _notes.dispose();
    super.dispose();
  }

  Future<void> _pickLoc() async {
    final r = await Navigator.push<LocationResult>(context,
      MaterialPageRoute(builder: (_) => LocationPickerScreen(
        title: 'Warehouse Location',
        initialLat: _loc?.lat, initialLng: _loc?.lng)));
    if (r != null && mounted) setState(() => _loc = r);
  }

  Future<void> _save() async {
    final qty   = double.tryParse(_qty.text);
    final price = double.tryParse(_price.text);
    if (qty == null || price == null) {
      _err('Enter valid numbers for quantity and price'); return;
    }
    HapticFeedback.mediumImpact();
    final stockId = widget.stock['stock_id'] as int?;
    if (stockId != null) {
      setState(() => _saving = true);
      final res = await StockService.updateStock(
        stockId,
        quantity: qty, price: price,
        warehouseArea: _loc != null
            ? (_loc!.area.isNotEmpty ? _loc!.area : _loc!.address) : null,
        lat: _loc?.lat,
        lng: _loc?.lng,
        notes: _notes.text.trim(),
        status: _status == 'Available' ? 'available' : 'sold_out',
      );
      if (!mounted) return;
      setState(() => _saving = false);
      if (!res.ok) { _err(res.error ?? 'Failed to update stock'); return; }
    }
    HapticFeedback.heavyImpact();
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Padding(padding: const EdgeInsets.all(28), child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 68, height: 68,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [_sp1, _sp3],
                  begin: Alignment.topLeft, end: Alignment.bottomRight),
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: _sp3.withOpacity(.4),
                  blurRadius: 16, offset: const Offset(0, 4))],
            ),
            child: const Icon(Icons.check_rounded, color: Colors.white, size: 34)),
          const SizedBox(height: 16),
          const Text('Stock Updated', style: TextStyle(
              fontSize: 19, fontWeight: FontWeight.w900, color: _txt)),
          const SizedBox(height: 8),
          const Text('Your changes have been saved successfully.',
              textAlign: TextAlign.center, style: TextStyle(color: _sub, fontSize: 13.5)),
          const SizedBox(height: 22),
          _Tap(onTap: () { Navigator.pop(context); Navigator.pop(context, true); },
            child: Container(width: double.infinity, height: 50,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [_sp1, _sp3]),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: _sp3.withOpacity(.35),
                    blurRadius: 12, offset: const Offset(0, 4))],
              ),
              child: const Center(child: Text('Done',
                  style: TextStyle(color: Colors.white,
                      fontSize: 16, fontWeight: FontWeight.w900))))),
        ])),
      ),
    );
  }

  Future<void> _confirmDelete() async {
    HapticFeedback.mediumImpact();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 56, height: 56,
            decoration: BoxDecoration(color: _red2.withOpacity(.1), shape: BoxShape.circle),
            child: const Icon(Icons.delete_outline, color: _red2, size: 28)),
          const SizedBox(height: 16),
          const Text('Delete this stock?', style: TextStyle(
              fontSize: 18, fontWeight: FontWeight.w900, color: _txt)),
          const SizedBox(height: 8),
          const Text('This action cannot be undone.',
              textAlign: TextAlign.center, style: TextStyle(color: _sub, fontSize: 13)),
          const SizedBox(height: 22),
          Row(children: [
            Expanded(child: _Tap(onTap: () => Navigator.pop(context, false),
              child: Container(height: 46,
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFE0E0E0)),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Center(child: Text('Cancel',
                    style: TextStyle(fontWeight: FontWeight.w700, color: _sub)))))),
            const SizedBox(width: 12),
            Expanded(child: _Tap(onTap: () => Navigator.pop(context, true),
              child: Container(height: 46,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [_red1, _red2]),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Center(child: Text('Delete',
                    style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white)))))),
          ]),
        ])),
      ),
    );
    if (confirm != true || !mounted) return;
    final stockId = widget.stock['stock_id'] as int?;
    if (stockId != null) {
      final res = await StockService.deleteStock(stockId);
      if (!mounted) return;
      if (!res.ok) { _err(res.error ?? 'Failed to delete stock'); return; }
    }
    if (mounted) Navigator.pop(context, 'deleted');
  }

  void _err(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: _red1,
      content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600))));

  @override
  Widget build(BuildContext context) {
    final s = widget.stock;
    return Scaffold(
      backgroundColor: _bg,
      body: Column(children: [
        _buildHeader(s),
        Expanded(child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

            // Product info (read-only)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE8D5FF)),
              ),
              child: Row(children: [
                Container(width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: _sp3.withOpacity(.15), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.inventory_2_rounded, color: _sp2, size: 22)),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text((s['product'] as String?) ?? 'Stock Item',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: _txt)),
                  const Text('Product info cannot be changed',
                      style: TextStyle(color: _sub, fontSize: 11.5)),
                ])),
              ]),
            ),
            const SizedBox(height: 16),

            _card(title: 'Status', icon: Icons.toggle_on_rounded,
              child: Row(children: [
                _statusChip('Available', const [_sp1, _sp3]),
                const SizedBox(width: 10),
                _statusChip('Sold Out', const [_red1, _red2]),
              ])),
            const SizedBox(height: 14),

            _card(title: 'Quantity & Price', icon: Icons.scale_rounded,
              child: Column(children: [
                _fieldLabel('Available Quantity *'),
                _field(_qty, keyboard: TextInputType.number),
                const SizedBox(height: 12),
                _fieldLabel('Price per Unit (৳) *'),
                _field(_price, keyboard: TextInputType.number),
              ])),
            const SizedBox(height: 14),

            _card(title: 'Location & Notes', icon: Icons.warehouse_rounded,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _fieldLabel('Warehouse Location'),
                _locationCard(),
                const SizedBox(height: 12),
                _fieldLabel('Additional Notes'),
                _field(_notes, lines: 3),
              ])),
            const SizedBox(height: 28),

            _Tap(onTap: _saving ? () {} : _save,
              child: Container(width: double.infinity, height: 56,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_sp0, _sp2, _sp3],
                    stops: [0.0, 0.5, 1.0],
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [BoxShadow(color: _sp3.withOpacity(.4),
                      blurRadius: 22, spreadRadius: -2, offset: const Offset(0, 10))],
                ),
                child: Stack(children: [
                  Positioned.fill(child: ClipRRect(borderRadius: BorderRadius.circular(18),
                    child: Align(alignment: Alignment.topCenter,
                      child: FractionallySizedBox(heightFactor: .45, widthFactor: 1,
                        child: Container(decoration: BoxDecoration(
                          gradient: LinearGradient(begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.white.withOpacity(.18), Colors.transparent]))))))),
                  Center(child: _saving
                      ? const SizedBox(width: 22, height: 22,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                      : const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Icon(Icons.save_rounded, color: Colors.white, size: 20),
                          SizedBox(width: 10),
                          Text('Save Changes', style: TextStyle(color: Colors.white,
                              fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: .2)),
                        ])),
                ])),
            ),
          ]),
        )),
      ]),
    );
  }

  Widget _buildHeader(Map<String, dynamic> s) => Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        colors: [_sp0, _sp1, _sp2, _sp3],
        stops: [0.0, 0.35, 0.7, 1.0],
        begin: Alignment.topLeft, end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.only(
        bottomLeft: Radius.circular(28), bottomRight: Radius.circular(28)),
    ),
    child: SafeArea(bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 20, 24),
        child: Row(children: [
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
            const Text('Edit Stock', style: TextStyle(color: Colors.white,
                fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -.4)),
            const SizedBox(height: 2),
            Text((s['product'] as String?) ?? 'Stock Item',
                style: const TextStyle(color: Colors.white60, fontSize: 12.5)),
          ])),
          _Tap(onTap: _confirmDelete,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _red2.withOpacity(.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _red2.withOpacity(.4)),
              ),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.delete_outline, color: Colors.white, size: 15),
                SizedBox(width: 5),
                Text('Delete', style: TextStyle(color: Colors.white,
                    fontWeight: FontWeight.w800, fontSize: 12)),
              ]))),
        ]),
      ),
    ),
  );

  Widget _locationCard() => _Tap(onTap: _pickLoc,
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _bg, borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: _loc != null ? _sp2.withOpacity(.5) : const Color(0xFFE8D5FF),
            width: _loc != null ? 1.5 : 1),
      ),
      child: Row(children: [
        Container(width: 44, height: 44,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _loc != null ? const [_sp1, _sp3]
                  : [const Color(0xFFE8D5FF), const Color(0xFFEEDDFF)],
              begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(12),
            boxShadow: _loc != null ? [BoxShadow(color: _sp3.withOpacity(.3),
                blurRadius: 8, offset: const Offset(0, 3))] : null,
          ),
          child: Icon(Icons.warehouse_rounded,
              color: _loc != null ? Colors.white : _sub, size: 20)),
        const SizedBox(width: 12),
        Expanded(child: _loc != null
            ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(_loc!.address, maxLines: 2, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13.5,
                        fontWeight: FontWeight.w700, color: _txt)),
                const SizedBox(height: 3),
                Text('Tap to change warehouse location',
                    style: TextStyle(fontSize: 11, color: _sp2.withOpacity(.8),
                        fontWeight: FontWeight.w500)),
              ])
            : const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('No location set', style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w700, color: _txt)),
                SizedBox(height: 3),
                Text('Tap to pick on map or use GPS', style: TextStyle(
                    fontSize: 12, color: _sub)),
              ])),
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: _sp2.withOpacity(.1), shape: BoxShape.circle),
          child: Icon(Icons.chevron_right_rounded, color: _sp2, size: 18)),
      ]),
    ),
  );

  Widget _card({required String title, required IconData icon, required Widget child}) =>
    Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: _sp1.withOpacity(.06), blurRadius: 14, offset: const Offset(0, 4)),
          BoxShadow(color: Colors.black.withOpacity(.03), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 30, height: 30,
            decoration: BoxDecoration(
              color: _sp3.withOpacity(.15), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, size: 15, color: _sp2)),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(
              fontSize: 13.5, fontWeight: FontWeight.w900, color: _txt)),
        ]),
        const SizedBox(height: 14),
        child,
      ]),
    );

  Widget _statusChip(String value, List<Color> colors) {
    final sel = _status == value;
    return Expanded(child: _Tap(onTap: () {
      HapticFeedback.selectionClick();
      setState(() => _status = value);
    },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          gradient: sel ? LinearGradient(colors: colors) : null,
          color: sel ? null : _bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: sel ? Colors.transparent : const Color(0xFFE8D5FF)),
          boxShadow: sel ? [BoxShadow(color: colors.last.withOpacity(.3),
              blurRadius: 8, offset: const Offset(0, 3))] : null,
        ),
        child: Text(value, textAlign: TextAlign.center,
            style: TextStyle(
                color: sel ? Colors.white : _sub,
                fontWeight: FontWeight.w800, fontSize: 13.5)),
      )));
  }

  Widget _fieldLabel(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 8, left: 2),
    child: Text(t, style: const TextStyle(
        fontSize: 12.5, fontWeight: FontWeight.w800, color: _txt)),
  );

  Widget _field(TextEditingController c,
      {TextInputType? keyboard, int lines = 1}) => TextField(
    controller: c, keyboardType: keyboard, maxLines: lines,
    style: const TextStyle(fontSize: 14.5, color: _txt, fontWeight: FontWeight.w600),
    decoration: InputDecoration(
      filled: true, fillColor: _bg,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE8D5FF))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _sp2.withOpacity(.6), width: 1.5)),
    ),
  );
}
