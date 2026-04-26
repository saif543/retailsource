// Post Demand — friendly step-by-step form for village shopkeepers.
// Pick category → product → variant → qty/unit → location → notes → Post.

import 'package:flutter/material.dart';
import '../../config/app_colors.dart';
import '../../services/demand_service.dart';
import '../../services/location_service.dart';
import '../shared/location_picker_screen.dart';

class PostDemandScreen extends StatefulWidget {
  const PostDemandScreen({super.key});

  @override
  State<PostDemandScreen> createState() => _PostDemandScreenState();
}

class _PostDemandScreenState extends State<PostDemandScreen> {
  // Visual category meta
  static const _catMeta = {
    'Grocery': (Icons.shopping_basket_rounded, Color(0xFFFF8F00), '🛒'),
    'Pharmacy': (Icons.medical_services_rounded, Color(0xFFC62828), '💊'),
    'Stationary': (Icons.edit_note_rounded, Color(0xFF1565C0), '✏️'),
    'Hardware': (Icons.build_rounded, Color(0xFF424242), '🔧'),
  };
  static const _units = ['kg', 'litre', 'piece', 'pack'];

  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _variants = [];

  Map<String, dynamic>? _selectedCategory;
  Map<String, dynamic>? _selectedProduct;
  Map<String, dynamic>? _selectedVariant;
  String _unit = 'kg';
  final _qtyController = TextEditingController();
  final _notesController = TextEditingController();
  final _productSearchController = TextEditingController();
  String _productQuery = '';

