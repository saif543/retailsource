import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'auth_service.dart';

class StockService {
  static Future<Map<String, String>> _headers() async {
    final token = await AuthService.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<Map<String, int>> getDashboard() async {
    final res = await http.get(
      Uri.parse(ApiConfig.stockDashboard),
      headers: await _headers(),
    );
    if (res.statusCode != 200) {
      return {'active_stock': 0, 'new_orders': 0, 'delivered': 0, 'active_orders': 0};
    }
    final d = jsonDecode(res.body);
    return {
      'active_stock': (d['active_stock'] ?? 0) as int,
      'new_orders': (d['new_orders'] ?? 0) as int,
      'delivered': (d['total_delivered'] ?? 0) as int,
      'active_orders': (d['active_orders'] ?? 0) as int,
    };
  }

  /// Returns the stockholder's own stock, mapped to widget-friendly keys.
  static Future<List<Map<String, dynamic>>> getMyStock() async {
    final res = await http.get(
      Uri.parse(ApiConfig.myStock),
      headers: await _headers(),
    );
    if (res.statusCode != 200) return [];
    final raw = List<Map<String, dynamic>>.from(
        jsonDecode(res.body)['stocks'] ?? []);
    return raw.map((s) {
      final qty = s['quantity_available'] as num?;
      final unit = s['unit'] ?? '';
      final price = s['price_per_unit'] as num?;
      return {
        'stock_id': s['stock_id'],
        'product': '${s['product_name']} - ${s['variant_name']}',
        'product_name': s['product_name'],
        'variant_name': s['variant_name'],
        'qty': '${qty?.toStringAsFixed(0)} $unit',
        'quantity_available': qty,
        'unit': unit,
        'price': '৳${price?.toStringAsFixed(0)}/$unit',
        'price_per_unit': price,
        'loc': s['warehouse_area'] ?? '',
        'status': s['status'] == 'available' ? 'Available' : 'Sold Out',
        'views': 0,
        'interested': 0,
        'posted': _timeAgo(s['created_at'] as String?),
        'created_at': s['created_at'],
        'notes': s['additional_notes'] ?? '',
      };
    }).toList();
  }

  static Future<({bool ok, int? stockId, String? error})> createStock({
    required int productId,
    required int variantId,
    required double quantity,
    required String unit,
    required double price,
    String? warehouseArea,
    double? lat,
    double? lng,
    String? notes,
  }) async {
    final res = await http.post(
      Uri.parse(ApiConfig.createStock),
      headers: await _headers(),
      body: jsonEncode({
        'product_id': productId,
        'variant_id': variantId,
        'quantity_available': quantity,
        'unit': unit,
        'price_per_unit': price,
        if (warehouseArea != null && warehouseArea.isNotEmpty)
          'warehouse_area': warehouseArea,
        if (lat != null) 'lat': lat,
        if (lng != null) 'lng': lng,
        if (notes != null && notes.isNotEmpty) 'additional_notes': notes,
      }),
    );
    final data = jsonDecode(res.body);
    if (res.statusCode == 201) {
      return (ok: true, stockId: data['stock_id'] as int?, error: null);
    }
    return (ok: false, stockId: null, error: data['error']?.toString());
  }

  static Future<({bool ok, String? error})> updateStock(
    int stockId, {
    double? quantity,
    double? price,
    String? warehouseArea,
    String? notes,
    String? status,
  }) async {
    final body = <String, dynamic>{};
    if (quantity != null) body['quantity_available'] = quantity;
    if (price != null) body['price_per_unit'] = price;
    if (warehouseArea != null) body['warehouse_area'] = warehouseArea;
    if (notes != null) body['additional_notes'] = notes;
    if (status != null) body['status'] = status;

    final res = await http.put(
      Uri.parse(ApiConfig.updateStock(stockId)),
      headers: await _headers(),
      body: jsonEncode(body),
    );
    if (res.statusCode == 200) return (ok: true, error: null);
    return (ok: false, error: jsonDecode(res.body)['error']?.toString());
  }

  static Future<({bool ok, String? error})> deleteStock(int stockId) async {
    final res = await http.delete(
      Uri.parse(ApiConfig.deleteStock(stockId)),
      headers: await _headers(),
    );
    if (res.statusCode == 200) return (ok: true, error: null);
    return (ok: false, error: jsonDecode(res.body)['error']?.toString());
  }

  static Future<List<Map<String, dynamic>>> getNearbyDemands() async {
    final res = await http.get(
      Uri.parse(ApiConfig.nearbyDemands),
      headers: await _headers(),
    );
    if (res.statusCode != 200) return [];
    final raw = List<Map<String, dynamic>>.from(
        jsonDecode(res.body)['demands'] ?? []);
    return raw.map((d) => {
      'demand_id': d['demand_id'],
      'shop': d['shop_name'] ?? d['shop_owner_name'] ?? '',
      'owner': d['shop_owner_name'] ?? '',
      'product': '${d['product_name']} - ${d['variant_name']}',
      'product_name': d['product_name'],
      'variant_name': d['variant_name'],
      'category': d['category_name'] ?? '',
      'qty': '${(d['quantity'] as num?)?.toStringAsFixed(0)} ${d['unit']}',
      'area': d['location_area'] ?? '',
      'distance': (d['distance_km'] as num?)?.toDouble() ?? 0.0,
      'time': _timeAgo(d['created_at'] as String?),
      'notes': d['additional_notes'] ?? '',
    }).toList();
  }

  static String _timeAgo(String? iso) {
    if (iso == null) return '';
    final t = DateTime.tryParse(iso);
    if (t == null) return '';
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 60) return '${d.inMinutes}m ago';
    if (d.inHours < 24) return '${d.inHours}h ago';
    return '${d.inDays}d ago';
  }
}
