import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'auth_service.dart';
import 'location_service.dart';

class ProfileService {
  /// Save user's address + lat/lng to their profile.
  static Future<Map<String, dynamic>> saveLocation(LocationResult loc) async {
    final token = await AuthService.getToken();
    if (token == null) {
      return {'statusCode': 401, 'error': 'Not logged in'};
    }

    final res = await http.put(
      Uri.parse(ApiConfig.updateLocation),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'address': loc.address,
        'lat': loc.lat,
        'lng': loc.lng,
        'area': loc.area,
        'district': loc.district,
      }),
    );

    final data = jsonDecode(res.body);
    return {'statusCode': res.statusCode, ...data};
  }
}
