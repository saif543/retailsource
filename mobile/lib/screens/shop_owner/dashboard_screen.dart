// lib/screens/shop_owner/shop_owner_dashboard.dart
//
// The HOME screen for Shop Owners after they log in.
// Shows: active demand count, matched supplier count,
//        Post New Demand button, Recent Matches, My Active Demands.
// Calls GET /api/supplies?product=...&location=... for matches.

import 'package:flutter/material.dart';
import '../app_colors.dart';

class ShopOwnerDashboard extends StatefulWidget {
  // Pass the shop name from the login response
  final String shopName;
  final String userName;

  const ShopOwnerDashboard({
    super.key,
    this.shopName = 'My Store',
    this.userName = 'Shop Owner',
  });

  @override
  State<ShopOwnerDashboard> createState() => _ShopOwnerDashboardState();
}

class _ShopOwnerDashboardState extends State<ShopOwnerDashboard> {
  int _currentTab = 0; // bottom nav index

  // Dummy data — replace with real API responses
  final List<Map<String, dynamic>> _recentMatches = [
    {
      'supplier': 'Rahman Traders',
      'product': 'Basmati Rice - Premium',
      'price': '৳850/kg',
      'distance': '2.3 km away',
      'rating': 4.8,
      'isNew': true,
    },
  ];

