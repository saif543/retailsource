import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import 'auth_service.dart';
import 'location_service.dart';

class ProfileService {
  // ── SharedPreferences keys for location cache ──────────────────────────────
  static const _kLat  = 'pfl_lat';
  static const _kLng  = 'pfl_lng';
  static const _kAddr = 'pfl_addr';
  static const _kArea = 'pfl_area';
  static const _kDist = 'pfl_dist';

  /// Write location to local cache (called after every successful DB save).
  static Future<void> _cacheLocation(LocationResult loc) async {
    final p = await SharedPreferences.getInstance();
    await p.setDouble(_kLat,  loc.lat);
    await p.setDouble(_kLng,  loc.lng);
    await p.setString(_kAddr, loc.address);
    await p.setString(_kArea, loc.area);
    await p.setString(_kDist, loc.district);
  }

  /// Read location from local cache — returns null if never saved.
  static Future<LocationResult?> getCachedLocation() async {
    final p = await SharedPreferences.getInstance();
    final lat = p.getDouble(_kLat);
    final lng = p.getDouble(_kLng);
    if (lat == null || lng == null || lat == 0 || lng == 0) return null;
    return LocationResult(
      lat: lat,
      lng: lng,
      address:  p.getString(_kAddr) ?? '',
      area:     p.getString(_kArea) ?? '',
      district: p.getString(_kDist) ?? '',
    );
  }

  /// Clear cached location (e.g. on logout).
  static Future<void> clearCachedLocation() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_kLat); await p.remove(_kLng);
    await p.remove(_kAddr); await p.remove(_kArea); await p.remove(_kDist);
  }

  static Future<Map<String, String>> _headers() async {
    final token = await AuthService.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<Map<String, dynamic>?> getProfile() async {
    try {
      final res = await http.get(
        Uri.parse(ApiConfig.profile),
        headers: await _headers(),
      );
      if (res.statusCode != 200) return null;
      final user = jsonDecode(res.body)['user'] as Map<String, dynamic>?;
      // Seed the local cache from the server profile if not yet cached
      if (user != null) {
        final prof = user['profile'] as Map?;
        final lat = (prof?['lat'] as num?)?.toDouble();
        final lng = (prof?['lng'] as num?)?.toDouble();
        if (lat != null && lat != 0 && lng != null && lng != 0) {
          final role  = user['role'] as String?;
          final addrKey = role == 'shop_owner' ? 'shop_address' : 'warehouse_address';
          await _cacheLocation(LocationResult(
            lat: lat, lng: lng,
            address:  (prof?[addrKey]  as String?) ?? '',
            area:     (prof?['area']   as String?) ?? '',
            district: (prof?['district'] as String?) ?? '',
          ));
        }
      }
      return user;
    } catch (_) {
      return null;
    }
  }

  static Future<({bool ok, String? error})> updateProfile(
      Map<String, dynamic> data) async {
    try {
      final res = await http.put(
        Uri.parse(ApiConfig.updateProfile),
        headers: await _headers(),
        body: jsonEncode(data),
      );
      if (res.statusCode == 200) return (ok: true, error: null);
      return (ok: false, error: jsonDecode(res.body)['error']?.toString());
    } catch (e) {
      return (ok: false, error: e.toString());
    }
  }

  /// Save user's address + lat/lng to their profile (DB + local cache).
  static Future<Map<String, dynamic>> saveLocation(LocationResult loc) async {
    final token = await AuthService.getToken();
    if (token == null) return {'statusCode': 401, 'error': 'Not logged in'};

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
    // Cache locally on success so other screens can read instantly
    if (res.statusCode == 200) await _cacheLocation(loc);
    return {'statusCode': res.statusCode, ...data};
  }
}
