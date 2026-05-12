// Supplier Detail — full info + Order Now / Call buttons.

import 'package:flutter/material.dart';
import '../../config/app_colors.dart';
import 'order_confirm_screen.dart';

class SupplierDetailScreen extends StatelessWidget {
  final int demandId;
  final Map<String, dynamic> match;
  final String productLabel;
  final double demandQuantity;
  final String? deliveryArea;
  final double? deliveryLat;
  final double? deliveryLng;

  const SupplierDetailScreen({
    super.key,
    required this.demandId,
    required this.match,
    required this.productLabel,
    required this.demandQuantity,
    this.deliveryArea,
    this.deliveryLat,
    this.deliveryLng,
  });

  void _call(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.phone, color: AppColors.primaryGreen),
            SizedBox(width: 8),
            Text('Call Supplier'),
          ],
        ),
        content: const Text('Dialing +880 1712-345678 ...'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('End Call'),
          ),
        ],
      ),
    );
  }

  Future<void> _orderNow(BuildContext context) async {
    final placed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => OrderConfirmScreen(
          demandId: demandId,
          stockId: match['stock_id'] as int,
          supplierName:
              (match['company_name'] ?? match['stockholder_name']) as String,
          productLabel: productLabel,
          pricePerUnit: (match['price_per_unit'] as num).toDouble(),
          unit: match['unit'] as String,
          maxQuantity: (match['quantity_available'] as num).toDouble(),
          defaultQuantity: demandQuantity,
          defaultAddress: deliveryArea,
          deliveryLat: deliveryLat,
          deliveryLng: deliveryLng,
        ),
      ),
    );
    if (placed == true && context.mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final m = match;
    final price = (m['price_per_unit'] as num).toDouble();
    final qty = (m['quantity_available'] as num).toDouble();
    final dist = (m['distance_km'] as num?)?.toDouble();
    final rating = (m['rating_avg'] as num?)?.toDouble() ?? 4.9;
    final name = (m['company_name'] ?? m['stockholder_name']) as String;
    final initials = name
        .split(' ')
        .where((s) => s.isNotEmpty)
        .map((s) => s[0])
        .take(2)
        .join();
    final totalCost = price * demandQuantity;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Supplier Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite_border),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: AppColors.primaryGreen,
                        child: Text(initials,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w900)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(name,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w900)),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.verified,
                                    color: AppColors.primary, size: 18),
                              ],
                            ),
                            Text((m['stockholder_name'] ?? 'Trader') as String,
                                style: const TextStyle(
                                    color: AppColors.textGrey, fontSize: 13)),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.star,
                                    color: Colors.amber, size: 16),
                                const SizedBox(width: 4),
                                Text(rating.toStringAsFixed(1),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 13)),
                                const SizedBox(width: 4),
                                const Text('(127 reviews)',
                                    style: TextStyle(
                                        color: AppColors.textGrey,
                                        fontSize: 12)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(child: _trustChip('8+', 'Years')),
                      Expanded(child: _trustChip('450+', 'Orders')),
                      Expanded(child: _trustChip('< 1hr', 'Response')),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _section('Product Details', [
              Row(
                children: [
                  Expanded(child: _kv('Product', productLabel)),
                  Expanded(
                      child: _kv('Category',
                          (m['category_name'] ?? 'Grocery') as String)),
                ],
              ),
              const Divider(height: 22),
              Row(
                children: [
                  Expanded(
                      child: _kv('Available Quantity',
                          '${qty.toStringAsFixed(0)} ${m['unit']}')),
                  Expanded(
                      child: _kv('Your Requirement',
                          '${demandQuantity.toStringAsFixed(0)} ${m['unit']}')),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Price per Unit',
                              style: TextStyle(
                                  color: AppColors.textGrey, fontSize: 12)),
                          Text('৳${price.toStringAsFixed(0)} / ${m['unit']}',
                              style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.primaryGreen)),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('Total Cost',
                            style: TextStyle(
                                color: AppColors.textGrey, fontSize: 12)),
                        Text('৳${totalCost.toStringAsFixed(0)}',
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: AppColors.primary)),
                      ],
                    ),
                  ],
                ),
              ),
              if ((m['additional_notes'] ?? '').toString().isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F7FB),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Additional Information',
                          style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                              color: AppColors.textDark)),
                      const SizedBox(height: 4),
                      Text(m['additional_notes'] as String,
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textGrey)),
                    ],
                  ),
                ),
              ],
            ]),
            const SizedBox(height: 14),
            _section('Location & Distance', [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFB0BEC5), Color(0xFF78909C)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                              dist != null
                                  ? '${dist.toStringAsFixed(1)} km away'
                                  : 'Within 10 km',
                              style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 11)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                    Text(name,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800)),
                    const Text('Warehouse area, Dhaka',
                        style:
                            TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F7FB),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.place_rounded,
                        color: AppColors.errorRed, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Warehouse Address',
                              style: TextStyle(
                                  fontWeight: FontWeight.w800, fontSize: 12)),
                          Text(
                              (m['warehouse_area'] ??
                                      'House 45, Road 12, Sector 7, Uttara, Dhaka-1230')
                                  as String,
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textGrey)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ]),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () => _orderNow(context),
                icon: const Icon(Icons.shopping_cart_checkout_rounded),
                label: Text(
                    'Order Now • ৳${totalCost.toStringAsFixed(0)}',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w800)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: OutlinedButton.icon(
                onPressed: () => _call(context),
                icon: const Icon(Icons.phone),
                label: const Text('Call Supplier',
                    style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w800)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _trustChip(String value, String label) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FB),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(value,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textDark)),
          Text(label,
              style: const TextStyle(
                  color: AppColors.textGrey, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _section(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textDark)),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _kv(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                color: AppColors.textGrey, fontSize: 12)),
        const SizedBox(height: 2),
        Text(value,
            style: const TextStyle(
                fontWeight: FontWeight.w900, fontSize: 14)),
      ],
    );
  }
}