  final List<Map<String, dynamic>> _activeDemands = [
    {
      'product': 'Teer Mustard Oil - 1L',
      'quantity': '24 bottles',
      'location': 'Mirpur, Dhaka',
      'status': 'Matched',
      'matchCount': 5,
      'postedAgo': '5 hours ago',
    },
    {
      'product': 'Horlicks - 500g',
      'quantity': '12 jars',
      'location': 'Mirpur, Dhaka',
      'status': 'Open',
      'matchCount': 2,
      'postedAgo': '1 day ago',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // ── Blue header ────────────────────────────────────────────────
          _buildHeader(),

          // ── Scrollable body ────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Post New Demand button
                  _buildPostDemandButton(),
                  const SizedBox(height: 20),

                  // Recent Matches section
                  _buildSectionHeader('Recent Matches', 'View All', () {}),
                  const SizedBox(height: 12),
                  ..._recentMatches.map(_buildMatchCard),

                  const SizedBox(height: 20),

                  // My Active Demands section
                  _buildSectionHeader('My Active Demands', 'View All', () {}),
                  const SizedBox(height: 12),
                  ..._activeDemands.map(_buildDemandCard),

                  const SizedBox(height: 80), // space for bottom nav
                ],
              ),
            ),
          ),
        ],
      ),

      // ── Bottom navigation ────────────────────────────────────────────
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ── Header with stats ───────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 12,
        bottom: 20,
        left: 16,
        right: 16,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primaryDark, AppColors.primary],
        ),
      ),
      child: Column(
        children: [
          // Top row: avatar + name + notification bell
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: Colors.white24,
                child: const Icon(Icons.storefront,
                    color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Welcome back,',
                      style:
                          TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    Text(
                      widget.shopName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              Stack(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.white24,
                    child: const Icon(Icons.notifications_outlined,
                        color: Colors.white, size: 22),
                  ),
                  Positioned(
                    top: 2,
                    right: 2,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: const BoxDecoration(
                          color: Colors.red, shape: BoxShape.circle),
                      child: const Center(
                        child: Text('3',
                            style: TextStyle(
                                color: Colors.white, fontSize: 9)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Stat cards row
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: Icons.assignment_outlined,
                  label: 'Active Demands',
                  count: '5',
                  badge: 'Active',
                  badgeColor: AppColors.supplierGreen,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.handshake_outlined,
                  label: 'Matched Suppliers',
                  count: '8',
                  badge: 'New',
                  badgeColor: AppColors.badgeOrange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String count,
    required String badge,
    required Color badgeColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SizedBox(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: badgeColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(badge,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
                Text(
                  count,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(label,
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Post New Demand button ─────────────────────────────────────────────────
  Widget _buildPostDemandButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: _showPostDemandSheet,
        icon: const Icon(Icons.add_circle_outline, size: 22),
        label: const Text(
          'Post New Demand',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.supplierGreen,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
      ),
    );
  }

  void _showPostDemandSheet() {
    // Bottom sheet form for creating a demand
    final productCtrl = TextEditingController();
    final quantityCtrl = TextEditingController();
    final locationCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Post New Demand',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark),
            ),
            const SizedBox(height: 16),
            _sheetField(productCtrl, 'Product Name (e.g. Basmati Rice)'),
            const SizedBox(height: 12),
            _sheetField(quantityCtrl, 'Quantity (e.g. 50)',
                type: TextInputType.number),
            const SizedBox(height: 12),
            _sheetField(locationCtrl, 'Location (e.g. Mirpur, Dhaka)'),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () async {
                  // TODO: call POST /api/demands with JWT token
                  // await DemandService.create(
                  //   productCtrl.text, quantityCtrl.text, locationCtrl.text
                  // );
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Demand posted!'),
                        backgroundColor: AppColors.supplierGreen),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Post Demand',
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sheetField(TextEditingController c, String hint,
      {TextInputType type = TextInputType.text}) {
    return TextField(
      controller: c,
      keyboardType: type,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
            const TextStyle(color: AppColors.textGrey, fontSize: 14),
        filled: true,
        fillColor: AppColors.background,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.inputBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.inputBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      ),
    );
  }

  // ── Section header row ─────────────────────────────────────────────────────
  Widget _buildSectionHeader(
      String title, String action, VoidCallback onTap) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title,
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark)),
        GestureDetector(
          onTap: onTap,
          child: Text(action,
              style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }

  // ── Match card ─────────────────────────────────────────────────────────────
  Widget _buildMatchCard(Map<String, dynamic> match) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.warehouse_outlined,
                    color: AppColors.badgeOrange),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(match['supplier'],
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: AppColors.textDark)),
                    const SizedBox(height: 2),
                    Text(match['product'],
                        style: const TextStyle(
                            color: AppColors.textGrey, fontSize: 13)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(match['price'],
                            style: const TextStyle(
                                color: AppColors.supplierGreen,
                                fontWeight: FontWeight.w700,
                                fontSize: 15)),
                        const Text(' · ',
                            style: TextStyle(color: AppColors.textGrey)),
                        Text(match['distance'],
                            style: const TextStyle(
                                color: AppColors.textGrey, fontSize: 13)),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.star,
                          color: Colors.amber, size: 14),
                      const SizedBox(width: 2),
                      Text('${match['rating']}',
                          style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (match['isNew'])
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3E0),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('New',
                          style: TextStyle(
                              color: AppColors.badgeOrange,
                              fontSize: 11,
                              fontWeight: FontWeight.w600)),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 42,
            child: ElevatedButton.icon(
              onPressed: () {}, // TODO: navigate to order screen
              icon: const Icon(Icons.shopping_cart_outlined, size: 18),
              label: const Text('Order Now',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.supplierGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Demand card ────────────────────────────────────────────────────────────
  Widget _buildDemandCard(Map<String, dynamic> demand) {
    final isMatched = demand['status'] == 'Matched';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isMatched
                      ? const Color(0xFFFFECE0)
                      : const Color(0xFFE3F2FD),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  demand['status'],
                  style: TextStyle(
                    color: isMatched
                        ? AppColors.badgeOrange
                        : AppColors.statusBlue,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text('Posted ${demand['postedAgo']}',
                  style: const TextStyle(
                      color: AppColors.textGrey, fontSize: 12)),
              const Spacer(),
              const Icon(Icons.more_vert,
                  color: AppColors.textGrey, size: 20),
            ],
          ),
          const SizedBox(height: 10),
          Text(demand['product'],
              style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: AppColors.textDark)),
          const SizedBox(height: 4),
          Text('Quantity: ${demand['quantity']}',
              style: const TextStyle(
                  color: AppColors.textGrey, fontSize: 13)),
          Text('Location: ${demand['location']}',
              style: const TextStyle(
                  color: AppColors.textGrey, fontSize: 13)),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.handshake_outlined,
                  color: AppColors.badgeOrange, size: 18),
              const SizedBox(width: 6),
              Text(
                '${demand['matchCount']} Matches Found',
                style: const TextStyle(
                    color: AppColors.badgeOrange,
                    fontWeight: FontWeight.w600,
                    fontSize: 13),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {}, // TODO: navigate to matches list
                child: const Text(
                  'View Matches',
                  style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Bottom navigation bar ──────────────────────────────────────────────────
  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: _currentTab,
      onTap: (i) => setState(() => _currentTab = i),
      type: BottomNavigationBarType.fixed,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.textGrey,
      selectedFontSize: 11,
      unselectedFontSize: 11,
      items: [
        const BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home'),
        const BottomNavigationBarItem(
            icon: Icon(Icons.assignment_outlined),
            activeIcon: Icon(Icons.assignment),
            label: 'Demands'),
        BottomNavigationBarItem(
          icon: Stack(
            children: [
              const Icon(Icons.notifications_outlined),
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                      color: Colors.red, shape: BoxShape.circle),
                ),
              ),
            ],
          ),
          activeIcon: const Icon(Icons.notifications),
          label: 'Alerts',
        ),
        const BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile'),
      ],
    );
  }
}
