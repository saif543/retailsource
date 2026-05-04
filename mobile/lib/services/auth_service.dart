import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class AuthService {
  /// Register a new shop owner
  static Future<Map<String, dynamic>> registerShopOwner({
    required String name,
    required String phone,
    required String password,
    required String shopName,
    required String shopCategory,
    String? email,
    String? shopAddress,
    String? district,
    String? area,
    double? lat,
    double? lng,
  }) async {
    final body = <String, dynamic>{
      'name': name,
      'phone': phone,
      'password': password,
      'shop_name': shopName,
      'shop_category': shopCategory,
    };

    if (email != null && email.isNotEmpty) body['email'] = email;
    if (shopAddress != null && shopAddress.isNotEmpty) body['shop_address'] = shopAddress;
    if (district != null && district.isNotEmpty) body['district'] = district;
    if (area != null && area.isNotEmpty) body['area'] = area;
    if (lat != null) body['lat'] = lat.toString();
    if (lng != null) body['lng'] = lng.toString();

    final response = await http.post(
      Uri.parse(ApiConfig.registerShopOwner),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 201) {
      await _saveToken(data['token']);
      await _saveUser(data['user']);
    }

    return {'statusCode': response.statusCode, ...data};
  }

  /// Register a new stockholder/supplier
  static Future<Map<String, dynamic>> registerStockholder({
    required String name,
    required String phone,
    required String password,
    required String companyName,
    required List<String> categories,
    String? email,
    String? warehouseAddress,
    String? district,
    String? area,
    double? lat,
    double? lng,
  }) async {
    final body = <String, dynamic>{
      'name': name,
      'phone': phone,
      'password': password,
      'company_name': companyName,
      'categories': categories,
    };

    if (email != null && email.isNotEmpty) body['email'] = email;
    if (warehouseAddress != null && warehouseAddress.isNotEmpty) body['warehouse_address'] = warehouseAddress;
    if (district != null && district.isNotEmpty) body['district'] = district;
    if (area != null && area.isNotEmpty) body['area'] = area;
    if (lat != null) body['lat'] = lat.toString();
    if (lng != null) body['lng'] = lng.toString();

    final response = await http.post(
      Uri.parse(ApiConfig.registerStockholder),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 201) {
      await _saveToken(data['token']);
      await _saveUser(data['user']);
    }

    return {'statusCode': response.statusCode, ...data};
  }

  /// Login with email or phone + password
  static Future<Map<String, dynamic>> login({
    required String emailOrPhone,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse(ApiConfig.login),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email_or_phone': emailOrPhone,
        'password': password,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      await _saveToken(data['token']);
      await _saveUser(data['user']);
    }

    return {'statusCode': response.statusCode, ...data};
  }

  /// Logout — clear saved token and user
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user');
  }

  /// Get saved token
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  /// Get saved user info
  static Future<Map<String, dynamic>?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userStr = prefs.getString('user');
    if (userStr == null) return null;
    return jsonDecode(userStr);
  }

  /// Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null;
  }

  // Private helpers
  static Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  static Future<void> _saveUser(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user', jsonEncode(user));
  }
}
