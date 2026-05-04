import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/demand_service.dart';
import '../../services/location_service.dart';
import '../../services/profile_service.dart';
import '../shared/location_picker_screen.dart';

// ── palette (mirrors dashboard) ───────────────────────────────────────────────
const _c0  = Color(0xFF060D28);
const _c1  = Color(0xFF0E2260);
const _c2  = Color(0xFF1F4BD5);
const _c3  = Color(0xFF6C3FE8);
const _bg  = Color(0xFFF2F5FF);
const _txt = Color(0xFF212121);
const _sub = Color(0xFF757575);

// category accent colours
const _catColors = {
  'Grocery'   : [Color(0xFFAD4A0A), Color(0xFFF5981E)],
  'Pharmacy'  : [Color(0xFF7B1C1C), Color(0xFFEF5350)],
  'Stationary': [Color(0xFF1840AF), Color(0xFF4F8EF7)],
  'Hardware'  : [Color(0xFF1B4D3E), Color(0xFF26A17B)],
};
const _catEmoji = {
  'Grocery': '🛒', 'Pharmacy': '💊',
  'Stationary': '✏️', 'Hardware': '🔧',
};
const _catDesc = {
  'Grocery'   : 'Rice, oil, sugar & more',
  'Pharmacy'  : 'Medicine & health items',
  'Stationary': 'Paper, pens & office',
  'Hardware'  : 'Cement, paint & tools',
};

const _units = ['kg', 'litre', 'piece', 'pack'];

// ── press-scale tap wrapper ───────────────────────────────────────────────────
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
class PostDemandScreen extends StatefulWidget {
  const PostDemandScreen({super.key});
  @override State<PostDemandScreen> createState() => _PostDemandScreenState();
}