  LocationResult? _location;
  bool _loadingCats = true;
  bool _loadingProds = false;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _qtyController.dispose();
    _notesController.dispose();
    _productSearchController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    final cats = await DemandService.getCategories();
    if (!mounted) return;
    setState(() {
      _categories = cats;
      _loadingCats = false;
    });
  }

  Future<void> _onCategoryPicked(Map<String, dynamic> cat) async {
    setState(() {
      _selectedCategory = cat;
      _selectedProduct = null;
      _selectedVariant = null;
      _products = [];
      _variants = [];
      _productQuery = '';
      _productSearchController.clear();
      _loadingProds = true;
    });
    final products = await DemandService.getProductsByCategory(cat['category_id'] as int);
    if (!mounted) return;
    setState(() {
      _products = products;
      _loadingProds = false;
    });
  }

  void _onProductPicked(Map<String, dynamic> prod) {
    setState(() {
      _selectedProduct = prod;
      _variants = List<Map<String, dynamic>>.from(prod['variants'] ?? []);
      _selectedVariant = _variants.length == 1 ? _variants.first : null;
    });
  }

  Future<void> _pickLocation() async {
    final result = await Navigator.push<LocationResult>(
      context,
      MaterialPageRoute(
        builder: (_) => LocationPickerScreen(
          title: 'Delivery Location',
          initialLat: _location?.lat,
          initialLng: _location?.lng,
        ),
      ),
    );
    if (result != null && mounted) {
      setState(() => _location = result);
    }
  }

  Future<void> _submit() async {
    if (_selectedCategory == null) return _err('Pick a category');
    if (_selectedProduct == null) return _err('Pick a product');
    if (_selectedVariant == null) return _err('Pick a variant');
    final qty = double.tryParse(_qtyController.text.trim());
    if (qty == null || qty <= 0) return _err('Enter valid quantity');
    if (_location == null) return _err('Pick delivery location');

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Post this demand?'),
        content: Text(
          '${qty.toStringAsFixed(qty == qty.toInt() ? 0 : 2)} $_unit of '
          '${_selectedProduct!['name']} (${_selectedVariant!['variant_name']}) '
          'in ${_location!.area.isNotEmpty ? _location!.area : 'selected location'}.\n\n'
          'Suppliers near you will be notified.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Edit')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE65100),
                  foregroundColor: Colors.white),
              child: const Text('Post Now')),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _submitting = true);
    final res = await DemandService.createDemand(
      productId: _selectedProduct!['product_id'] as int,
      variantId: _selectedVariant!['variant_id'] as int,
      quantity: qty,
      unit: _unit,
      locationArea: _location!.area.isNotEmpty ? _location!.area : null,
      lat: _location!.lat,
      lng: _location!.lng,
      notes: _notesController.text.trim(),
    );
    if (!mounted) return;
    setState(() => _submitting = false);

    if (res['statusCode'] == 201) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            backgroundColor: Colors.green,
            content: Text('✓ Demand posted! Suppliers will be notified.')),
      );
      Navigator.pop(context, true);
    } else {
      _err(res['error']?.toString() ?? 'Failed to post');
    }
  }

  void _err(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(backgroundColor: Colors.red, content: Text(msg)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('Post Demand'),
        elevation: 0,
      ),
      body: _loadingCats
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _stepLabel(1, 'What do you need?'),
                  const SizedBox(height: 12),
                  _categoryGrid(),

                  if (_selectedCategory != null) ...[
                    const SizedBox(height: 24),
                    _stepLabel(2, 'Pick product'),
                    const SizedBox(height: 12),
                    _loadingProds
                        ? const Center(child: CircularProgressIndicator())
                        : _productList(),
                  ],

                  if (_variants.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _stepLabel(3, 'Pick type'),
                    const SizedBox(height: 12),
                    _variantChips(),
                  ],

                  if (_selectedVariant != null) ...[
                    const SizedBox(height: 24),
                    _stepLabel(4, 'How much?'),
                    const SizedBox(height: 12),
                    _quantityInput(),

                    const SizedBox(height: 24),
                    _stepLabel(5, 'Where to deliver?'),
                    const SizedBox(height: 12),
                    _locationButton(),

                    const SizedBox(height: 24),
                    _stepLabel(6, 'Any notes? (optional)'),
                    const SizedBox(height: 12),
                    _notesField(),

                    const SizedBox(height: 28),
                    _submitButton(),
                  ],
                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }

  // ── widgets ─────────────────────────────────────────
  Widget _stepLabel(int n, String text) => Row(
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: const BoxDecoration(
                color: AppColors.primary, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Text('$n',
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 13)),
          ),
          const SizedBox(width: 10),
          Text(text,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark)),
        ],
      );

  Widget _categoryGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.6,
      children: _categories.map((c) {
        final name = c['name'] as String;
        final meta = _catMeta[name] ?? (Icons.category, AppColors.primary, '📦');
        final selected = _selectedCategory?['category_id'] == c['category_id'];
        return GestureDetector(
          onTap: () => _onCategoryPicked(c),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              color: selected ? meta.$2 : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: selected ? meta.$2 : const Color(0xFFE0E0E0),
                  width: 1.5),
              boxShadow: selected
                  ? [BoxShadow(color: meta.$2.withOpacity(0.3), blurRadius: 8)]
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(meta.$3, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 8),
                Text(name,
                    style: TextStyle(
                        color: selected ? Colors.white : AppColors.textDark,
                        fontWeight: FontWeight.w700,
                        fontSize: 14)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _productList() {
    if (_products.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(8),
        child: Text('No products in this category'),
      );
    }

    final q = _productQuery.trim().toLowerCase();
    final filtered = q.isEmpty
        ? _products
        : _products
            .where((p) => (p['name'] as String).toLowerCase().startsWith(q))
            .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _productSearchController,
          onChanged: (v) => setState(() => _productQuery = v),
          decoration: InputDecoration(
            hintText: 'Type to search... (e.g. "R" → Rice, Rod)',
            hintStyle: const TextStyle(color: AppColors.textGrey, fontSize: 13),
            prefixIcon: const Icon(Icons.search, color: AppColors.textGrey),
            suffixIcon: _productQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close, color: AppColors.textGrey),
                    onPressed: () {
                      _productSearchController.clear();
                      setState(() => _productQuery = '');
                    },
                  )
                : null,
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: AppColors.primary, width: 2)),
          ),
        ),
        const SizedBox(height: 12),
        if (filtered.isEmpty)
          const Padding(
            padding: EdgeInsets.all(12),
            child: Text('No matching products',
                style: TextStyle(color: AppColors.textGrey)),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: filtered.map((p) {
              final selected =
                  _selectedProduct?['product_id'] == p['product_id'];
              return GestureDetector(
                onTap: () => _onProductPicked(p),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.primary : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: selected
                            ? AppColors.primary
                            : const Color(0xFFE0E0E0)),
                  ),
                  child: Text(p['name'] as String,
                      style: TextStyle(
                          color:
                              selected ? Colors.white : AppColors.textDark,
                          fontWeight: FontWeight.w600,
                          fontSize: 13)),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _variantChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _variants.map((v) {
        final selected = _selectedVariant?['variant_id'] == v['variant_id'];
        return GestureDetector(
          onTap: () => setState(() => _selectedVariant = v),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: selected ? AppColors.supplierGreen : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: selected
                      ? AppColors.supplierGreen
                      : const Color(0xFFE0E0E0)),
            ),
            child: Text(v['variant_name'] as String,
                style: TextStyle(
                    color: selected ? Colors.white : AppColors.textDark,
                    fontWeight: FontWeight.w600,
                    fontSize: 13)),
          ),
        );
      }).toList(),
    );
  }

  Widget _quantityInput() {
    return Column(
      children: [
        TextField(
          controller: _qtyController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
          textAlign: TextAlign.center,
          decoration: InputDecoration(
            hintText: '0',
            hintStyle: const TextStyle(color: AppColors.textGrey),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primary, width: 2)),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: _units.map((u) {
            final sel = _unit == u;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: GestureDetector(
                  onTap: () => setState(() => _unit = u),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: sel ? AppColors.primary : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: sel
                              ? AppColors.primary
                              : const Color(0xFFE0E0E0)),
                    ),
                    alignment: Alignment.center,
                    child: Text(u,
                        style: TextStyle(
                            color: sel ? Colors.white : AppColors.textDark,
                            fontWeight: FontWeight.w700,
                            fontSize: 13)),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _locationButton() {
    final has = _location != null;
    return GestureDetector(
      onTap: _pickLocation,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: has ? AppColors.primary : const Color(0xFFE0E0E0),
              width: has ? 1.5 : 1),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.map_rounded,
                  color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: has
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_location!.address,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textDark)),
                        const SizedBox(height: 2),
                        Text('Tap to change',
                            style: TextStyle(
                                fontSize: 11,
                                color: AppColors.primary.withOpacity(0.8))),
                      ],
                    )
                  : const Text('Tap to choose on map',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textGrey)),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textGrey),
          ],
        ),
      ),
    );
  }

  Widget _notesField() {
    return TextField(
      controller: _notesController,
      maxLines: 3,
      decoration: InputDecoration(
        hintText: 'e.g. need by tomorrow morning',
        hintStyle: const TextStyle(color: AppColors.textGrey, fontSize: 13),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.all(12),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary, width: 2)),
      ),
    );
  }

  Widget _submitButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton.icon(
        onPressed: _submitting ? null : _submit,
        icon: _submitting
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2))
            : const Icon(Icons.send_rounded),
        label: Text(_submitting ? 'Posting...' : 'Post Demand',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFE65100),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }
}
