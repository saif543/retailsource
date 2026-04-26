import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class LocationResult {
  final double lat;
  final double lng;
  final String address;
  final String area;
  final String district;

  LocationResult({
    required this.lat,
    required this.lng,
    required this.address,
    required this.area,
    required this.district,
  });
}

class LocationService {
  /// Get current GPS coords. Throws on permission/service error.
  static Future<({double lat, double lng})> getCurrentCoords() async {
    if (!kIsWeb) {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw 'service_disabled';
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) throw 'permission_denied';
    }
    if (permission == LocationPermission.deniedForever) {
      throw 'permission_denied';
    }

    final pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    return (lat: pos.latitude, lng: pos.longitude);
  }

  /// Reverse-geocode lat/lng → address text via free OSM Nominatim API.
  /// Works on web and mobile (HTTP-based, no native plugin).
  static Future<LocationResult> reverseGeocode(double lat, double lng) async {
    final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lng&zoom=18&addressdetails=1&accept-language=en');

    try {
      final res = await http.get(url, headers: {
        'User-Agent': 'SupplyLink/1.0 (Bangladesh shop-supplier app)',
      });
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final addr = data['address'] ?? {};
        final area = (addr['suburb'] ?? addr['neighbourhood'] ??
            addr['village'] ?? addr['town'] ?? addr['city_district'] ?? '').toString();
        final district = (addr['city'] ?? addr['state_district'] ?? addr['county'] ?? addr['state'] ?? '').toString();
        final fullAddress = (data['display_name'] ?? '').toString();

        return LocationResult(
          lat: lat,
          lng: lng,
          address: fullAddress,
          area: area,
          district: district,
        );
      }
    } catch (_) {}

    // Fallback: return coords as address text
    return LocationResult(
      lat: lat,
      lng: lng,
      address: '${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}',
      area: '',
      district: '',
    );
  }

  /// Convenience: GPS + reverse geocode in one call.
  static Future<LocationResult> getCurrentLocation() async {
    final coords = await getCurrentCoords();
    return reverseGeocode(coords.lat, coords.lng);
  }
}
