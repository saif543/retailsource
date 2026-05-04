// Matching Suppliers — search + sort + nearby stockholder cards.

import 'package:flutter/material.dart';
import '../../config/app_colors.dart';
import '../../services/order_service.dart';
import 'order_confirm_screen.dart';
import 'supplier_detail_screen.dart';

class MatchingSuppliersScreen extends StatefulWidget {
  final int demandId;
  final String productLabel;
  final double demandQuantity;
  final String demandUnit;
  final String? deliveryArea;
  final double? deliveryLat;
  final double? deliveryLng;

  const MatchingSuppliersScreen({
    super.key,
    required this.demandId,
    required this.productLabel,
    required this.demandQuantity,
    required this.demandUnit,
    this.deliveryArea,
    this.deliveryLat,
    this.deliveryLng,
  });

  @override
  State<MatchingSuppliersScreen> createState() => _MatchingSuppliersScreenState();
}

enum _SortBy { nearest, cheapest, topRated }

class _MatchingSuppliersScreenState extends State<MatchingSuppliersScreen> {
  List<Map<String, dynamic>> _all = [];
  bool _loading = true;
  String _query = '';
  _SortBy _sort = _SortBy.nearest;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = await OrderService.getMatches(widget.demandId);
    if (!mounted) return;
    setState(() {
      _all = list;
      _loading = false;
    });
  }

  List<Map<String, dynamic>> get _visible {
    final q = _query.trim().toLowerCase();
    var list = q.isEmpty
        ? List<Map<String, dynamic>>.from(_all)
        : _all.where((m) {
            final name = (m['company_name'] ?? m['stockholder_name'] ?? '')
                .toString()
                .toLowerCase();
            final area = (m['warehouse_area'] ?? '').toString().toLowerCase();
            return name.contains(q) || area.contains(q);
          }).toList();

    switch (_sort) {
      case _SortBy.nearest:
        list.sort((a, b) =>
            (a['distance_km'] as num).compareTo(b['distance_km'] as num));
        break;
      case _SortBy.cheapest:
        list.sort((a, b) =>
            (a['price_per_unit'] as num).compareTo(b['price_per_unit'] as num));
        break;
      case _SortBy.topRated:
        list.sort((a, b) =>
            ((b['rating_avg'] ?? 0) as num).compareTo((a['rating_avg'] ?? 0) as num));
        break;
    }
    return list;
  }

  Future<void> _openConfirm(Map<String, dynamic> m) async {
    final placed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => SupplierDetailScreen(
          demandId: widget.demandId,
          match: m,
          productLabel: widget.productLabel,
          demandQuantity: widget.demandQuantity,
          deliveryArea: widget.deliveryArea,
          deliveryLat: widget.deliveryLat,
          deliveryLng: widget.deliveryLng,
        ),
      ),
    );
    if (placed == true && mounted) Navigator.pop(context, true);
  }

  // ignore: unused_element
  Future<void> _legacyConfirm(Map<String, dynamic> m) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OrderConfirmScreen(
          demandId: widget.demandId,
          stockId: m['stock_id'] as int,
          supplierName:
              (m['company_name'] ?? m['stockholder_name']) as String,
          productLabel: widget.productLabel,
          pricePerUnit: (m['price_per_unit'] as num).toDouble(),
          unit: m['unit'] as String,
          maxQuantity: (m['quantity_available'] as num).toDouble(),
          defaultQuantity: widget.demandQuantity,
          defaultAddress: widget.deliveryArea,
          deliveryLat: widget.deliveryLat,
          deliveryLng: widget.deliveryLng,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final list = _visible;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            pinned: true,
            expandedHeight: 156,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 56, bottom: 14),
              title: const Text('Nearby Suppliers',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.primary, Color(0xFF1976D2)],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 60, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.shopping_basket_rounded,
                              size: 16, color: Colors.white70),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              '${widget.demandQuantity.toStringAsFixed(0)} ${widget.demandUnit} • ${widget.productLabel}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 38),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                  onPressed: _load, icon: const Icon(Icons.refresh_rounded)),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2)),
                  ],
                ),
                child: TextField(
                  onChanged: (v) => setState(() => _query = v),
                  decoration: const InputDecoration(
                    hintText: 'Search supplier or area...',
                    prefixIcon: Icon(Icons.search_rounded,
                        color: AppColors.textGrey),
                    border: InputBorder.none,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                children: [
                  _sortChip('Nearest', Icons.near_me_rounded, _SortBy.nearest),
                  _sortChip('Cheapest', Icons.attach_money_rounded, _SortBy.cheapest),
                  _sortChip('Top Rated', Icons.star_rounded, _SortBy.topRated),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Text(
                _loading
                    ? ''
                    : '${list.length} supplier${list.length == 1 ? '' : 's'} found',
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textGrey),
              ),
            ),
          ),
          if (_loading)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: CircularProgressIndicator()),
            )
          else if (list.isEmpty)
            SliverFillRemaining(hasScrollBody: false, child: _empty()),
          if (!_loading && list.isNotEmpty)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 24),
              sliver: SliverList.builder(
                itemCount: list.length,
                itemBuilder: (_, i) => _card(list[i], i == 0),
              ),
            ),
        ],
      ),
    );
  }

  Widget _sortChip(String label, IconData icon, _SortBy value) {
    final selected = _sort == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => setState(() => _sort = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: selected ? AppColors.primary : const Color(0xFFE0E0E0)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon,
                  size: 14,
                  color: selected ? Colors.white : AppColors.textGrey),
              const SizedBox(width: 5),
              Text(label,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: selected ? Colors.white : AppColors.textDark)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _card(Map<String, dynamic> m, bool isBest) {
    final dist = (m['distance_km'] as num).toDouble();
    final price = (m['price_per_unit'] as num).toDouble();
    final qty = (m['quantity_available'] as num).toDouble();
    final rating = (m['rating_avg'] as num?)?.toDouble() ?? 0;
    final name = (m['company_name'] ?? m['stockholder_name']) as String;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isBest
            ? Border.all(color: const Color(0xFF2E7D32), width: 1.5)
            : null,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          if (isBest)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 5),
              decoration: const BoxDecoration(
                color: Color(0xFF2E7D32),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(15),
                  topRight: Radius.circular(15),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.verified_rounded, size: 14, color: Colors.white),
                  SizedBox(width: 5),
                  Text('BEST MATCH',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.6)),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF2E7D32), Color(0xFF4CAF50)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.warehouse_rounded,
                          color: Colors.white, size: 26),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textDark)),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              const Icon(Icons.star_rounded,
                                  size: 14, color: Colors.amber),
                              const SizedBox(width: 2),
                              Text(rating > 0 ? rating.toStringAsFixed(1) : 'New',
                                  style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textDark)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1565C0).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.near_me_rounded,
                              size: 14, color: AppColors.primary),
                          Text('${dist.toStringAsFixed(1)} km',
                              style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primary)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F7FB),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _stat(
                            '৳${price.toStringAsFixed(0)}',
                            'per ${m['unit']}',
                            const Color(0xFFE65100)),
                      ),
                      Container(
                          height: 30, width: 1, color: const Color(0xFFE0E0E0)),
                      Expanded(
                        child: _stat(
                            '${qty.toStringAsFixed(0)}',
                            '${m['unit']} stock',
                            const Color(0xFF2E7D32)),
                      ),
                      if ((m['warehouse_area'] ?? '').toString().isNotEmpty) ...[
                        Container(
                            height: 30, width: 1, color: const Color(0xFFE0E0E0)),
                        Expanded(
                          flex: 2,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Column(
                              children: [
                                const Icon(Icons.place_rounded,
                                    size: 14, color: AppColors.textGrey),
                                const SizedBox(height: 2),
                                Text(m['warehouse_area'] as String,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textDark)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton.icon(
                    onPressed: () => _openConfirm(m),
                    icon: const Icon(
                        Icons.shopping_cart_checkout_rounded, size: 18),
                    label: Text(
                        'Order ${widget.demandQuantity.toStringAsFixed(0)} ${widget.demandUnit} • ৳${(price * widget.demandQuantity).toStringAsFixed(0)}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 13.5)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _stat(String top, String bottom, Color color) {
    return Column(
      children: [
        Text(top,
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: color)),
        Text(bottom,
            style: const TextStyle(
                fontSize: 10, color: AppColors.textGrey)),
      ],
    );
  }

  Widget _empty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.search_off_rounded,
                size: 54, color: AppColors.primary),
          ),
          const SizedBox(height: 18),
          const Text('No suppliers found',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark)),
          const SizedBox(height: 6),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'No stockholder within 10km has this product right now. Pull to refresh or try later.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textGrey, fontSize: 13),
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _load,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Refresh'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }
}
