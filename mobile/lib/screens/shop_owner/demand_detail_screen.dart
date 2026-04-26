// Demand Detail — full info for one demand. Cancel if open, View Matches if matched.

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../config/app_colors.dart';
import '../../services/demand_service.dart';

class DemandDetailScreen extends StatefulWidget {
  final int demandId;
  const DemandDetailScreen({super.key, required this.demandId});

  @override
  State<DemandDetailScreen> createState() => _DemandDetailScreenState();
}

class _DemandDetailScreenState extends State<DemandDetailScreen> {
  Map<String, dynamic>? _d;
  bool _loading = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final d = await DemandService.getDemand(widget.demandId);
    if (!mounted) return;
    setState(() {
      _d = d;
      _loading = false;
    });
  }

  Future<void> _confirmCancel() async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cancel this demand?'),
        content: const Text('Suppliers will no longer see this request.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Keep')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Cancel Demand',
                  style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (yes != true) return;

    setState(() => _busy = true);
    final res = await DemandService.cancelDemand(widget.demandId);
    if (!mounted) return;
    setState(() => _busy = false);

    if (res.ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            backgroundColor: Colors.green,
            content: Text('Demand cancelled')),
      );
      Navigator.pop(context, 'cancelled');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res.error ?? 'Failed to cancel')),
      );
    }
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
        title: const Text('Demand Details'),
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _d == null
              ? const Center(child: Text('Demand not found'))
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    final d = _d!;
    final status = (d['status'] ?? 'open') as String;
    final lat = d['lat'] as double?;
    final lng = d['lng'] as double?;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.shopping_basket_rounded,
                          color: AppColors.primary, size: 26),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${d['product_name']} - ${d['variant_name']}',
                              style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textDark)),
                          const SizedBox(height: 2),
                          Text(d['category_name'] as String,
                              style: const TextStyle(
                                  fontSize: 12, color: AppColors.textGrey)),
                        ],
                      ),
                    ),
                    _statusPill(status),
                  ],
                ),
                const SizedBox(height: 14),
                _kv(Icons.scale_rounded, 'Quantity',
                    '${d['quantity']} ${d['unit']}'),
                _kv(Icons.access_time, 'Posted', _timeAgo(d['created_at'])),
                if ((d['additional_notes'] ?? '').toString().isNotEmpty)
                  _kv(Icons.note_alt_outlined, 'Notes',
                      d['additional_notes'] as String),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Location card
          if (lat != null && lng != null) ...[
            const Text('Delivery Location',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark)),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(
                height: 180,
                child: Stack(
                  children: [
                    FlutterMap(
                      options: MapOptions(
                        initialCenter: LatLng(lat, lng),
                        initialZoom: 15,
                        interactionOptions: const InteractionOptions(
                            flags: InteractiveFlag.none),
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.supplylink.app',
                        ),
                      ],
                    ),
                    const Center(
                      child: Icon(Icons.location_pin,
                          color: Colors.red, size: 40),
                    ),
                  ],
                ),
              ),
            ),
            if ((d['location_area'] ?? '').toString().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    const Icon(Icons.place, size: 14, color: AppColors.textGrey),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(d['location_area'] as String,
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textGrey)),
                    ),
                  ],
                ),
              ),
          ],

          const SizedBox(height: 22),

          // Actions
          if (status == 'open')
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _busy ? null : _confirmCancel,
                icon: _busy
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.cancel_outlined),
                label: Text(_busy ? 'Cancelling...' : 'Cancel Demand',
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC62828),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          if (status == 'matched')
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Matches screen coming soon')),
                  );
                },
                icon: const Icon(Icons.handshake_rounded),
                label: const Text('View Matches',
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE65100),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _statusPill(String status) {
    final colors = {
      'open': const Color(0xFF1565C0),
      'matched': const Color(0xFFE65100),
      'fulfilled': const Color(0xFF2E7D32),
    };
    final c = colors[status] ?? AppColors.textGrey;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: c.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(status.toUpperCase(),
          style: TextStyle(
              color: c, fontSize: 10, fontWeight: FontWeight.w800)),
    );
  }

  Widget _kv(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.textGrey),
          const SizedBox(width: 8),
          SizedBox(
            width: 80,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textGrey)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark)),
          ),
        ],
      ),
    );
  }
}
