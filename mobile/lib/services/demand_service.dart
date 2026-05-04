import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'auth_service.dart';

class DemandService {
  static Future<Map<String, String>> _authHeaders() async {
    final token = await AuthService.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Get all 4 categories: Grocery, Pharmacy, Stationary, Hardware.
  static Future<List<Map<String, dynamic>>> getCategories() async {
    final res = await http.get(Uri.parse(ApiConfig.categories));
    if (res.statusCode != 200) return [];
    final data = jsonDecode(res.body);
    return List<Map<String, dynamic>>.from(data['categories'] ?? []);
  }

  /// Get products in a category, each with nested variants.
  static Future<List<Map<String, dynamic>>> getProductsByCategory(int catId) async {
    final res = await http.get(Uri.parse(ApiConfig.productsByCategory(catId)));
    if (res.statusCode != 200) return [];
    final data = jsonDecode(res.body);
    return List<Map<String, dynamic>>.from(data['products'] ?? []);
  }

  /// Post a new demand. Returns {statusCode, ...} map.
  static Future<Map<String, dynamic>> createDemand({
    required int productId,
    required int variantId,
    required double quantity,
    required String unit,
    String? locationArea,
    double? lat,
    double? lng,
    String? notes,
  }) async {
    final res = await http.post(
      Uri.parse(ApiConfig.createDemand),
      headers: await _authHeaders(),
      body: jsonEncode({
        'product_id': productId,
        'variant_id': variantId,
        'quantity': quantity,
        'unit': unit,
        if (locationArea != null) 'location_area': locationArea,
        if (lat != null) 'lat': lat,
        if (lng != null) 'lng': lng,
        if (notes != null && notes.isNotEmpty) 'additional_notes': notes,
      }),
    );
    final data = jsonDecode(res.body);
    return {'statusCode': res.statusCode, ...data};
  }

  /// Get the logged-in shop owner's demands.
  static Future<List<Map<String, dynamic>>> getMyDemands() async {
    final res = await http.get(
      Uri.parse(ApiConfig.myDemands),
      headers: await _authHeaders(),
    );
    if (res.statusCode != 200) return [];
    final data = jsonDecode(res.body);
    return List<Map<String, dynamic>>.from(data['demands'] ?? []);
  }

  /// Get one demand by id (owner-only).
  static Future<Map<String, dynamic>?> getDemand(int id) async {
    final res = await http.get(
      Uri.parse(ApiConfig.demandById(id)),
      headers: await _authHeaders(),
    );
    if (res.statusCode != 200) return null;
    return Map<String, dynamic>.from(jsonDecode(res.body)['demand']);
  }

  /// Cancel (delete) a demand. Returns true on success.
  static Future<({bool ok, String? error})> cancelDemand(int id) async {
    final res = await http.delete(
      Uri.parse(ApiConfig.demandById(id)),
      headers: await _authHeaders(),
    );
    if (res.statusCode == 200) return (ok: true, error: null);
    final data = jsonDecode(res.body);
    return (ok: false, error: data['error']?.toString());
  }

  /// Shop dashboard stats: open_demands, matched_demands, active_orders.
  static Future<Map<String, int>> getShopStats() async {
    final res = await http.get(
      Uri.parse(ApiConfig.shopStats),
      headers: await _authHeaders(),
    );
    if (res.statusCode != 200) {
      return {'open_demands': 0, 'matched_demands': 0, 'active_orders': 0};
    }
    final data = jsonDecode(res.body);
    return {
      'open_demands': (data['open_demands'] ?? 0) as int,
      'matched_demands': (data['matched_demands'] ?? 0) as int,
      'active_orders': (data['active_orders'] ?? 0) as int,
    };
  }
}
