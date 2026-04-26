// My Demands — list of shop owner's posted demands with filter chips.

import 'package:flutter/material.dart';
import '../../config/app_colors.dart';
import '../../services/demand_service.dart';
import 'post_demand_screen.dart';
import 'demand_detail_screen.dart';

class MyDemandsScreen extends StatefulWidget {
  const MyDemandsScreen({super.key});

  @override
  State<MyDemandsScreen> createState() => _MyDemandsScreenState();
}

class _MyDemandsScreenState extends State<MyDemandsScreen> {
  static const _statusMeta = {
    'open': (Color(0xFF1565C0), Icons.search_rounded, 'Searching...'),
    'matched': (Color(0xFFE65100), Icons.handshake_rounded, 'View Matches'),
    'fulfilled': (Color(0xFF2E7D32), Icons.check_circle_rounded, 'Done'),
  };

  List<Map<String, dynamic>> _demands = [];
  bool _loading = true;
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = await DemandService.getMyDemands();
    if (!mounted) return;
    setState(() {
      _demands = list;
      _loading = false;
    });
  }

  List<Map<String, dynamic>> get _filtered =>
      _filter == 'all' ? _demands : _demands.where((d) => d['status'] == _filter).toList();

  int _count(String status) =>
      status == 'all' ? _demands.length : _demands.where((d) => d['status'] == status).length;

  Future<void> _openPost() async {
    final posted = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PostDemandScreen()),
    );
    if (posted == true) _load();
  }

  String _timeAgo(String? iso) {
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
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('My Demands'),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _load,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(54),
          child: Container(
            color: AppColors.primary,
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
            child: Row(
              children: [
                _chip('all', 'All', _count('all')),
                _chip('open', 'Open', _count('open')),
                _chip('matched', 'Matched', _count('matched')),
                _chip('fulfilled', 'Done', _count('fulfilled')),
              ],
            ),
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _filtered.isEmpty
                  ? ListView(children: [
                      SizedBox(
                          height: MediaQuery.of(context).size.height * 0.7,
                          child: _emptyState()),
                    ])
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 90),
                      itemCount: _filtered.length,
                      itemBuilder: (_, i) => _demandCard(_filtered[i]),
                    ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openPost,
        backgroundColor: const Color(0xFFE65100),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Demand',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }

  Widget _chip(String key, String label, int count) {
    final selected = _filter == key;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => setState(() => _filter = key),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.white.withOpacity(0.18),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '$label ($count)',
            style: TextStyle(
                color: selected ? AppColors.primary : Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 13),
          ),
        ),
      ),
    );
  }

  Widget _demandCard(Map<String, dynamic> d) {
    final status = (d['status'] ?? 'open') as String;
    final meta = _statusMeta[status] ??
        (AppColors.textGrey, Icons.help_outline, status);

    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => DemandDetailScreen(demandId: d['demand_id'] as int)),
        );
        if (result == 'cancelled') _load();
      },
      child: Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: meta.$1.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.shopping_basket_rounded,
                    color: meta.$1, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${d['product_name']} - ${d['variant_name']}',
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${d['quantity']} ${d['unit']} • ${d['category_name']}',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textGrey),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: meta.$1.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: TextStyle(
                      color: meta.$1,
                      fontSize: 10,
                      fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.access_time, size: 13, color: AppColors.textGrey),
              const SizedBox(width: 4),
              Text(_timeAgo(d['created_at'] as String?),
                  style: const TextStyle(fontSize: 12, color: AppColors.textGrey)),
              if ((d['location_area'] ?? '').toString().isNotEmpty) ...[
                const SizedBox(width: 12),
                const Icon(Icons.location_on_outlined,
                    size: 13, color: AppColors.textGrey),
                const SizedBox(width: 2),
                Expanded(
                  child: Text(d['location_area'] as String,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textGrey)),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 40,
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: Icon(meta.$2, size: 18),
              label: Text(meta.$3,
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: meta.$1,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
    ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.inbox_rounded,
                size: 50, color: AppColors.primary),
          ),
          const SizedBox(height: 16),
          const Text('No demands yet',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark)),
          const SizedBox(height: 6),
          const Text('Tap "New Demand" to find suppliers',
              style: TextStyle(color: AppColors.textGrey)),
        ],
      ),
    );
  }
}
