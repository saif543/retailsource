// Shop Owner home — friendly, simple layout for village shopkeepers.
// Big buttons, plain language, hardcoded data for now.

import 'package:flutter/material.dart';
import '../../config/app_colors.dart';
import '../../services/auth_service.dart';
<<<<<<< HEAD
import '../../services/demand_service.dart';
import 'post_demand_screen.dart';
import 'my_demands_screen.dart';
=======
import '../../services/location_service.dart';
import '../../services/profile_service.dart';
import '../shared/location_picker_screen.dart';
>>>>>>> 15b0678d03781c17983fb616c22699d368855ae5

class ShopOwnerDashboard extends StatefulWidget {
  final String shopName;
  final String userName;

  const ShopOwnerDashboard({
    super.key,
    this.shopName = 'My Shop',
    this.userName = 'Shop Owner',
  });

  @override
  State<ShopOwnerDashboard> createState() => _ShopOwnerDashboardState();
}

class _ShopOwnerDashboardState extends State<ShopOwnerDashboard> {
  int _currentTab = 0;
<<<<<<< HEAD
  Map<String, int> _stats = {
    'open_demands': 0,
    'matched_demands': 0,
    'active_orders': 0,
  };

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final s = await DemandService.getShopStats();
    if (!mounted) return;
    setState(() => _stats = s);
  }
=======
>>>>>>> 15b0678d03781c17983fb616c22699d368855ae5

  final List<Map<String, dynamic>> _recentOrders = [
    {
      'product': 'Basmati Rice',
      'qty': '50 kg',
      'supplier': 'Rahman Traders',
      'price': '৳42,500',
      'status': 'On the way',
      'statusColor': Color(0xFFE65100),
      'icon': Icons.local_shipping_rounded,
    },
    {
      'product': 'Mustard Oil',
      'qty': '24 bottles',
      'supplier': 'Karim Stores',
      'price': '৳4,800',
      'status': 'Delivered',
      'statusColor': Color(0xFF2E7D32),
      'icon': Icons.check_circle_rounded,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPostDemandCard(),
                    const SizedBox(height: 20),
                    _sectionTitle('What you can do'),
                    const SizedBox(height: 12),
                    _buildQuickActions(),
                    const SizedBox(height: 24),
                    _sectionTitle('Your Orders'),
                    const SizedBox(height: 12),
                    ..._recentOrders.map(_buildOrderCard),
                    const SizedBox(height: 12),
                    _buildTipCard(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ── Header ─────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primaryDark, AppColors.primary],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.storefront_rounded,
                    color: Colors.white, size: 26),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Assalamu Alaikum 👋',
                        style: TextStyle(
                            color: Colors.white70, fontSize: 13)),
                    const SizedBox(height: 2),
                    Text(
                      widget.shopName,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.w800),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              _circleIcon(Icons.notifications_outlined, badge: '3'),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _confirmLogout,
                child: _circleIcon(Icons.logout_rounded),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
<<<<<<< HEAD
                child: _statTile('${_stats['open_demands']}', 'Open\nDemands',
=======
                child: _statTile('5', 'Open\nDemands',
>>>>>>> 15b0678d03781c17983fb616c22699d368855ae5
                    Icons.assignment_outlined),
              ),
              const SizedBox(width: 10),
              Expanded(
<<<<<<< HEAD
                child: _statTile('${_stats['matched_demands']}', 'Matched\nDemands',
=======
                child: _statTile('8', 'Suppliers\nFound',
>>>>>>> 15b0678d03781c17983fb616c22699d368855ae5
                    Icons.handshake_outlined),
              ),
              const SizedBox(width: 10),
              Expanded(
<<<<<<< HEAD
                child: _statTile('${_stats['active_orders']}', 'Orders\nNow',
=======
                child: _statTile('2', 'Orders\nNow',
>>>>>>> 15b0678d03781c17983fb616c22699d368855ae5
                    Icons.shopping_cart_outlined),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _circleIcon(IconData icon, {String? badge}) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        if (badge != null)
          Positioned(
            top: -2,
            right: -2,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Color(0xFFE65100),
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              child: Text(badge,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700)),
            ),
          ),
      ],
    );
  }

  Widget _statTile(String count, String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(height: 6),
          Text(count,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  height: 1.2)),
        ],
      ),
    );
  }

  // ── Big "Post Demand" card ─────────────────────────────
<<<<<<< HEAD
  Future<void> _openPostDemand() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PostDemandScreen()),
    );
    _loadStats();
  }

  Future<void> _openMyDemands() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MyDemandsScreen()),
    );
    _loadStats();
=======
  Future<void> _testGps() async {
    final result = await Navigator.push<LocationResult>(
      context,
      MaterialPageRoute(
        builder: (_) => const LocationPickerScreen(title: 'Pick Your Shop Location'),
      ),
    );
    if (result == null || !mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final res = await ProfileService.saveLocation(result);
    if (!mounted) return;
    Navigator.pop(context); // close loader

    final ok = res['statusCode'] == 200;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: ok ? Colors.green : Colors.red,
        content: Text(ok
            ? '✓ Location saved to your profile'
            : 'Failed: ${res['error'] ?? 'unknown'}'),
      ),
    );
