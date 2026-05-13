import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/demand_service.dart';
import '../../services/location_service.dart';
import '../../services/profile_service.dart';
import '../shared/location_picker_screen.dart';
import '../../config/language.dart';

// ── palette ───────────────────────────────────────────────────────────────────
const _c0  = Color(0xFF060D28);
const _c1  = Color(0xFF0E2260);
const _c2  = Color(0xFF1F4BD5);
const _c3  = Color(0xFF6C3FE8);
const _bg  = Color(0xFFF2F5FF);
const _txt = Color(0xFF212121);
const _sub = Color(0xFF757575);

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

// quick-qty presets per unit
const _qtyPresets = {
  'kg'    : [10.0, 50.0, 100.0, 500.0],
  'litre' : [5.0,  20.0, 50.0,  200.0],
  'piece' : [5.0,  10.0, 50.0,  100.0],
  'pack'  : [1.0,  5.0,  10.0,  50.0],
};

// ── tap wrapper ───────────────────────────────────────────────────────────────
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

// ─────────────────────────────────────────────────────────────────────────────
class PostDemandScreen extends StatefulWidget {
  const PostDemandScreen({super.key});
  @override State<PostDemandScreen> createState() => _PostDemandScreenState();
}

class _PostDemandScreenState extends State<PostDemandScreen>
    with SingleTickerProviderStateMixin {

  // wizard step: 0=category, 1=product+variant, 2=quantity, 3=location+notes
  int _step = 0;

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

  late final _pageC = PageController();
  late final _fadeC = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 350));
  late final _fade = CurvedAnimation(parent: _fadeC, curve: Curves.easeOut);

  @override
  void initState() {
    super.initState();
    appLang.addListener(_onLangChange);
    _loadCategories();
    _prefillLoc();
    _fadeC.forward();
  }

  void _onLangChange() => setState(() {});

  @override
  void dispose() {
    appLang.removeListener(_onLangChange);
    _qtyC.dispose(); _notesC.dispose(); _searchC.dispose();
    _fadeC.dispose(); _pageC.dispose();
    super.dispose();
  }

  Future<void> _prefillLoc() async {
    final cached = await ProfileService.getCachedLocation();
    if (cached != null && mounted) setState(() => _loc = cached);
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
        area: (prof['area'] as String?) ?? '',
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
    _goTo(1);
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

  void _goTo(int step) {
    setState(() => _step = step);
    _pageC.animateToPage(step,
        duration: const Duration(milliseconds: 320), curve: Curves.easeInOut);
  }

  void _back() {
    if (_step == 0) { Navigator.pop(context); return; }
    _goTo(_step - 1);
  }

  bool get _canNext {
    if (_step == 0) return _selCat != null;
    if (_step == 1) return _selProd != null && _selVar != null;
    if (_step == 2) {
      final qty = double.tryParse(_qtyC.text.trim());
      return qty != null && qty > 0;
    }
    return _loc != null;
  }

  Future<void> _submit() async {
    if (!_canNext) { _err('Set your delivery location'); return; }
    final qty = double.tryParse(_qtyC.text.trim())!;
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
      HapticFeedback.heavyImpact();
      await _showSuccess(qty);
      if (mounted) Navigator.pop(context, true);
    } else {
      _err(res['error']?.toString() ?? 'Failed to post demand');
    }
  }

  Future<void> _showSuccess(double qty) => showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(padding: const EdgeInsets.all(28),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 72, height: 72,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [_c1, _c3],
                  begin: Alignment.topLeft, end: Alignment.bottomRight),
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: _c3.withOpacity(.4),
                  blurRadius: 18, offset: const Offset(0, 6))],
            ),
            child: const Icon(Icons.check_rounded, color: Colors.white, size: 36)),
          const SizedBox(height: 18),
          const Text('Demand Posted!', style: TextStyle(
              fontSize: 20, fontWeight: FontWeight.w900, color: _txt)),
          const SizedBox(height: 8),
          Text(
            '${qty % 1 == 0 ? qty.toInt() : qty} $_unit of '
            '${_selProd!['name']} (${_selVar!['variant_name']})\n'
            'Nearby suppliers will be notified.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: _sub, fontSize: 13.5, height: 1.5)),
          const SizedBox(height: 24),
          _Tap(onTap: () => Navigator.pop(context),
            child: Container(width: double.infinity, height: 50,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [_c1, _c3]),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: _c3.withOpacity(.35),
                    blurRadius: 14, offset: const Offset(0, 6))],
              ),
              child: const Center(child: Text('Done',
                  style: TextStyle(color: Colors.white,
                      fontSize: 16, fontWeight: FontWeight.w900))))),
        ]),
      ),
    ),
  );

  void _err(String msg) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(backgroundColor: const Color(0xFFC62828),
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600))));

  // ════════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: SystemUiOverlayStyle.light,
    child: Scaffold(
      backgroundColor: _bg,
      body: _loadCats
          ? const Center(child: CircularProgressIndicator(color: _c2))
          : FadeTransition(
              opacity: _fade,
              child: Column(children: [
                _header(),
                Expanded(child: PageView(
                  controller: _pageC,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _stepPage(_categoryStep()),
                    _stepPage(_productStep()),
                    _stepPage(_quantityStep()),
                    _stepPage(_locationStep()),
                  ],
                )),
                _bottomBar(),
              ]),
            ),
    ),
  );

  // ── header ────────────────────────────────────────────────────────────────
  Widget _header() => Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        colors: [_c0, _c1, _c2, _c3],
        stops: [0.0, 0.35, 0.72, 1.0],
        begin: Alignment.topLeft, end: Alignment.bottomRight),
      borderRadius: BorderRadius.only(
        bottomLeft: Radius.circular(28), bottomRight: Radius.circular(28)),
    ),
    child: SafeArea(bottom: false,
      child: Stack(children: [
        Positioned(top: -20, right: -30, child: _blob(130, Colors.white, .04)),
        Positioned(top: 8,   right: 50,  child: _blob(44,  _c2, .35)),
        Positioned(top: 40,  left: -20,  child: _blob(80,  _c3, .22)),
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 20, 20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              ClipRRect(borderRadius: BorderRadius.circular(12),
                child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: _Tap(onTap: _back,
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
                Text(_stepTitles[_step],
                    style: const TextStyle(color: Colors.white, fontSize: 20,
                        fontWeight: FontWeight.w900, letterSpacing: -.4)),
                const SizedBox(height: 2),
                Text(_stepSubtitles[_step],
                    style: TextStyle(color: Colors.white.withOpacity(0.65), fontSize: 12.5)),
              ])),
              // step indicator pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.25)),
                ),
                child: Text('${_step + 1} / 4',
                    style: const TextStyle(color: Colors.white,
                        fontSize: 12, fontWeight: FontWeight.w700)),
              ),
            ]),
            const SizedBox(height: 14),
            _progressBar(),
          ]),
        ),
      ]),
    ),
  );

  static const _stepTitles = [
    'What do you need?',
    'Pick product & type',
    'How much?',
    'Delivery details',
  ];
  static const _stepSubtitles = [
    'Choose a category to get started',
    'Search and select the exact item',
    'Set quantity and unit',
    'Location and any extra notes',
  ];

  Widget _progressBar() {
    return Row(children: List.generate(4, (i) {
      final done    = i < _step;
      final current = i == _step;
      return Expanded(child: Row(children: [
        Expanded(child: AnimatedContainer(
          duration: const Duration(milliseconds: 350),
          height: 5,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(3),
            color: done
                ? Colors.white
                : current
                    ? Colors.white.withOpacity(.65)
                    : Colors.white.withOpacity(.22),
          ),
        )),
        if (i < 3) const SizedBox(width: 5),
      ]));
    }));
  }

  // ── step wrapper ──────────────────────────────────────────────────────────
  Widget _stepPage(Widget content) => SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
    child: content,
  );

  // ── step 0: category ──────────────────────────────────────────────────────
  Widget _categoryStep() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    _label('Choose a category'),
    const SizedBox(height: 14),
    LayoutBuilder(builder: (ctx, c) {
      final w = (c.maxWidth - 12) / 2;
      return GridView.count(
        crossAxisCount: 2, shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 12, crossAxisSpacing: 12,
        childAspectRatio: (w / 110).clamp(1.1, 1.6),
        children: _categories.map((cat) {
          final name = cat['name'] as String;
          final colors = _catColors[name] ?? [_c1, _c2];
          final emoji  = _catEmoji[name]  ?? '📦';
          final desc   = _catDesc[name]   ?? '';
          final sel    = _selCat?['category_id'] == cat['category_id'];
          return _Tap(onTap: () => _pickCat(cat),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                gradient: sel ? LinearGradient(colors: colors,
                    begin: Alignment.topLeft, end: Alignment.bottomRight) : null,
                color: sel ? null : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: sel ? colors.last : const Color(0xFFE4E8F5),
                    width: sel ? 0 : 1.5),
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
            ),
          );
        }).toList(),
      );
    }),
  ]);

  // ── step 1: product + variant ─────────────────────────────────────────────
  Widget _productStep() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    if (_selCat != null) ...[
      // category pill recap
      _recapChip(
          _catEmoji[_selCat!['name']] ?? '📦',
          _selCat!['name'] as String,
          onTap: () => _goTo(0)),
      const SizedBox(height: 20),
    ],

    _label('Search product'),
    const SizedBox(height: 10),
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
          hintText: S('search_products_hint'),
          hintStyle: TextStyle(color: _sub.withOpacity(.7), fontSize: 13.5),
          prefixIcon: const Icon(Icons.search_rounded, color: _sub, size: 20),
          suffixIcon: _q.isNotEmpty
              ? IconButton(icon: const Icon(Icons.close_rounded, color: _sub, size: 18),
                  onPressed: () { _searchC.clear(); setState(() => _q = ''); })
              : null,
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
    const SizedBox(height: 16),

    if (_loadProds)
      const Center(child: Padding(
        padding: EdgeInsets.all(32),
        child: CircularProgressIndicator(color: _c2, strokeWidth: 2)))
    else ...[
      _productChips(),
      if (_selProd != null && _variants.isNotEmpty) ...[
        const SizedBox(height: 24),
        _label('Select type / variant'),
        const SizedBox(height: 10),
        _variantChips(),
      ],
    ],
  ]);

  Widget _productChips() {
    final q = _q.trim().toLowerCase();
    final list = q.isEmpty ? _products
        : _products.where((p) =>
            (p['name'] as String).toLowerCase().contains(q)).toList();
    if (list.isEmpty) return _emptyBox(q.isEmpty
        ? 'No products in this category' : 'No products match "$_q"');
    return Wrap(spacing: 8, runSpacing: 8,
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
                style: TextStyle(color: sel ? Colors.white : _txt,
                    fontWeight: FontWeight.w700, fontSize: 13.5)),
          ),
        );
      }).toList());
  }

  Widget _variantChips() => Wrap(spacing: 8, runSpacing: 8,
    children: _variants.map((v) {
      final sel = _selVar?['variant_id'] == v['variant_id'];
      return _Tap(onTap: () { HapticFeedback.lightImpact(); setState(() => _selVar = v); },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
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
          child: Text(v['variant_name'] as String,
              style: TextStyle(color: sel ? Colors.white : _txt,
                  fontWeight: FontWeight.w700, fontSize: 13.5)),
        ),
      );
    }).toList(),
  );

  // ── step 2: quantity ──────────────────────────────────────────────────────
  Widget _quantityStep() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    // recap
    if (_selProd != null)
      _recapChip('📦', '${_selProd!['name']} · ${_selVar?['variant_name'] ?? ''}',
          onTap: () => _goTo(1)),
    const SizedBox(height: 20),

    // big qty input
    Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: _c1.withOpacity(.08),
            blurRadius: 20, offset: const Offset(0, 6))],
      ),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Expanded(child: TextField(
            controller: _qtyC,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textAlign: TextAlign.center,
            onChanged: (_) => setState(() {}),
            style: const TextStyle(fontSize: 52, fontWeight: FontWeight.w900,
                color: _txt, letterSpacing: -2),
            decoration: const InputDecoration(
              hintText: '0',
              hintStyle: TextStyle(color: Color(0xFFCDD0E3), fontSize: 52,
                  fontWeight: FontWeight.w900, letterSpacing: -2),
              border: InputBorder.none, enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
          )),
          const SizedBox(width: 12),
          // unit selector
          Column(crossAxisAlignment: CrossAxisAlignment.end,
              children: _units.map((u) {
            final sel = _unit == u;
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: _Tap(onTap: () { HapticFeedback.selectionClick(); setState(() => _unit = u); },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    gradient: sel ? const LinearGradient(colors: [_c1, _c3],
                        begin: Alignment.topLeft, end: Alignment.bottomRight) : null,
                    color: sel ? null : _bg,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: sel ? [BoxShadow(color: _c2.withOpacity(.3),
                        blurRadius: 8, offset: const Offset(0, 3))] : null,
                  ),
                  child: Text(u, style: TextStyle(
                      color: sel ? Colors.white : _sub,
                      fontWeight: FontWeight.w800, fontSize: 13)),
                ),
              ),
            );
          }).toList()),
        ]),
        const Divider(height: 8, color: Color(0xFFF0F2FA)),
        const SizedBox(height: 12),
        // quick presets
        Row(children: (_qtyPresets[_unit] ?? []).map((q) {
          final label = q % 1 == 0 ? '${q.toInt()}' : '$q';
          final isCurrent = _qtyC.text == label;
          return Expanded(child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: _Tap(onTap: () {
              HapticFeedback.selectionClick();
              _qtyC.text = label;
              setState(() {});
            },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  gradient: isCurrent ? const LinearGradient(
                      colors: [_c1, _c3], begin: Alignment.topLeft,
                      end: Alignment.bottomRight) : null,
                  color: isCurrent ? null : _bg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: isCurrent ? Colors.transparent
                          : const Color(0xFFDDE0F0)),
                ),
                child: Text(label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: isCurrent ? Colors.white : _sub,
                        fontWeight: FontWeight.w800, fontSize: 13)),
              ),
            ),
          ));
        }).toList()),
        const SizedBox(height: 4),
        Text('Quick select $_unit',
            style: const TextStyle(color: _sub, fontSize: 11, fontWeight: FontWeight.w500)),
      ]),
    ),
  ]);

  // ── step 3: location + notes ──────────────────────────────────────────────
  Widget _locationStep() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    // recap pill
    if (_selProd != null) ...[
      _recapChip('📦',
          '${_qtyC.text.isNotEmpty ? _qtyC.text : '?'} $_unit · ${_selProd!['name']} (${_selVar?['variant_name'] ?? ''})',
          onTap: () => _goTo(2)),
      const SizedBox(height: 20),
    ],

    _label('Delivery location *'),
    const SizedBox(height: 10),
    _locationCard(),

    const SizedBox(height: 24),
    _label('Notes (optional)'),
    const SizedBox(height: 10),
    _notesField(),
  ]);

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
              colors: _loc != null ? [_c1, _c2]
                  : [const Color(0xFFE4E8F5), const Color(0xFFEEF0FA)],
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
                Text('From your shop address · tap to change',
                    style: TextStyle(fontSize: 11, color: _c2.withOpacity(.75),
                        fontWeight: FontWeight.w500)),
              ])
            : const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Set delivery location', style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w700, color: _txt)),
                SizedBox(height: 3),
                Text('Tap to pick on map or use GPS', style: TextStyle(
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
        hintText: S('notes_hint'),
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

  // ── bottom action bar ─────────────────────────────────────────────────────
  Widget _bottomBar() => Container(
    padding: EdgeInsets.fromLTRB(20, 12, 20,
        MediaQuery.of(context).padding.bottom + 12),
    decoration: BoxDecoration(
      color: Colors.white,
      boxShadow: [BoxShadow(color: _c1.withOpacity(.08),
          blurRadius: 16, offset: const Offset(0, -4))],
    ),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      // selection summary (steps 1-3)
      if (_step > 0 && _selProd != null) ...[
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: _bg, borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFDDE0F0)),
          ),
          child: Row(children: [
            const Icon(Icons.shopping_cart_outlined, color: _c2, size: 16),
            const SizedBox(width: 8),
            Expanded(child: Text(
              [
                if (_selCat != null) _selCat!['name'] as String,
                if (_selProd != null) _selProd!['name'] as String,
                if (_selVar != null) _selVar!['variant_name'] as String,
                if (_qtyC.text.isNotEmpty) '${_qtyC.text} $_unit',
                if (_loc != null && _loc!.area.isNotEmpty) _loc!.area,
              ].join(' › '),
              maxLines: 1, overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: _txt,
                  fontWeight: FontWeight.w600))),
          ]),
        ),
      ],

      // Next / Post button
      _Tap(
        onTap: !_canNext
            ? () { HapticFeedback.lightImpact(); _showNextHint(); }
            : _step < 3
                ? () { HapticFeedback.mediumImpact(); _goTo(_step + 1); }
                : _submitting ? () {} : _submit,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity, height: 54,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _canNext
                  ? (_step == 3
                      ? [const Color(0xFF7C1A00), const Color(0xFFD03800),
                         const Color(0xFFF06000), const Color(0xFFFF9500)]
                      : [_c0, _c1, _c2, _c3])
                  : [const Color(0xFFCDD0E3), const Color(0xFFBEC3D4)],
              begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(16),
            boxShadow: _canNext ? [BoxShadow(
                color: (_step == 3
                    ? const Color(0xFFD03800) : _c2).withOpacity(.4),
                blurRadius: 16, spreadRadius: -2, offset: const Offset(0, 8))]
                : [],
          ),
          child: Center(child: _submitting
              ? const SizedBox(width: 22, height: 22,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
              : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(
                    _step == 3
                        ? Icons.send_rounded
                        : Icons.arrow_forward_rounded,
                    color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    _step == 3 ? S('post_demand_btn') : S('next_btn'),
                    style: const TextStyle(color: Colors.white,
                        fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: .2)),
                ])),
        ),
      ),
    ]),
  );

  void _showNextHint() {
    final hints = [
      'Pick a category first',
      _selProd == null ? 'Pick a product' : 'Pick a variant type',
      'Enter a quantity',
      'Set your delivery location',
    ];
    _err(hints[_step]);
  }

  // ── helpers ───────────────────────────────────────────────────────────────
  Widget _label(String t) => Text(t, style: const TextStyle(
      fontSize: 13.5, fontWeight: FontWeight.w800, color: _sub, letterSpacing: .3));

  Widget _recapChip(String emoji, String text, {required VoidCallback onTap}) =>
    _Tap(onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [_c1, _c3],
              begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: _c2.withOpacity(.25),
              blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(emoji, style: const TextStyle(fontSize: 15)),
          const SizedBox(width: 8),
          Flexible(child: Text(text,
              maxLines: 1, overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white,
                  fontSize: 12.5, fontWeight: FontWeight.w700))),
          const SizedBox(width: 6),
          const Icon(Icons.edit_rounded, color: Colors.white70, size: 12),
        ]),
      ),
    );

  Widget _blob(double sz, Color c, double op) =>
      Container(width: sz, height: sz,
          decoration: BoxDecoration(shape: BoxShape.circle, color: c.withOpacity(op)));

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
}
