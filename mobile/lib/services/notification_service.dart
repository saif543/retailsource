import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'auth_service.dart';

class NotificationService {
  static Future<Map<String, String>> _headers() async {
    final token = await AuthService.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<({List<Map<String, dynamic>> items, int unread})>
      getNotifications() async {
    final res = await http.get(
      Uri.parse(ApiConfig.notifications),
      headers: await _headers(),
    );
    if (res.statusCode != 200) {
      return (items: <Map<String, dynamic>>[], unread: 0);
    }
    final data = jsonDecode(res.body);
    final items = List<Map<String, dynamic>>.from(data['notifications'] ?? []);
    return (items: items, unread: (data['unread_count'] ?? 0) as int);
  }

  static Future<void> markAllRead() async {
    final h = await _headers();
    await http.put(Uri.parse(ApiConfig.markNotificationsRead), headers: h);
  }

  static Future<void> markRead(List<int> ids) async {
    await http.put(
      Uri.parse(ApiConfig.markNotificationsRead),
      headers: await _headers(),
      body: jsonEncode({'notif_ids': ids}),
    );
  }
}
