import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConfig {
  static String get baseUrl {
    if (kIsWeb) return 'http://localhost:5000/api';
    return 'http://192.168.0.202:5000/api';
  }

  // Auth
  static String get registerShopOwner => '$baseUrl/auth/register/shop-owner';
  static String get registerStockholder => '$baseUrl/auth/register/stockholder';
  static String get login => '$baseUrl/auth/login';
  static String get me => '$baseUrl/auth/me';

  // Profile
  static String get profile => '$baseUrl/profile';
  static String get updateProfile => '$baseUrl/profile/update';
  static String get updateLocation => '$baseUrl/profile/location';

  // Products
  static String get categories => '$baseUrl/products/categories';
  static String productsByCategory(int catId) => '$baseUrl/products/by-category/$catId';
<<<<<<< Updated upstream
  static String productVariants(int productId) => '$baseUrl/products/$productId/variants';

  // Demands (shop owner)
  static String get createDemand => '$baseUrl/demands/create';
  static String get myDemands => '$baseUrl/demands/my';
  static String demandById(int id) => '$baseUrl/demands/$id';
  static String demandMatches(int id) => '$baseUrl/demands/$id/matches';

  // Shop dashboard
  static String get shopStats => '$baseUrl/shop/stats';

  // Orders (shop owner)
  static String get placeOrder => '$baseUrl/orders/place';
  static String get myOrders => '$baseUrl/orders/my';
  static String orderStatus(int id) => '$baseUrl/orders/$id/status';
  static String confirmOtp(int id) => '$baseUrl/orders/$id/confirm-otp';

  // Orders (stockholder)
  static String get incomingOrders => '$baseUrl/orders/incoming';
  static String acceptOrder(int id) => '$baseUrl/orders/$id/accept';
  static String declineOrder(int id) => '$baseUrl/orders/$id/decline';
  static String markDelivered(int id) => '$baseUrl/orders/$id/mark-delivered';
  static String generateOtp(int id) => '$baseUrl/orders/$id/generate-otp';
  static String verifyOtp(int id) => '$baseUrl/orders/$id/verify-otp';

  // Stocks (browse for shop owners)
  static String searchStocks({String? q, int? categoryId}) {
    final params = <String, String>{};
    if (q != null && q.isNotEmpty) params['q'] = q;
    if (categoryId != null) params['category_id'] = '$categoryId';
    final qs = params.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');
    return qs.isEmpty ? '$baseUrl/stocks/search' : '$baseUrl/stocks/search?$qs';
  }

  // Stocks (stockholder)
  static String get stockDashboard => '$baseUrl/stocks/dashboard';
  static String get createStock => '$baseUrl/stocks/create';
  static String get myStock => '$baseUrl/stocks/my';
  static String updateStock(int id) => '$baseUrl/stocks/$id/update';
  static String deleteStock(int id) => '$baseUrl/stocks/$id/delete';
  static String get nearbyDemands => '$baseUrl/stocks/nearby-demands';

  // Notifications
  static String get notifications => '$baseUrl/notifications';
  static String get markNotificationsRead => '$baseUrl/notifications/mark-read';

  // Earnings
  static String get stockholderEarnings => '$baseUrl/earnings/stockholder';
  static String get platformEarnings => '$baseUrl/earnings/platform';

  // Ratings
  static String get submitRating => '$baseUrl/ratings/submit';
  static String get myRatings => '$baseUrl/ratings/my';
  static String get unratedOrders => '$baseUrl/ratings/unrated';
=======

  // Demands
  static String get createDemand => '$baseUrl/demands/create';
  static String get myDemands => '$baseUrl/demands/my';
  static String demandById(int id) => '$baseUrl/demands/$id';

  // Shop dashboard
  static String get shopStats => '$baseUrl/shop/stats';
>>>>>>> Stashed changes
}
