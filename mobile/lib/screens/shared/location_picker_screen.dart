// Reusable map-based location picker.
// Drag the map to move the pin (pin stays at center).
// Address auto-fills via OSM Nominatim. User can edit text manually.
// Returns LocationResult on Save.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../config/app_colors.dart';
import '../../services/location_service.dart';

class LocationPickerScreen extends StatefulWidget {
  final double? initialLat;
  final double? initialLng;
  final String title;

  const LocationPickerScreen({
    super.key,
    this.initialLat,
    this.initialLng,
    this.title = 'Pick Location',
  });

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  final MapController _mapController = MapController();
  final TextEditingController _addressController = TextEditingController();

  // Default: Dhaka center
  LatLng _center = const LatLng(23.8103, 90.4125);
  String _area = '';
  String _district = '';
  bool _loadingAddress = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    if (widget.initialLat != null && widget.initialLng != null) {
      _center = LatLng(widget.initialLat!, widget.initialLng!);
    }
    // Auto-fetch address for initial position
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateAddressFromMap();
    });
  }

  @override
  void dispose() {
    _addressController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _useMyGps() async {
    setState(() => _loadingAddress = true);
    try {
      final c = await LocationService.getCurrentCoords();
      _center = LatLng(c.lat, c.lng);
      _mapController.move(_center, 16);
      await _fetchAddress();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('GPS error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loadingAddress = false);
    }
  }

  void _updateAddressFromMap() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), _fetchAddress);
  }

  Future<void> _fetchAddress() async {
    setState(() => _loadingAddress = true);
    final loc = await LocationService.reverseGeocode(
        _center.latitude, _center.longitude);
    if (!mounted) return;
    setState(() {
      _addressController.text = loc.address;
      _area = loc.area;
      _district = loc.district;
      _loadingAddress = false;
    });
  }

  void _save() {
    if (_addressController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Address cannot be empty')),
      );
      return;
    }
    Navigator.pop(
      context,
      LocationResult(
        lat: _center.latitude,
        lng: _center.longitude,
        address: _addressController.text.trim(),
        area: _area,
        district: _district,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: Text(widget.title),
        elevation: 0,
      ),
      body: Column(
        children: [
          // ── Map with center pin ───────────────────────
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _center,
                    initialZoom: 15,
                    onPositionChanged: (pos, hasGesture) {
                      if (hasGesture && pos.center != null) {
                        _center = pos.center!;
                        _updateAddressFromMap();
                      }
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.supplylink.app',
                    ),
                  ],
                ),
                // Center pin (always at screen middle)
                IgnorePointer(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.location_pin,
                            color: Colors.red, size: 50),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
                // GPS button (top right)
                Positioned(
                  top: 12,
                  right: 12,
                  child: FloatingActionButton.small(
                    backgroundColor: Colors.white,
                    onPressed: _useMyGps,
                    child: const Icon(Icons.my_location,
                        color: AppColors.primary),
                  ),
                ),
                // Hint banner
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Drag map to move pin',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Address panel ─────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              boxShadow: [
                BoxShadow(
                    color: Colors.black12,
                    blurRadius: 12,
                    offset: Offset(0, -3)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.place,
                        color: AppColors.primary, size: 20),
                    const SizedBox(width: 8),
                    const Text('Selected Address',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDark)),
                    const Spacer(),
                    if (_loadingAddress)
                      const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2)),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _addressController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'Address (you can edit)',
                    filled: true,
                    fillColor: const Color(0xFFF5F7FB),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (_area.isNotEmpty)
                      _chip(Icons.location_city, _area),
                    if (_district.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      _chip(Icons.map, _district),
                    ],
                    const Spacer(),
                    Text(
                      '${_center.latitude.toStringAsFixed(4)}, ${_center.longitude.toStringAsFixed(4)}',
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textGrey),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.check),
                    label: const Text('Confirm Location',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.primary),
          const SizedBox(width: 4),
          Text(text,
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary)),
        ],
      ),
    );
  }
}
