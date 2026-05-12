import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';
import '../../config/language.dart';
import '../../services/auth_service.dart';
import '../../services/stock_service.dart';
import '../../services/profile_service.dart';
import '../../services/location_service.dart';
import '../shared/location_picker_screen.dart';

const _sp0 = Color(0xFF16002E);
const _sp1 = Color(0xFF3B0D6B);
const _sp2 = Color(0xFF7B2FD4);
const _sp3 = Color(0xFFBB6BF7);
const _bg  = Color(0xFFF8F0FF);
const _txt = Color(0xFF212121);
const _sub = Color(0xFF757575);

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
class PostStockScreen extends StatefulWidget {
  const PostStockScreen({super.key});
  @override State<PostStockScreen> createState() => _PSS();
}

class _PSS extends State<PostStockScreen> {
  String? _cat;
  String? _product;
  String? _variant;
  String? _unit;
  final _qty   = TextEditingController();
  final _price = TextEditingController();
  final _notes = TextEditingController();
  LocationResult? _loc;

  final Map<String, int> _catIdMap = {};
  final Map<String, Map<String, dynamic>> _productData = {};
  int? _selectedProductId;
  int? _selectedVariantId;

  bool _submitting = false;
  bool _loadingCats = true;
  bool _loadingProducts = false;

  final _cats  = ['Grocery', 'Pharmacy', 'Stationary', 'Hardware'];
  final _units = ['kg', 'litre', 'piece', 'pack'];
  static const _catIcons = {
    'Grocery':    Icons.shopping_basket_rounded,
    'Pharmacy':   Icons.local_pharmacy_rounded,
    'Stationary': Icons.edit_rounded,
    'Hardware':   Icons.hardware_rounded,
  };

  List<String> get _productsForCat => _productData.keys.toList();
  List<String> get _variantsForProduct {
    if (_product == null) return ['Other'];
    final variants = _productData[_product]?['variants'] as List<dynamic>?;
    return variants?.map((v) => v['variant_name'] as String).toList() ?? ['Other'];
  }

