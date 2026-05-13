import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/order_service.dart';
import '../../services/demand_service.dart';
import '../../config/language.dart';
import 'stock_order_screen.dart';

const _c0  = Color(0xFF060D28);
const _c1  = Color(0xFF0E2260);
const _c2  = Color(0xFF1F4BD5);
const _c3  = Color(0xFF6C3FE8);
const _bg  = Color(0xFFF2F5FF);
const _txt = Color(0xFF212121);
const _sub = Color(0xFF757575);
const _amb1 = Color(0xFFAD4A0A); const _amb2 = Color(0xFFF5981E);
const _grn1 = Color(0xFF054F3A); const _grn2 = Color(0xFF0FBB84);
const _teal1 = Color(0xFF094E6A); const _teal2 = Color(0xFF17BBDD);

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

// category accent palette
const _catGrad = {
  'Grocery'   : [Color(0xFFAD4A0A), Color(0xFFF5981E)],
  'Pharmacy'  : [Color(0xFF7B1C1C), Color(0xFFEF5350)],
  'Stationary': [Color(0xFF1840AF), Color(0xFF4F8EF7)],
  'Hardware'  : [Color(0xFF1B4D3E), Color(0xFF26A17B)],
};

class BrowseStocksScreen extends StatefulWidget {
  const BrowseStocksScreen({super.key});
  @override State<BrowseStocksScreen> createState() => _BSS();
}

class _BSS extends State<BrowseStocksScreen> with SingleTickerProviderStateMixin {
  final _ctrl = TextEditingController();
  Timer? _debounce;
  List<Map<String, dynamic>> _stocks = [];
  List<Map<String, dynamic>> _cats   = [];
  int? _catFilter;
  bool _loading = true;

