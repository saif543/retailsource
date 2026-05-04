// Notifications — All / Matches / Orders / Ratings tabs.

import 'package:flutter/material.dart';
import '../../config/app_colors.dart';
import '../../services/notification_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  int _filter = 0;
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _items = [];

  // Maps API notification type → widget display properties
  static const _typeMeta = {
    'new_match':          ('match',  Icons.handshake_rounded,        AppColors.statusGreen, 'New Match'),
    'new_order':          ('order',  Icons.shopping_cart_rounded,    AppColors.accentOrange, 'New Order'),
    'order_accepted':     ('order',  Icons.check_circle_rounded,     AppColors.primary, 'Order Accepted'),
    'order_declined':     ('order',  Icons.cancel_rounded,           AppColors.errorRed, 'Order Declined'),
    'otp_sent':           ('order',  Icons.vpn_key_rounded,          AppColors.primary, 'OTP Sent'),
    'delivery_confirmed': ('order',  Icons.local_shipping_rounded,   AppColors.statusGreen, 'Delivered'),
    'rating_received':    ('rating', Icons.star_rounded,             Colors.amber, 'New Rating'),
    'stock_alert':        ('match',  Icons.warning_amber_rounded,    AppColors.errorRed, 'Stock Alert'),
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final result = await NotificationService.getNotifications();
      if (!mounted) return;
      setState(() {
        _items = result.items.map((n) {
          final meta = _typeMeta[n['type']] ??
              ('order', Icons.notifications_rounded, AppColors.primary, 'Notification');
          return {
            ...n,
            'kind': meta.$1,
            'icon': meta.$2,
            'color': meta.$3,
            'title': meta.$4,
            'msg': n['message'] ?? '',
            'meta': '',
            'time': _timeAgo(n['created_at'] as String?),
            'unread': n['is_read'] == false || n['is_read'] == 0,
          };
        }).toList();
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() { _loading = false; _error = e.toString(); });
    }
  }

  List<Map<String, dynamic>> get _filtered {
    if (_filter == 0) return _items;
    final keys = ['', 'match', 'order', 'rating'];
    return _items.where((n) => n['kind'] == keys[_filter]).toList();
  }

  Future<void> _markAllRead() async {
    await NotificationService.markAllRead();
    setState(() {
      for (final n in _items) {
        n['unread'] = false;
      }
    });
  }

  static String _timeAgo(String? iso) {
    if (iso == null) return '';
    final t = DateTime.tryParse(iso);
    if (t == null) return '';
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 60) return '${d.inMinutes}m ago';
    if (d.inHours < 24) return '${d.inHours}h ago';
    return '${d.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            decoration: const BoxDecoration(
              color: AppColors.primary,
              borderRadius:
                  BorderRadius.vertical(bottom: Radius.circular(16)),
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 36, height: 36,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.arrow_back_rounded,
                              color: Colors.white, size: 20),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Icon(Icons.notifications,
                          color: Colors.white, size: 22),
                      const SizedBox(width: 6),
                      const Text('Notifications',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w900)),
                      const Spacer(),
                      TextButton(
                        onPressed: _markAllRead,
                        child: const Text('Mark all read',
                            style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                  const Text(
                      'Stay updated with your orders and matches',
                      style:
                          TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
            child: Row(
              children: [
                _tab('All', 0),
                _tab('Matches', 1),
                _tab('Orders', 2),
                _tab('Ratings', 3),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _load,
                    child: _error != null
                        ? Center(
                            child: Column(mainAxisSize: MainAxisSize.min, children: [
                              const Icon(Icons.wifi_off_rounded, color: AppColors.textGrey, size: 40),
                              const SizedBox(height: 10),
                              Text('Could not load notifications',
                                  style: const TextStyle(color: AppColors.textGrey, fontWeight: FontWeight.w700)),
                              const SizedBox(height: 4),
                              Text(_error!, style: const TextStyle(color: AppColors.textGrey, fontSize: 11)),
                              const SizedBox(height: 16),
                              TextButton(onPressed: _load, child: const Text('Retry')),
                            ]))
                        : _filtered.isEmpty
                        ? const Center(
                            child: Text('No notifications',
                                style: TextStyle(color: AppColors.textGrey)))
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(14, 6, 14, 24),
                            itemCount: _filtered.length,
                            itemBuilder: (_, i) => _card(_filtered[i]),
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _tab(String label, int idx) {
    final selected = _filter == idx;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _filter = idx),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 3),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: selected ? Colors.white : AppColors.textDark,
                  fontWeight: FontWeight.w800,
                  fontSize: 12)),
        ),
      ),
    );
  }

  Widget _card(Map<String, dynamic> n) {
    final unread = n['unread'] == true;
    return GestureDetector(
      onTap: () => setState(() => n['unread'] = false),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: unread
              ? Border.all(color: (n['color'] as Color).withOpacity(0.4))
              : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: (n['color'] as Color).withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(n['icon'] as IconData,
                  color: n['color'] as Color, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(n['title'],
                            style: const TextStyle(
                                fontWeight: FontWeight.w900, fontSize: 14)),
                      ),
                      Text(n['time'],
                          style: const TextStyle(
                              color: AppColors.textGrey, fontSize: 11)),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(n['msg'],
                      style: const TextStyle(
                          color: AppColors.textDark, fontSize: 12)),
                  if (n['meta'] != null) ...[
                    const SizedBox(height: 4),
                    Text(n['meta'],
                        style: TextStyle(
                            color: n['color'] as Color,
                            fontSize: 12,
                            fontWeight: FontWeight.w800)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
