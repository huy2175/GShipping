import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

import '../widgets/location_details_sheet.dart';
import '../../contacts/services/firestore_customer_service.dart';
import '../../../shared/services/location_tools.dart';
import '../../../shared/widgets/place_info_sheet.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  final _customerStream = FirestoreCustomerService().getCustomersStream();
  final List<LatLng> _pinnedLocations = [];
  LatLng _currentPin = const LatLng(10.762622, 106.660172);
  LatLng? _deviceLocation;
  bool _isLocating = false;
  bool _isPinned = false;

  @override
  void dispose() {
    _mapController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _determinePosition() async {
    if (_isLocating) return;
    setState(() => _isLocating = true);

    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw Exception('Hãy bật dịch vụ định vị trên thiết bị rồi thử lại.');
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception(
          'Quyền vị trí đang bị từ chối. Hãy cho phép trình duyệt/ứng dụng truy cập vị trí.',
        );
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation,
        timeLimit: const Duration(seconds: 20),
      );
      final currentLocation = LatLng(position.latitude, position.longitude);

      if (!mounted) return;
      final currentZoom = _mapController.camera.zoom;
      setState(() => _deviceLocation = currentLocation);
      _mapController.move(currentLocation, currentZoom);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Đã lấy vị trí. Sai số thiết bị báo: khoảng ${position.accuracy.round()} m.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không lấy được vị trí hiện tại: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  void _pinTrackerPosition() {
    final center = _mapController.camera.center;
    setState(() {
      _currentPin = center;
      _isPinned = true;
      _pinnedLocations.add(center);
    });
    _handleMarkerTap(center);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã ghim vị trí tại điểm ngắm!'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _handleMarkerTap(LatLng point) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => PlaceInfoSheet(
        point: point,
        onSave: () {
          Navigator.pop(sheetContext);
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => LocationDetailsSheet(
              location: point,
              onDeletePin: () => setState(() => _pinnedLocations.remove(point)),
              onSaved: () => setState(() {
                _pinnedLocations.remove(point);
                _isPinned = _pinnedLocations.isNotEmpty;
              }),
            ),
          );
        },
        onDelete: _pinnedLocations.contains(point)
            ? () {
                setState(() {
                  _pinnedLocations.remove(point);
                  _isPinned = _pinnedLocations.isNotEmpty;
                });
                Navigator.pop(sheetContext);
              }
            : null,
      ),
    );
  }

  void _showCustomer(Map<String, dynamic> customer) {
    final point = LatLng(
      (customer['latitude'] as num).toDouble(),
      (customer['longitude'] as num).toDouble(),
    );
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => PlaceInfoSheet(
        point: point,
        name: customer['fullName'] as String?,
        address: customer['address'] as String?,
        phone: customer['phoneNumber'] as String?,
      ),
    );
  }

  Future<void> _searchAddress(String address) async {
    if (address.trim().isEmpty) return;

    try {
      final targetLatLng = await LocationTools.searchAddress(address);
      if (!mounted) return;

      if (targetLatLng == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không tìm thấy địa chỉ này.')),
        );
        return;
      }
      setState(() {
        _currentPin = targetLatLng;
        _isPinned = true;
        _pinnedLocations.add(targetLatLng);
      });

      _mapController.move(targetLatLng, 15.0);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã tìm thấy vị trí cho: $address')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Không tìm được địa chỉ. Kiểm tra kết nối mạng rồi thử lại.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. Lớp Bản đồ
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentPin,
              initialZoom: 13.0,
              onTap: (_, point) => _handleMarkerTap(point),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.de/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.g_shipping',
              ),
              if (_isPinned || _pinnedLocations.isNotEmpty)
                MarkerLayer(
                  markers: _pinnedLocations
                      .map(
                        (point) => Marker(
                          point: point,
                          width: 40,
                          height: 40,
                          child: GestureDetector(
                            onTap: () => _handleMarkerTap(point),
                            child: const Icon(
                              Icons.location_on,
                              color: Colors.red,
                              size: 40,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              StreamBuilder<List<Map<String, dynamic>>>(
                stream: _customerStream,
                builder: (context, snapshot) => MarkerLayer(
                  markers: [
                    for (final customer
                        in snapshot.data ?? <Map<String, dynamic>>[])
                      if (customer['latitude'] is num &&
                          customer['longitude'] is num)
                        Marker(
                          point: LatLng(
                            (customer['latitude'] as num).toDouble(),
                            (customer['longitude'] as num).toDouble(),
                          ),
                          width: 44,
                          height: 44,
                          child: GestureDetector(
                            onTap: () => _showCustomer(customer),
                            child: const Icon(
                              Icons.location_on,
                              color: Color(0xFF2563EB),
                              size: 40,
                            ),
                          ),
                        ),
                  ],
                ),
              ),
              if (_deviceLocation != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _deviceLocation!,
                      width: 36,
                      height: 36,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.blue.withValues(alpha: 0.2),
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: const [
                            BoxShadow(color: Colors.black26, blurRadius: 4),
                          ],
                        ),
                        child: const Center(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFF2563EB),
                            ),
                            child: SizedBox(width: 12, height: 12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
          // Thanh tìm kiếm địa chỉ (Đặt sau FlutterMap để nằm trên)
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 20,
            right: 20,
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(30),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Tìm kiếm địa chỉ...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                ),
                onSubmitted: (value) {
                  _searchAddress(value);
                },
              ),
            ),
          ),

          // 2. Lớp Tracker - Sử dụng const để tối ưu performance
          const Center(
            child: Padding(
              padding: EdgeInsets.only(bottom: 40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [TrackerDot(), SizedBox(height: 4), TrackerLabel()],
              ),
            ),
          ),

          // 3. Bộ nút điều khiển
          Positioned(
            bottom: 30,
            right: 20,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton(
                  heroTag: 'btn_location',
                  onPressed: _isLocating ? null : _determinePosition,
                  mini: true,
                  elevation: 2,
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _isLocating
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.my_location, color: Color(0xFF2563EB)),
                ),
                const SizedBox(height: 12),
                FloatingActionButton(
                  heroTag: 'btn_pin',
                  onPressed: _pinTrackerPosition,
                  mini: true,
                  elevation: 2,
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                    color: _isPinned
                        ? const Color(0xFFB91C1C)
                        : const Color(0xFF2563EB),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class TrackerDot extends StatelessWidget {
  const TrackerDot({super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.blue, width: 2),
        color: Colors.blue.withValues(alpha: 0.2),
      ),
    );
  }
}

class TrackerLabel extends StatelessWidget {
  const TrackerLabel({super.key});
  @override
  Widget build(BuildContext context) {
    return const Text(
      "Chọn vị trí",
      style: TextStyle(
        fontSize: 12,
        color: Colors.blue,
        fontWeight: FontWeight.bold,
        backgroundColor: Colors.white70,
      ),
    );
  }
}