class _PostDemandScreenState extends State<PostDemandScreen>
    with SingleTickerProviderStateMixin {

  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _products   = [];
  List<Map<String, dynamic>> _variants   = [];

  Map<String, dynamic>? _selCat, _selProd, _selVar;
  String _unit = 'kg';
  final _qtyC   = TextEditingController();
  final _notesC = TextEditingController();
  final _searchC = TextEditingController();
  String _q = '';

  LocationResult? _loc;
  bool _loadCats = true, _loadProds = false, _submitting = false;

  late final _fadeC = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 420));
  late final _fade  = CurvedAnimation(parent: _fadeC, curve: Curves.easeOut);

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _prefillLoc();
    _fadeC.forward();
  }

  @override
  void dispose() {
    _qtyC.dispose(); _notesC.dispose(); _searchC.dispose();
    _fadeC.dispose();
    super.dispose();
  }

  Future<void> _prefillLoc() async {
    // 1. Use local cache instantly — no network wait
    final cached = await ProfileService.getCachedLocation();
    if (cached != null && mounted) setState(() => _loc = cached);

    // 2. Sync from network in the background; update if different
    final profile = await ProfileService.getProfile();
    if (!mounted) return;
    final prof = (profile?['profile'] as Map?) ?? {};
    final lat = (prof['lat'] as num?)?.toDouble();
    final lng = (prof['lng'] as num?)?.toDouble();
    if (lat != null && lat != 0 && lng != null && lng != 0) {
      final addr = (prof['shop_address'] as String?) ?? '';
      setState(() => _loc = LocationResult(
        lat: lat, lng: lng,
        address: addr.isNotEmpty ? addr : '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}',
        area:     (prof['area']     as String?) ?? '',
        district: (prof['district'] as String?) ?? '',
      ));
    }
  }

  Future<void> _loadCategories() async {
    final cats = await DemandService.getCategories();
    if (!mounted) return;
    setState(() { _categories = cats; _loadCats = false; });
  }

  Future<void> _pickCat(Map<String, dynamic> cat) async {
    HapticFeedback.lightImpact();
    setState(() {
      _selCat = cat; _selProd = null; _selVar = null;
      _products = []; _variants = [];
      _q = ''; _searchC.clear(); _loadProds = true;
    });
    final prods = await DemandService.getProductsByCategory(cat['category_id'] as int);
    if (!mounted) return;
    setState(() { _products = prods; _loadProds = false; });
  }

  void _pickProd(Map<String, dynamic> p) {
    HapticFeedback.lightImpact();
    setState(() {
      _selProd = p;
      _variants = List<Map<String, dynamic>>.from(p['variants'] ?? []);
      _selVar = _variants.length == 1 ? _variants.first : null;
    });
  }

  Future<void> _pickLoc() async {
    final r = await Navigator.push<LocationResult>(context,
      MaterialPageRoute(builder: (_) => LocationPickerScreen(
        title: 'Delivery Location',
        initialLat: _loc?.lat, initialLng: _loc?.lng)));
    if (r != null && mounted) setState(() => _loc = r);
  }

  Future<void> _submit() async {
    if (_selCat  == null) return _err('Pick a category');
    if (_selProd == null) return _err('Pick a product');
    if (_selVar  == null) return _err('Pick a variant');
    final qty = double.tryParse(_qtyC.text.trim());
    if (qty == null || qty <= 0) return _err('Enter a valid quantity');
    if (_loc == null) return _err('Set your delivery location');

    final ok = await showDialog<bool>(context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Text('Post this demand?',
            style: TextStyle(fontWeight: FontWeight.w800)),
        content: Text(
          '${qty % 1 == 0 ? qty.toInt() : qty} $_unit of '
          '${_selProd!['name']} (${_selVar!['variant_name']}) '
          'in ${_loc!.area.isNotEmpty ? _loc!.area : 'your location'}.\n\n'
          'Nearby suppliers will be notified.',
          style: const TextStyle(color: _sub, height: 1.5)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
              child: const Text('Edit')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD03800),
                foregroundColor: Colors.white, elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: const Text('Post Now', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (ok != true) return;

    setState(() => _submitting = true);
    final res = await DemandService.createDemand(
      productId: _selProd!['product_id'] as int,
      variantId: _selVar!['variant_id'] as int,
      quantity: qty, unit: _unit,
      locationArea: _loc!.area.isNotEmpty ? _loc!.area : null,
      lat: _loc!.lat, lng: _loc!.lng,
      notes: _notesC.text.trim(),
    );
    if (!mounted) return;
    setState(() => _submitting = false);

    if (res['statusCode'] == 201) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        backgroundColor: Color(0xFF2E7D32),
        content: Text('Demand posted! Suppliers will be notified.',
            style: TextStyle(fontWeight: FontWeight.w600))));
      Navigator.pop(context, true);
    } else {
      _err(res['error']?.toString() ?? 'Failed to post demand');
    }
  }

  void _err(String msg) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(backgroundColor: const Color(0xFFC62828), content: Text(msg)));

  // ── current step (1-based) ────────────────────────────────────────────────
  int get _step {
    if (_selCat  == null) return 1;
    if (_selProd == null) return 2;
    if (_selVar  == null) return 3;
    if (_qtyC.text.trim().isEmpty) return 4;
    if (_loc == null) return 5;
    return 6;
  }

  // ════════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: SystemUiOverlayStyle.light,
    child: Scaffold(
      backgroundColor: _bg,
      body: _loadCats
          ? const Center(child: CircularProgressIndicator())
          : FadeTransition(
              opacity: _fade,
              child: Column(children: [
                _header(),
                Expanded(child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    _progressBar(),
                    const SizedBox(height: 28),

                    _sectionTitle(1, 'What do you need?', Icons.category_rounded),
                    const SizedBox(height: 14),
                    _categoryGrid(),

                    if (_selCat != null) ...[
                      const SizedBox(height: 28),
                      _sectionTitle(2, 'Pick a product', Icons.inventory_2_rounded),
                      const SizedBox(height: 14),
                      _loadProds
                          ? _shimmerBox(120)
                          : _productSection(),
                    ],

                    if (_variants.isNotEmpty) ...[
                      const SizedBox(height: 28),
                      _sectionTitle(3, 'Pick type / variant', Icons.tune_rounded),
                      const SizedBox(height: 14),
                      _variantChips(),
                    ],

                    if (_selVar != null) ...[
                      const SizedBox(height: 28),
                      _sectionTitle(4, 'How much?', Icons.scale_rounded),
                      const SizedBox(height: 14),
                      _quantitySection(),

                      const SizedBox(height: 28),
                      _sectionTitle(5, 'Delivery location', Icons.location_on_rounded),
                      const SizedBox(height: 14),
                      _locationCard(),

                      const SizedBox(height: 28),
                      _sectionTitle(6, 'Notes (optional)', Icons.edit_note_rounded),
                      const SizedBox(height: 14),
                      _notesField(),

                      const SizedBox(height: 32),
                      _submitBtn(),
                    ],
                  ]),
                )),
              ]),
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
        // decorative blobs
        Positioned(top: -20, right: -30, child: _blob(130, Colors.white, .04)),
        Positioned(top: 8,   right: 50,  child: _blob(44,  _c2, .35)),
        Positioned(top: 40,  left: -20,  child: _blob(80,  _c3, .22)),
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 20, 22),
          child: Row(children: [
            // back button
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
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Post a Demand',
                  style: TextStyle(color: Colors.white, fontSize: 20,
                      fontWeight: FontWeight.w900, letterSpacing: -.4)),
              const SizedBox(height: 2),
              Text('Suppliers near you respond instantly',
                  style: TextStyle(color: Colors.white.withOpacity(0.65), fontSize: 12.5)),
            ])),
            // step badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.25)),
              ),
              child: Text('Step $_step / 6',
                  style: const TextStyle(color: Colors.white,
                      fontSize: 12, fontWeight: FontWeight.w700)),
            ),
          ]),
        ),
      ]),
    ),
  );

  Widget _blob(double sz, Color c, double op) =>
      Container(width: sz, height: sz,
          decoration: BoxDecoration(shape: BoxShape.circle,
              color: c.withOpacity(op)));

  // ── step progress bar ─────────────────────────────────────────────────────
  Widget _progressBar() {
    const total = 6;
    final done = (_step - 1).clamp(0, total);
    return Column(children: [
      Row(children: List.generate(total, (i) {
        final active  = i < done;
        final current = i == done;
        return Expanded(child: Row(children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 350),
            width: 28, height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: active || current ? const LinearGradient(
                  colors: [_c1, _c3], begin: Alignment.topLeft, end: Alignment.bottomRight)
                  : null,
              color: active || current ? null : Colors.white,
              border: Border.all(
                color: active || current ? _c2 : const Color(0xFFDDE0F0), width: 1.5),
              boxShadow: current ? [BoxShadow(color: _c2.withOpacity(.4),
                  blurRadius: 10, offset: const Offset(0, 3))] : null,
            ),
            child: Center(child: active
                ? const Icon(Icons.check_rounded, color: Colors.white, size: 13)
                : Text('${i + 1}', style: TextStyle(
                    color: current ? Colors.white : _sub,
                    fontSize: 11, fontWeight: FontWeight.w700))),
          ),
          if (i < total - 1) Expanded(child: AnimatedContainer(
            duration: const Duration(milliseconds: 350),
            height: 2,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              gradient: active ? const LinearGradient(colors: [_c1, _c3]) : null,
              color: active ? null : const Color(0xFFDDE0F0),
            ),
          )),
        ]));
      })),
    ]);
  }

  // ── section title ─────────────────────────────────────────────────────────
  Widget _sectionTitle(int n, String label, IconData icon) {
    final done = n < _step;
    return Row(children: [
      Container(width: 36, height: 36,
        decoration: BoxDecoration(
          gradient: done || n == _step
              ? const LinearGradient(colors: [_c1, _c3],
                  begin: Alignment.topLeft, end: Alignment.bottomRight)
              : null,
          color: done || n == _step ? null : Colors.white,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: done || n == _step ? _c2 : const Color(0xFFDDE0F0)),
          boxShadow: n == _step ? [BoxShadow(color: _c2.withOpacity(.3),
              blurRadius: 10, offset: const Offset(0, 4))] : null,
        ),
        child: Icon(done ? Icons.check_rounded : icon,
            color: done || n == _step ? Colors.white : _sub, size: 17)),
      const SizedBox(width: 12),
      Text(label, style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800,
          color: n <= _step ? _txt : _sub, letterSpacing: -.2)),
      if (done) ...[
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF054F3A).withOpacity(0.1),
            borderRadius: BorderRadius.circular(20)),
          child: const Text('Done', style: TextStyle(color: Color(0xFF0FBB84),
              fontSize: 11, fontWeight: FontWeight.w700)),
        ),
      ],
    ]);
  }

  // ── category grid ─────────────────────────────────────────────────────────
  Widget _categoryGrid() => LayoutBuilder(
    builder: (ctx, constraints) {
      final cellW = (constraints.maxWidth - 12) / 2;
      final ratio = cellW / 110;
      return GridView.count(
    crossAxisCount: 2,
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    mainAxisSpacing: 12, crossAxisSpacing: 12,
    childAspectRatio: ratio.clamp(1.1, 1.6),
    children: _categories.map((c) {
      final name = c['name'] as String;
      final colors = _catColors[name] ?? [_c1, _c2];
      final emoji  = _catEmoji[name]  ?? '📦';
      final desc   = _catDesc[name]   ?? '';
      final sel    = _selCat?['category_id'] == c['category_id'];
      return _Tap(onTap: () => _pickCat(c), child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          gradient: sel ? LinearGradient(colors: colors,
              begin: Alignment.topLeft, end: Alignment.bottomRight) : null,
          color: sel ? null : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: sel ? colors.last : const Color(0xFFE4E8F5), width: sel ? 0 : 1.5),
          boxShadow: sel
              ? [BoxShadow(color: colors.last.withOpacity(.42),
                  blurRadius: 20, spreadRadius: -3, offset: const Offset(0, 8))]
              : [BoxShadow(color: _c1.withOpacity(.06),
                  blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Stack(children: [
          if (sel) Positioned(right: -12, bottom: -12,
            child: Text(emoji, style: const TextStyle(fontSize: 56))),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(emoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(height: 8),
              Text(name, style: TextStyle(
                  color: sel ? Colors.white : _txt,
                  fontSize: 14, fontWeight: FontWeight.w800)),
              const SizedBox(height: 3),
              Text(desc, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: sel ? Colors.white.withOpacity(.7) : _sub,
                      fontSize: 11)),
            ]),
          ),
        ]),
      ));
    }).toList(),
      );
    },
  );

  // ── product section ───────────────────────────────────────────────────────
  Widget _productSection() {
    if (_products.isEmpty) return _emptyBox('No products in this category');
    final q = _q.trim().toLowerCase();
    final list = q.isEmpty ? _products
        : _products.where((p) => (p['name'] as String).toLowerCase().contains(q)).toList();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // search
      Container(
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: _c1.withOpacity(.07),
              blurRadius: 14, offset: const Offset(0, 5))],
        ),
        child: TextField(
          controller: _searchC,
          onChanged: (v) => setState(() => _q = v),
          decoration: InputDecoration(
            hintText: 'Search products...',
            hintStyle: TextStyle(color: _sub.withOpacity(.7), fontSize: 13.5),
            prefixIcon: const Icon(Icons.search_rounded, color: _sub, size: 20),
            suffixIcon: _q.isNotEmpty ? IconButton(
              icon: const Icon(Icons.close_rounded, color: _sub, size: 18),
              onPressed: () { _searchC.clear(); setState(() => _q = ''); }) : null,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: _c2, width: 1.5)),
            filled: true, fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
      const SizedBox(height: 14),
      if (list.isEmpty)
        _emptyBox('No products match "$_q"')
      else
        Wrap(spacing: 8, runSpacing: 8,
          children: list.map((p) {
            final sel = _selProd?['product_id'] == p['product_id'];
            return _Tap(onTap: () => _pickProd(p),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                decoration: BoxDecoration(
                  gradient: sel ? const LinearGradient(
                      colors: [_c1, _c3], begin: Alignment.topLeft,
                      end: Alignment.bottomRight) : null,
                  color: sel ? null : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                      color: sel ? _c2 : const Color(0xFFE4E8F5), width: 1.5),
                  boxShadow: sel ? [BoxShadow(color: _c2.withOpacity(.38),
                      blurRadius: 14, offset: const Offset(0, 5))] : null,
                ),
                child: Text(p['name'] as String,
                    style: TextStyle(
                        color: sel ? Colors.white : _txt,
                        fontWeight: FontWeight.w700, fontSize: 13.5)),
              ),
            );
          }).toList()),
    ]);
  }

  // ── variant chips ─────────────────────────────────────────────────────────
  Widget _variantChips() => Wrap(spacing: 8, runSpacing: 8,
    children: _variants.map((v) {
      final sel = _selVar?['variant_id'] == v['variant_id'];
      return _Tap(onTap: () { HapticFeedback.lightImpact(); setState(() => _selVar = v); },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
          decoration: BoxDecoration(
            gradient: sel ? const LinearGradient(
                colors: [Color(0xFF054F3A), Color(0xFF0FBB84)],
                begin: Alignment.topLeft, end: Alignment.bottomRight) : null,
            color: sel ? null : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
                color: sel ? const Color(0xFF0FBB84) : const Color(0xFFE4E8F5),
                width: 1.5),
            boxShadow: sel ? [BoxShadow(color: const Color(0xFF0FBB84).withOpacity(.38),
                blurRadius: 14, offset: const Offset(0, 5))] : null,
          ),
          child: Text(v['variant_name'] as String,
              style: TextStyle(
                  color: sel ? Colors.white : _txt,
                  fontWeight: FontWeight.w700, fontSize: 13.5)),
        ),
      );
    }).toList(),
  );

  // ── quantity section ──────────────────────────────────────────────────────
  Widget _quantitySection() => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white, borderRadius: BorderRadius.circular(22),
      boxShadow: [BoxShadow(color: _c1.withOpacity(.07),
          blurRadius: 16, offset: const Offset(0, 5))],
    ),
    child: Column(children: [
      TextField(
        controller: _qtyC,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        textAlign: TextAlign.center,
        onChanged: (_) => setState(() {}),
        style: const TextStyle(fontSize: 38, fontWeight: FontWeight.w900,
            color: _txt, letterSpacing: -1),
        decoration: const InputDecoration(
          hintText: '0',
          hintStyle: TextStyle(color: Color(0xFFCDD0E3), fontSize: 38,
              fontWeight: FontWeight.w900),
          border: InputBorder.none, enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
      ),
      const Divider(height: 24),
      Row(children: _units.map((u) {
        final sel = _unit == u;
        return Expanded(child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: _Tap(onTap: () => setState(() => _unit = u),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                gradient: sel ? const LinearGradient(
                    colors: [_c1, _c3], begin: Alignment.topLeft,
                    end: Alignment.bottomRight) : null,
                color: sel ? null : const Color(0xFFF2F5FF),
                borderRadius: BorderRadius.circular(12),
                boxShadow: sel ? [BoxShadow(color: _c2.withOpacity(.35),
                    blurRadius: 10, offset: const Offset(0, 4))] : null,
              ),
              alignment: Alignment.center,
              child: Text(u, style: TextStyle(
                  color: sel ? Colors.white : _sub,
                  fontWeight: FontWeight.w800, fontSize: 13.5)),
            ),
          ),
        ));
      }).toList()),
    ]),
  );

  // ── location card ─────────────────────────────────────────────────────────
  Widget _locationCard() => _Tap(onTap: _pickLoc,
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: _loc != null ? _c2.withOpacity(.4) : const Color(0xFFE4E8F5),
            width: _loc != null ? 1.5 : 1),
        boxShadow: [BoxShadow(color: _c1.withOpacity(.07),
            blurRadius: 14, offset: const Offset(0, 5))],
      ),
      child: Row(children: [
        Container(width: 48, height: 48,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _loc != null ? [_c1, _c2] : [const Color(0xFFE4E8F5), const Color(0xFFEEF0FA)],
              begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(14),
            boxShadow: _loc != null ? [BoxShadow(color: _c2.withOpacity(.35),
                blurRadius: 10, offset: const Offset(0, 4))] : null,
          ),
          child: Icon(Icons.location_on_rounded,
              color: _loc != null ? Colors.white : _sub, size: 22)),
        const SizedBox(width: 14),
        Expanded(child: _loc != null
            ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(_loc!.address, maxLines: 2, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13.5,
                        fontWeight: FontWeight.w700, color: _txt)),
                const SizedBox(height: 3),
                Text('From your saved shop address · tap to change for this order',
                    style: TextStyle(fontSize: 11, color: _c2.withOpacity(.75),
                        fontWeight: FontWeight.w500)),
              ])
            : const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Set delivery location', style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w700, color: _txt)),
                SizedBox(height: 3),
                Text('Tap to pick on map', style: TextStyle(
                    fontSize: 12, color: _sub)),
              ])),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _c2.withOpacity(.08), shape: BoxShape.circle),
          child: Icon(Icons.chevron_right_rounded, color: _c2, size: 20)),
      ]),
    ),
  );

  // ── notes field ───────────────────────────────────────────────────────────
  Widget _notesField() => Container(
    decoration: BoxDecoration(
      color: Colors.white, borderRadius: BorderRadius.circular(20),
      boxShadow: [BoxShadow(color: _c1.withOpacity(.06),
          blurRadius: 14, offset: const Offset(0, 4))],
    ),
    child: TextField(
      controller: _notesC,
      maxLines: 3,
      decoration: InputDecoration(
        hintText: 'e.g. need by tomorrow morning, specific brand...',
        hintStyle: TextStyle(color: _sub.withOpacity(.7), fontSize: 13),
        prefixIcon: const Padding(
          padding: EdgeInsets.only(left: 14, right: 10, top: 14),
          child: Icon(Icons.sticky_note_2_outlined, color: _sub, size: 20)),
        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(color: _c2, width: 1.5)),
        filled: true, fillColor: Colors.white,
        contentPadding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
      ),
    ),
  );

  // ── submit button ─────────────────────────────────────────────────────────
  Widget _submitBtn() => _Tap(
    onTap: _submitting ? () {} : _submit,
    child: Container(
      width: double.infinity,
      height: 58,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7C1A00), Color(0xFFD03800),
                   Color(0xFFF06000), Color(0xFFFF9500)],
          stops: [0.0, 0.32, 0.68, 1.0],
          begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: const Color(0xFFD03800).withOpacity(.45),
              blurRadius: 22, spreadRadius: -2, offset: const Offset(0, 10)),
        ],
        border: Border.all(color: Colors.white.withOpacity(.12)),
      ),
      child: Stack(children: [
        // gloss
        Positioned.fill(child: ClipRRect(borderRadius: BorderRadius.circular(18),
          child: Align(alignment: Alignment.topCenter,
            child: FractionallySizedBox(heightFactor: .45, widthFactor: 1,
              child: Container(decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  colors: [Colors.white.withOpacity(.18), Colors.transparent]))))))),
        Center(child: _submitting
            ? const SizedBox(width: 22, height: 22,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
            : const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.send_rounded, color: Colors.white, size: 20),
                SizedBox(width: 10),
                Text('Post Demand', style: TextStyle(color: Colors.white,
                    fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: .2)),
              ])),
      ]),
    ),
  );

  // ── helpers ───────────────────────────────────────────────────────────────
  Widget _emptyBox(String msg) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE4E8F5))),
    child: Row(children: [
      Icon(Icons.inbox_rounded, color: _sub.withOpacity(.4), size: 22),
      const SizedBox(width: 12),
      Text(msg, style: TextStyle(color: _sub, fontSize: 13.5)),
    ]),
  );

  Widget _shimmerBox(double h) => Container(
    height: h,
    decoration: BoxDecoration(
      color: Colors.white, borderRadius: BorderRadius.circular(16)),
    child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
  );
}
