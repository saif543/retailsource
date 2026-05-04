import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'auth_service.dart';

class OrderService {
  static Future<Map<String, String>> _headers() async {
    final token = await AuthService.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ── Shop owner ─────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getMatches(int demandId) async {
    final res = await http.get(
      Uri.parse(ApiConfig.demandMatches(demandId)),
      headers: await _headers(),
    );
    if (res.statusCode != 200) return [];
    return List<Map<String, dynamic>>.from(
        jsonDecode(res.body)['matches'] ?? []);
  }

  static Future<({bool ok, int? orderId, double? total, String? error})>
      placeOrder({
    required int demandId,
    required int stockId,
    required double quantity,
    required String deliveryAddress,
    double? deliveryLat,
    double? deliveryLng,
  }) async {
    final res = await http.post(
      Uri.parse(ApiConfig.placeOrder),
      headers: await _headers(),
      body: jsonEncode({
        'demand_id': demandId,
        'stock_id': stockId,
        'quantity': quantity,
        'delivery_address': deliveryAddress,
        if (deliveryLat != null) 'delivery_lat': deliveryLat,
        if (deliveryLng != null) 'delivery_lng': deliveryLng,
      }),
    );
    final data = jsonDecode(res.body);
    if (res.statusCode == 201) {
      return (
        ok: true,
        orderId: data['order_id'] as int?,
        total: (data['total_price'] as num?)?.toDouble(),
        error: null,
      );
    }
    return (ok: false, orderId: null, total: null, error: data['error']?.toString());
  }

  static Future<List<Map<String, dynamic>>> searchStocks({
    String? q,
    int? categoryId,
  }) async {
    final res = await http.get(
      Uri.parse(ApiConfig.searchStocks(q: q, categoryId: categoryId)),
      headers: await _headers(),
    );
    if (res.statusCode != 200) return [];
    return List<Map<String, dynamic>>.from(jsonDecode(res.body)['stocks'] ?? []);
  }

  /// Returns orders for the shop owner, mapped to widget-friendly keys.
  static Future<List<Map<String, dynamic>>> getMyOrders() async {
    final res = await http.get(
      Uri.parse(ApiConfig.myOrders),
      headers: await _headers(),
    );
    if (res.statusCode != 200) return [];
    final raw = List<Map<String, dynamic>>.from(
        jsonDecode(res.body)['orders'] ?? []);
    return raw.map((o) => {
      'id': 'ORD-${o['order_id']}',
      'order_id': o['order_id'],
      'product': '${o['product_name']} - ${o['variant_name']}',
      'product_name': o['product_name'],
      'variant_name': o['variant_name'],
      'qty': '${(o['quantity'] as num?)?.toStringAsFixed(0)} ${o['unit']}',
      'quantity': o['quantity'],
      'unit': o['unit'],
      'price': (o['total_price'] as num?)?.toDouble() ?? 0.0,
      'supplier': o['stockholder_name'] ?? '',
      'stockholder_name': o['stockholder_name'],
      'status': o['status'] ?? 'pending',
      'time': _timeAgo(o['created_at'] as String?),
      'created_at': o['created_at'],
      'has_rating': o['has_rating'] == true || o['has_rating'] == 1,
    }).toList();
  }

  /// Single order status — includes OTP when out_for_delivery.
  static Future<Map<String, dynamic>?> getOrderStatus(int orderId) async {
    final res = await http.get(
      Uri.parse(ApiConfig.orderStatus(orderId)),
      headers: await _headers(),
    );
    if (res.statusCode != 200) return null;
    return Map<String, dynamic>.from(jsonDecode(res.body)['order'] ?? {});
  }

  // ── Stockholder ────────────────────────────────────────

  /// Returns incoming orders for the stockholder, mapped to widget-friendly keys.
  static Future<List<Map<String, dynamic>>> getIncomingOrders() async {
    final res = await http.get(
      Uri.parse(ApiConfig.incomingOrders),
      headers: await _headers(),
    );
    if (res.statusCode != 200) return [];
    final raw = List<Map<String, dynamic>>.from(
        jsonDecode(res.body)['orders'] ?? []);
    return raw.map((o) => {
      'id': 'ORD-${o['order_id']}',
      'order_id': o['order_id'],
      'shop': o['shop_owner_name'] ?? '',
      'shopName': o['shop_name'] ?? '',
      'area': o['shop_area'] ?? '',
      'product': '${o['product_name']} - ${o['variant_name']}',
      'product_name': o['product_name'],
      'variant_name': o['variant_name'],
      'qty': '${(o['quantity'] as num?)?.toStringAsFixed(0)} ${o['unit']}',
      'quantity': o['quantity'],
      'unit': o['unit'],
      'price': (o['total_price'] as num?)?.toDouble() ?? 0.0,
      'status': o['status'] ?? 'pending',
      'time': _timeAgo(o['created_at'] as String?),
      'created_at': o['created_at'],
      // Location only set when not pending
      'delivery_address': o['delivery_address'],
      'shop_owner_phone': o['shop_owner_phone'],
      'location_note': o['location_note'],
    }).toList();
  }

  static Future<({bool ok, String? error})> acceptOrder(int orderId) async {
    final res = await http.post(
      Uri.parse(ApiConfig.acceptOrder(orderId)),
      headers: await _headers(),
    );
    if (res.statusCode == 200) return (ok: true, error: null);
    return (ok: false, error: jsonDecode(res.body)['error']?.toString());
  }

  static Future<({bool ok, String? error})> declineOrder(int orderId) async {
    final res = await http.post(
      Uri.parse(ApiConfig.declineOrder(orderId)),
      headers: await _headers(),
    );
    if (res.statusCode == 200) return (ok: true, error: null);
    return (ok: false, error: jsonDecode(res.body)['error']?.toString());
  }

  static Future<({bool ok, String? error})> markDelivered(int orderId) async {
    final res = await http.post(
      Uri.parse(ApiConfig.markDelivered(orderId)),
      headers: await _headers(),
    );
    if (res.statusCode == 200) return (ok: true, error: null);
    return (ok: false, error: jsonDecode(res.body)['error']?.toString());
  }

  /// Shop owner generates OTP for the delivery person to enter.
  static Future<({bool ok, String? otp, String? error})> generateOtp(
      int orderId) async {
    final res = await http.post(
      Uri.parse(ApiConfig.generateOtp(orderId)),
      headers: await _headers(),
    );
    final data = jsonDecode(res.body);
    if (res.statusCode == 200) {
      return (ok: true, otp: data['otp']?.toString(), error: null);
    }
    return (ok: false, otp: null, error: data['error']?.toString());
  }

  static Future<({bool ok, String? error})> verifyOtp(
      int orderId, String code) async {
    final res = await http.post(
      Uri.parse(ApiConfig.verifyOtp(orderId)),
      headers: await _headers(),
      body: jsonEncode({'otp': code}),
    );
    if (res.statusCode == 200) return (ok: true, error: null);
    return (ok: false, error: jsonDecode(res.body)['error']?.toString());
  }

  // ── Helpers ────────────────────────────────────────────

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
