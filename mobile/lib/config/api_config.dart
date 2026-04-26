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
<<<<<<< HEAD

  // Products
  static String get categories => '$baseUrl/products/categories';
  static String productsByCategory(int catId) => '$baseUrl/products/by-category/$catId';

  // Demands
  static String get createDemand => '$baseUrl/demands/create';
  static String get myDemands => '$baseUrl/demands/my';
  static String demandById(int id) => '$baseUrl/demands/$id';

  // Shop dashboard
  static String get shopStats => '$baseUrl/shop/stats';
=======
>>>>>>> 15b0678d03781c17983fb616c22699d368855ae5
}
