import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConfig {
  // Auto-detect: use localhost for web, 10.0.2.2 for Android emulator
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:5000/api';
    }
    return 'http://10.0.2.2:5000/api';
  }

  // Auth endpoints
  static String get registerShopOwner => '$baseUrl/auth/register/shop-owner';
  static String get registerStockholder => '$baseUrl/auth/register/stockholder';
  static String get login => '$baseUrl/auth/login';
  static String get me => '$baseUrl/auth/me';

  // Profile
  static String get updateLocation => '$baseUrl/profile/location';
}
