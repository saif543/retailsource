import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'auth_service.dart';

class RatingService {
  static Future<Map<String, String>> _headers() async {
    final token = await AuthService.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<List<Map<String, dynamic>>> getUnratedOrders() async {
    try {
      final res = await http.get(
        Uri.parse(ApiConfig.unratedOrders),
        headers: await _headers(),
      );
      if (res.statusCode != 200) return [];
      final data = jsonDecode(res.body);
      return List<Map<String, dynamic>>.from(data['orders'] ?? []);
    } catch (_) {
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getMyRatings() async {
    try {
      final res = await http.get(
        Uri.parse(ApiConfig.myRatings),
        headers: await _headers(),
      );
      if (res.statusCode != 200) return [];
      final data = jsonDecode(res.body);
      return List<Map<String, dynamic>>.from(data['ratings'] ?? []);
    } catch (_) {
      return [];
    }
  }

  static Future<({bool ok, double? newAvg, String? error})> submitRating({
    required int orderId,
    required int score,
    String? review,
  }) async {
    final res = await http.post(
      Uri.parse(ApiConfig.submitRating),
      headers: await _headers(),
      body: jsonEncode({
        'order_id': orderId,
        'score': score,
        if (review != null && review.isNotEmpty) 'review': review,
      }),
    );
    final data = jsonDecode(res.body);
    if (res.statusCode == 201) {
      return (
        ok: true,
        newAvg: (data['new_avg'] as num?)?.toDouble(),
        error: null,
      );
    }
    return (ok: false, newAvg: null, error: data['error']?.toString());
  }
}