  @override
  void initState() {
    super.initState();
    appLang.addListener(_onLangChange);
    _loadCategories();
    _prefillLoc();
  }
  void _onLangChange() => setState(() {});
  @override
  void dispose() {
    appLang.removeListener(_onLangChange);
    _qty.dispose(); _price.dispose(); _notes.dispose();
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
      final addr = (prof['warehouse_address'] as String?) ?? '';
      setState(() => _loc = LocationResult(
        lat: lat, lng: lng,
        address: addr.isNotEmpty ? addr : '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}',
        area:     (prof['area']     as String?) ?? '',
        district: (prof['district'] as String?) ?? '',
      ));
    }
  }

  Future<void> _pickLoc() async {
    final r = await Navigator.push<LocationResult>(context,
      MaterialPageRoute(builder: (_) => LocationPickerScreen(
        title: 'Warehouse Location',
        initialLat: _loc?.lat, initialLng: _loc?.lng)));
    if (r != null && mounted) setState(() => _loc = r);
  }

  Future<void> _loadCategories() async {
    try {
      final token = await AuthService.getToken();
      final res = await http.get(Uri.parse(ApiConfig.categories),
          headers: {'Authorization': 'Bearer ${token ?? ''}'});
      if (res.statusCode == 200) {
        final cats = jsonDecode(res.body)['categories'] as List<dynamic>;
        for (final c in cats) {
          _catIdMap[c['name'] as String] = c['category_id'] as int;
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _loadingCats = false);
  }

  Future<void> _loadProducts(String catName) async {
    final catId = _catIdMap[catName];
    if (catId == null) return;
    setState(() => _loadingProducts = true);
    try {
      final token = await AuthService.getToken();
      final res = await http.get(Uri.parse(ApiConfig.productsByCategory(catId)),
          headers: {'Authorization': 'Bearer ${token ?? ''}'});
      if (res.statusCode == 200) {
        final products = jsonDecode(res.body)['products'] as List<dynamic>;
        _productData.clear();
        for (final p in products) {
          _productData[p['name'] as String] = {
            'product_id': p['product_id'],
            'variants': p['variants'],
          };
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _loadingProducts = false);
  }

  Future<void> _submit() async {
    if (_cat == null || _product == null || _qty.text.isEmpty || _price.text.isEmpty) {
      _err('Fill all required fields'); return;
    }
    if (_selectedProductId == null || _selectedVariantId == null) {
      _err('Please select a valid product and variant'); return;
    }
    final qty = double.tryParse(_qty.text);
    final price = double.tryParse(_price.text);
    if (qty == null || price == null) {
      _err('Enter valid numbers for quantity and price'); return;
    }
    if (_loc == null) { _err('Set your warehouse location'); return; }
    HapticFeedback.mediumImpact();
    setState(() => _submitting = true);
    final res = await StockService.createStock(
      productId: _selectedProductId!,
      variantId: _selectedVariantId!,
      quantity: qty,
      unit: _unit ?? 'kg',
      price: price,
      warehouseArea: _loc!.area.isNotEmpty ? _loc!.area : _loc!.address,
      lat: _loc!.lat,
      lng: _loc!.lng,
      notes: _notes.text.trim(),
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (!res.ok) { _err(res.error ?? 'Failed to post stock'); return; }
    HapticFeedback.heavyImpact();
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Padding(padding: const EdgeInsets.all(28), child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 72, height: 72,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [_sp1, _sp3],
                  begin: Alignment.topLeft, end: Alignment.bottomRight),
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: _sp3.withOpacity(.4),
                  blurRadius: 18, offset: const Offset(0, 6))],
            ),
            child: const Icon(Icons.check_rounded, color: Colors.white, size: 38)),
          const SizedBox(height: 18),
          Text(S('stock_posted'), style: const TextStyle(
              fontSize: 20, fontWeight: FontWeight.w900, color: _txt)),
          const SizedBox(height: 8),
          const Text('Your stock is now live and visible to nearby shop owners.',
              textAlign: TextAlign.center, style: TextStyle(color: _sub, fontSize: 13.5)),
          const SizedBox(height: 24),
          _Tap(onTap: () {
            Navigator.pop(context);
            Navigator.pop(context, true);
          },
            child: Container(width: double.infinity, height: 50,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [_sp1, _sp3]),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: _sp3.withOpacity(.4),
                    blurRadius: 14, offset: const Offset(0, 6))],
              ),
              child: const Center(child: Text('Done',
                  style: TextStyle(color: Colors.white,
                      fontSize: 16, fontWeight: FontWeight.w900))))),
        ])),
      ),
    );
  }

  void _err(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: const Color(0xFF7B1C1C),
      content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600))));

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _bg,
    body: Column(children: [
      _buildHeader(),
      Expanded(child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          _sectionCard(title: 'What are you selling?', icon: Icons.category_rounded,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _fieldLabel('Category *'),
              Wrap(spacing: 8, runSpacing: 8,
                children: _cats.map((cat) {
                  final sel = _cat == cat;
                  return _Tap(onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() {
                      _cat = sel ? null : cat;
                      _product = null; _variant = null;
                      _selectedProductId = null; _selectedVariantId = null;
                      _productData.clear();
                    });
                    if (!sel) _loadProducts(cat);
                  }, child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                    decoration: BoxDecoration(
                      gradient: sel ? const LinearGradient(colors: [_sp1, _sp3]) : null,
                      color: sel ? null : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: sel ? Colors.transparent : const Color(0xFFE8D5FF)),
                      boxShadow: sel ? [BoxShadow(color: _sp3.withOpacity(.3),
                          blurRadius: 8, offset: const Offset(0, 3))] : null,
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(_catIcons[cat] ?? Icons.category,
                          color: sel ? Colors.white : _sp2, size: 15),
                      const SizedBox(width: 6),
                      Text(cat, style: TextStyle(
                          color: sel ? Colors.white : _txt,
                          fontWeight: FontWeight.w700, fontSize: 13)),
                    ]),
                  ));
                }).toList()),
              const SizedBox(height: 16),
              _fieldLabel('Product *'),
              _loadingProducts
                  ? const Padding(padding: EdgeInsets.symmetric(vertical: 14),
                      child: Center(child: CircularProgressIndicator(color: _sp2, strokeWidth: 2)))
                  : _dropdown(_productsForCat, _product,
                      _cat == null ? 'Select a category first' : 'Choose product...',
                      (v) => setState(() {
                        _product = v; _variant = null; _selectedVariantId = null;
                        _selectedProductId = _productData[v]?['product_id'] as int?;
                      })),
              const SizedBox(height: 14),
              _fieldLabel('Variant *'),
              _dropdown(_variantsForProduct, _variant,
                  _product == null ? 'Select a product first' : 'Choose variant...',
                  (v) {
                final variants = _productData[_product]?['variants'] as List<dynamic>?;
                setState(() {
                  _variant = v;
                  _selectedVariantId = variants?.firstWhere(
                      (x) => x['variant_name'] == v,
                      orElse: () => <String, dynamic>{}
                  )['variant_id'] as int?;
                });
              }),
            ])),
          const SizedBox(height: 16),

          _sectionCard(title: 'Quantity & Price', icon: Icons.scale_rounded,
            child: Column(children: [
              Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _fieldLabel('Quantity *'),
                  _field(_qty, '0.00', keyboard: TextInputType.number),
                ])),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _fieldLabel('Unit *'),
                  _dropdown(_units, _unit, 'Select...',
                      (v) => setState(() => _unit = v)),
                ])),
              ]),
              const SizedBox(height: 14),
              _fieldLabel('Price per Unit (৳) *'),
              _field(_price, '0.00', keyboard: TextInputType.number,
                  prefix: const Text('৳', style: TextStyle(
                      color: _sp2, fontWeight: FontWeight.w900, fontSize: 16))),
            ])),
          const SizedBox(height: 16),

          _sectionCard(title: 'Location & Notes', icon: Icons.warehouse_rounded,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _fieldLabel('Warehouse Location *'),
              _locationCard(),
              const SizedBox(height: 14),
              _fieldLabel('Additional Notes (optional)'),
              _field(_notes,
                  'Quality, packaging, minimum order qty, etc.',
                  lines: 3),
            ])),
          const SizedBox(height: 28),

          _Tap(onTap: _submitting ? () {} : _submit,
            child: Container(width: double.infinity, height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _submitting
                      ? [_sp1.withOpacity(.5), _sp3.withOpacity(.5)]
                      : const [_sp0, _sp2, _sp3],
                  stops: const [0.0, 0.5, 1.0],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: _submitting ? [] : [BoxShadow(color: _sp3.withOpacity(.4),
                    blurRadius: 22, spreadRadius: -2, offset: const Offset(0, 10))],
              ),
              child: Stack(children: [
                if (!_submitting)
                  Positioned.fill(child: ClipRRect(borderRadius: BorderRadius.circular(18),
                    child: Align(alignment: Alignment.topCenter,
                      child: FractionallySizedBox(heightFactor: .45, widthFactor: 1,
                        child: Container(decoration: BoxDecoration(
                          gradient: LinearGradient(begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.white.withOpacity(.18), Colors.transparent]))))))),
                Center(child: _submitting
                    ? const SizedBox(width: 22, height: 22,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                    : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        const Icon(Icons.add_box_rounded, color: Colors.white, size: 20),
                        const SizedBox(width: 10),
                        Text(S('post_stock_btn'), style: const TextStyle(color: Colors.white,
                            fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: .2)),
                      ])),
              ])),
          ),
        ]),
      )),
    ]),
  );

  Widget _buildHeader() => Container(
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
            Text(S('post_stock_title'), style: const TextStyle(color: Colors.white,
                fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -.4)),
            SizedBox(height: 2),
            Text('List your stock for nearby shops',
                style: TextStyle(color: Colors.white54, fontSize: 12.5)),
          ])),
          Container(width: 50, height: 50,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.18),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(.25)),
            ),
            child: const Icon(Icons.add_box_rounded, color: Colors.white, size: 26)),
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
                Text('From your saved warehouse · tap to change',
                    style: TextStyle(fontSize: 11, color: _sp2.withOpacity(.8),
                        fontWeight: FontWeight.w500)),
              ])
            : const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Set warehouse location', style: TextStyle(
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

  Widget _sectionCard({required String title, required IconData icon, required Widget child}) =>
    Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: _sp1.withOpacity(.07), blurRadius: 16, offset: const Offset(0, 4)),
          BoxShadow(color: Colors.black.withOpacity(.03), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 32, height: 32,
            decoration: BoxDecoration(
              color: _sp3.withOpacity(.15), borderRadius: BorderRadius.circular(9)),
            child: Icon(icon, size: 17, color: _sp2)),
          const SizedBox(width: 10),
          Text(title, style: const TextStyle(
              fontSize: 14, fontWeight: FontWeight.w900, color: _txt)),
        ]),
        const SizedBox(height: 14),
        child,
      ]),
    );

  Widget _fieldLabel(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 8, left: 2),
    child: Text(t, style: const TextStyle(
        fontSize: 12.5, fontWeight: FontWeight.w800, color: _txt)),
  );

  Widget _field(TextEditingController c, String hint,
      {TextInputType? keyboard, int lines = 1, Widget? prefix}) => TextField(
    controller: c, keyboardType: keyboard, maxLines: lines,
    style: const TextStyle(fontSize: 14.5, color: _txt, fontWeight: FontWeight.w600),
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFFBBC0D4), fontSize: 14),
      prefix: prefix,
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

  Widget _dropdown(List<String> items, String? value, String hint,
      ValueChanged<String?> onChange) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12),
    decoration: BoxDecoration(
      color: _bg, borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFE8D5FF)),
    ),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: value, isExpanded: true,
        hint: Text(hint, style: const TextStyle(color: Color(0xFFBBC0D4), fontSize: 14)),
        items: items.map((e) => DropdownMenuItem(value: e,
            child: Text(e, style: const TextStyle(
                fontSize: 14.5, color: _txt, fontWeight: FontWeight.w600)))).toList(),
        onChanged: onChange,
      ),
    ),
  );
}