>>>>>>> 15b0678d03781c17983fb616c22699d368855ae5
  }

  Widget _buildPostDemandCard() {
    return GestureDetector(
<<<<<<< HEAD
      onTap: _openPostDemand,
=======
      onTap: _testGps,
>>>>>>> 15b0678d03781c17983fb616c22699d368855ae5
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFB74D), Color(0xFFE65100)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
                color: const Color(0xFFE65100).withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 6))
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.25),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.add_shopping_cart_rounded,
                  color: Colors.white, size: 30),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Need stock?',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800)),
                  SizedBox(height: 2),
                  Text('Post what you need — we\'ll find suppliers near you',
                      style: TextStyle(color: Colors.white, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_rounded, color: Colors.white),
          ],
        ),
      ),
    );
  }

  // ── Quick action grid ─────────────────────────────────
  Widget _buildQuickActions() {
<<<<<<< HEAD
    final actions = <(String, IconData, Color, VoidCallback)>[
      ('Post\nDemand', Icons.add_shopping_cart_rounded, AppColors.primary, _openPostDemand),
      ('My\nDemands', Icons.list_alt_rounded, const Color(0xFF7B1FA2), _openMyDemands),
      ('My\nOrders', Icons.local_shipping_rounded, const Color(0xFF2E7D32), () {}),
      ('Rate &\nReview', Icons.star_rounded, const Color(0xFFE65100), () {}),
=======
    final actions = [
      ('Browse\nSuppliers', Icons.store_rounded, AppColors.primary),
      ('My\nDemands', Icons.list_alt_rounded, const Color(0xFF7B1FA2)),
      ('My\nOrders', Icons.local_shipping_rounded, const Color(0xFF2E7D32)),
      ('Rate &\nReview', Icons.star_rounded, const Color(0xFFE65100)),
>>>>>>> 15b0678d03781c17983fb616c22699d368855ae5
    ];
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 0.85,
      children: actions
<<<<<<< HEAD
          .map((a) => _quickAction(a.$1, a.$2, a.$3, a.$4))
=======
          .map((a) => _quickAction(a.$1, a.$2, a.$3))
>>>>>>> 15b0678d03781c17983fb616c22699d368855ae5
          .toList(),
    );
  }

<<<<<<< HEAD
  Widget _quickAction(String label, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
=======
  Widget _quickAction(String label, IconData icon, Color color) {
    return Container(
>>>>>>> 15b0678d03781c17983fb616c22699d368855ae5
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 8),
          Text(label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                  height: 1.2)),
        ],
      ),
<<<<<<< HEAD
    ),
=======
>>>>>>> 15b0678d03781c17983fb616c22699d368855ae5
    );
  }

  Widget _sectionTitle(String text) {
    return Text(text,
        style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppColors.textDark));
  }

  // ── Order card ─────────────────────────────────────────
  Widget _buildOrderCard(Map<String, dynamic> o) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: (o['statusColor'] as Color).withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(o['icon'] as IconData,
                color: o['statusColor'] as Color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(o['product'] as String,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark)),
                const SizedBox(height: 2),
                Text('${o['qty']} • ${o['supplier']}',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textGrey)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: (o['statusColor'] as Color).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(o['status'] as String,
                      style: TextStyle(
                          color: o['statusColor'] as Color,
                          fontSize: 11,
                          fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
          Text(o['price'] as String,
              style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  color: AppColors.primary)),
        ],
      ),
    );
  }

  // ── Tip box ───────────────────────────────────────────
  Widget _buildTipCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFE3F2FD),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: const [
          Icon(Icons.lightbulb_rounded,
              color: AppColors.primary, size: 22),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Tip: Post your demand once — multiple suppliers will offer prices.',
              style: TextStyle(fontSize: 12, color: AppColors.textDark),
            ),
          ),
        ],
      ),
    );
  }

  // ── Bottom nav ────────────────────────────────────────
  Widget _buildBottomNav() {
    final items = [
      (Icons.home_rounded, 'Home'),
      (Icons.search_rounded, 'Find'),
      (Icons.receipt_long_rounded, 'Orders'),
      (Icons.person_rounded, 'Profile'),
    ];
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, -2)),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(items.length, (i) {
            final selected = _currentTab == i;
            return GestureDetector(
              onTap: () => setState(() => _currentTab = i),
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(items[i].$1,
                        color: selected
                            ? AppColors.primary
                            : AppColors.textGrey,
                        size: 24),
                    const SizedBox(height: 2),
                    Text(items[i].$2,
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: selected
                                ? AppColors.primary
                                : AppColors.textGrey)),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Future<void> _confirmLogout() async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('You will need to sign in again.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Log out',
                  style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (yes == true) {
      await AuthService.logout();
      if (mounted) Navigator.pushReplacementNamed(context, '/welcome');
    }
  }
}