  late final _fadeC = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 380));

  @override
  void initState() { super.initState(); appLang.addListener(_onLangChange); _loadCats(); _search(); }
  void _onLangChange() => setState(() {});
  @override
  void dispose() { appLang.removeListener(_onLangChange); _debounce?.cancel(); _ctrl.dispose(); _fadeC.dispose(); super.dispose(); }

  Future<void> _loadCats() async {
    final cats = await DemandService.getCategories();
    if (!mounted) return;
    setState(() => _cats = cats);
  }

  Future<void> _search() async {
    setState(() => _loading = true);
    final list = await OrderService.searchStocks(
        q: _ctrl.text.trim(), categoryId: _catFilter);
    if (!mounted) return;
    setState(() { _stocks = list; _loading = false; });
    _fadeC.forward(from: 0);
  }

  void _onChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), _search);
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
                  onRefresh: _search, color: _c2,
                  child: _stocks.isEmpty ? _empty() : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                    itemCount: _stocks.length,
                    itemBuilder: (_, i) => _card(_stocks[i]),
                  ),
                ),
              )),
      ]),
    ),
  );

  // ── header ────────────────────────────────────────────────────────────────
  Widget _header() => Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
          colors: [_c0, _c1, _teal1, _teal2],
          stops: [0.0, 0.35, 0.72, 1.0],
          begin: Alignment.topLeft, end: Alignment.bottomRight),
      borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32), bottomRight: Radius.circular(32)),
    ),
    child: SafeArea(bottom: false,
      child: Stack(children: [
        Positioned(top: -20, right: -30, child: _blob(130, Colors.white, .04)),
        Positioned(top: 8,   right: 50,  child: _blob(44,  _teal2, .35)),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // top row
            Row(children: [
              // back / close
              if (Navigator.canPop(context))
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: ClipRRect(borderRadius: BorderRadius.circular(12),
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
                ),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(S('browse_stocks_title'), style: const TextStyle(color: Colors.white,
                    fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -.4)),
                SizedBox(height: 2),
                Text('Available stock within 10 km',
                    style: TextStyle(color: Colors.white54, fontSize: 12.5)),
              ])),
              // result count pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(.25)),
                ),
                child: Text('${_stocks.length} found',
                    style: const TextStyle(color: Colors.white,
                        fontSize: 12, fontWeight: FontWeight.w700))),
            ]),
            const SizedBox(height: 16),
            // search bar
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: _c0.withOpacity(.25),
                    blurRadius: 16, offset: const Offset(0, 6))],
              ),
              child: TextField(
                controller: _ctrl,
                onChanged: _onChanged,
                style: const TextStyle(fontSize: 14, color: _txt),
                decoration: InputDecoration(
                  hintText: S('search_stocks_hint'),
                  hintStyle: TextStyle(color: _sub.withOpacity(.7), fontSize: 13.5),
                  prefixIcon: const Icon(Icons.search_rounded, color: _sub, size: 20),
                  suffixIcon: _ctrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close_rounded, color: _sub, size: 18),
                          onPressed: () { _ctrl.clear(); _search(); setState(() {}); })
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
            if (_cats.isNotEmpty) ...[
              const SizedBox(height: 14),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(children: [
                  _catChip('All', null),
                  for (final c in _cats)
                    _catChip(c['name'] as String, c['category_id'] as int),
                ]),
              ),
            ],
          ]),
        ),
      ]),
    ),
  );

  Widget _catChip(String label, int? id) {
    final sel = _catFilter == id;
    final grad = id == null ? [_c1, _c3]
        : (_catGrad[label] ?? [_c1, _c2]);
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: _Tap(onTap: () {
        HapticFeedback.lightImpact();
        setState(() => _catFilter = id);
        _search();
      }, child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          gradient: sel ? LinearGradient(colors: grad) : null,
          color: sel ? null : Colors.white.withOpacity(0.18),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
              color: sel ? Colors.transparent : Colors.white.withOpacity(.35)),
          boxShadow: sel ? [BoxShadow(color: grad.last.withOpacity(.4),
              blurRadius: 10, offset: const Offset(0, 3))] : null,
        ),
        child: Text(label, style: TextStyle(
            color: sel ? Colors.white : Colors.white,
            fontWeight: FontWeight.w800, fontSize: 12.5)),
      )),
    );
  }

  // ── stock card ────────────────────────────────────────────────────────────
  Widget _card(Map<String, dynamic> s) {
    final price  = (s['price_per_unit'] as num).toDouble();
    final qty    = (s['quantity_available'] as num).toDouble();
    final dist   = (s['distance_km'] as num?)?.toDouble();
    final rating = (s['rating_avg'] as num?)?.toDouble() ?? 0;
    final catName = (s['category_name'] ?? '') as String;
    final grad   = _catGrad[catName] ?? [_amb1, _amb2];

    return _Tap(
      onTap: () async {
        final placed = await Navigator.push<bool>(context,
            MaterialPageRoute(builder: (_) => StockOrderScreen(stock: s)));
        if (placed == true) _search();
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
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // icon
              Container(width: 52, height: 52,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: grad,
                      begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [BoxShadow(color: grad.last.withOpacity(.38),
                      blurRadius: 12, offset: const Offset(0, 4))],
                ),
                child: const Icon(Icons.inventory_2_rounded, color: Colors.white, size: 24)),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${s['product_name']}',
                    style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800,
                        color: _txt, letterSpacing: -.2),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: grad[0].withOpacity(.1), borderRadius: BorderRadius.circular(6)),
                    child: Text('${s['variant_name']}',
                        style: TextStyle(color: grad[0], fontSize: 11.5,
                            fontWeight: FontWeight.w700))),
                  const SizedBox(width: 6),
                  Flexible(child: Text(
                      '${s['company_name'] ?? s['stockholder_name'] ?? ''}',
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: _sub, fontSize: 12))),
                ]),
              ])),
              const SizedBox(width: 10),
              // price
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('৳${price.toStringAsFixed(0)}',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900,
                        color: grad[0])),
                Text('per ${s['unit']}',
                    style: const TextStyle(fontSize: 11, color: _sub)),
              ]),
            ]),
          ),
          // bottom pills strip
          Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: [grad[0].withOpacity(.05), grad[1].withOpacity(.02)]),
              borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(22), bottomRight: Radius.circular(22)),
              border: Border(top: BorderSide(color: grad[1].withOpacity(.1))),
            ),
            child: Row(children: [
              _pill(Icons.inventory_2_outlined,
                  '${qty % 1 == 0 ? qty.toInt() : qty} ${s['unit']}', _sub),
              if (dist != null) ...[
                const SizedBox(width: 8),
                _pill(Icons.near_me_rounded, '${dist.toStringAsFixed(1)} km', _c2),
              ],
              if (rating > 0) ...[
                const SizedBox(width: 8),
                _pill(Icons.star_rounded, rating.toStringAsFixed(1), Colors.amber.shade700),
              ],
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: grad),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [BoxShadow(color: grad.last.withOpacity(.35),
                      blurRadius: 8, offset: const Offset(0, 3))],
                ),
                child: const Text('Order',
                    style: TextStyle(color: Colors.white,
                        fontSize: 12, fontWeight: FontWeight.w800))),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _pill(IconData icon, String text, Color c) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
        color: c.withOpacity(.09), borderRadius: BorderRadius.circular(8)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 12, color: c),
      const SizedBox(width: 5),
      Text(text, style: TextStyle(color: c, fontSize: 11.5, fontWeight: FontWeight.w600)),
    ]),
  );

  Widget _empty() => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
    Container(width: 90, height: 90,
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [_teal1, _teal2]),
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: _teal2.withOpacity(.3), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: const Icon(Icons.search_off_rounded, size: 44, color: Colors.white)),
    const SizedBox(height: 20),
    Text(S('no_stocks_found'), style: const TextStyle(fontSize: 18,
        fontWeight: FontWeight.w800, color: _txt)),
    const SizedBox(height: 8),
    const Padding(
      padding: EdgeInsets.symmetric(horizontal: 48),
      child: Text('Try a different keyword or category.\nStocks within 10 km are shown.',
          textAlign: TextAlign.center,
          style: TextStyle(color: _sub, fontSize: 13.5, height: 1.5)),
    ),
  ]));

  Widget _blob(double sz, Color c, double op) =>
      Container(width: sz, height: sz,
          decoration: BoxDecoration(shape: BoxShape.circle, color: c.withOpacity(op)));
}
