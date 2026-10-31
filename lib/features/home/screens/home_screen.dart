import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../widgets/location_details_sheet.dart';
import '../../contacts/services/firestore_customer_service.dart';
import '../../contacts/models/customer_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  late final Geocoding? _geocoding = kIsWeb ? null : Geocoding();
  final FirestoreCustomerService _customerService = FirestoreCustomerService();
  final List<LatLng> _pinnedLocations = [];
  late final Stream<List<Map<String, dynamic>>> _customersStream;
  LatLng _currentPin = const LatLng(10.762622, 106.660172);
  bool _isPinned = false;

  @override
  void initState() {
    super.initState();
    _customersStream = _customerService.getCustomersStream();
  }

  @override
  void dispose() {
    _mapController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vui lòng bật dịch vụ định vị GPS')),
        );
      }
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Quyền truy cập vị trí bị từ chối')),
          );
        }
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Quyền vị trí bị từ chối vĩnh viễn')),
        );
      }
      return;
    }

    Position position = await Geolocator.getCurrentPosition();
    LatLng currentLocation = LatLng(position.latitude, position.longitude);

    setState(() {
      _currentPin = currentLocation;
      _isPinned = true;
      _pinnedLocations.add(currentLocation);
    });

    _mapController.move(currentLocation, 15.0);
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

  void _handleMarkerTap(LatLng point, {Customer? customer}) {
    // Nếu không có customer truyền vào, thử tìm xem có khách hàng nào tại vị trí này không
    if (customer == null) {
      // Tìm trong danh sách khách hàng hiện tại (từ StreamBuilder)
      // Tuy nhiên vì _handleMarkerTap nằm ngoài StreamBuilder, ta không có list khách hàng ở đây.
      // Cách tốt nhất là truyền customer từ marker tap.
    }

    print(
      'DEBUG: _handleMarkerTap called with customer: ${customer?.fullName}',
    );
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => LocationDetailsSheet(
        location: point,
        customer: customer,
        onDeletePin: () {
          setState(() {
            _pinnedLocations.remove(point);
            if (_pinnedLocations.isEmpty) {
              _isPinned = false;
            }
          });
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Đã xóa ghim vị trí')));
        },
      ),
    );
  }

  Future<void> _searchAddress(String address) async {
    if (address.trim().isEmpty) return;

    final searchQuery = "${address.trim()}, Việt Nam";

    try {
      LatLng? targetLatLng;
      if (kIsWeb) {
        final response = await http
            .get(Uri.https('photon.komoot.io', '/api/', {
              'q': searchQuery,
              'limit': '1',
              'lang': 'vi',
            }))
            .timeout(const Duration(seconds: 12));
        if (response.statusCode != 200) {
          throw Exception('Tìm địa chỉ trả về HTTP ${response.statusCode}');
        }

        final features = (jsonDecode(response.body) as Map)['features'] as List;
        if (features.isNotEmpty) {
          final coordinates =
              (features.first as Map)['geometry']['coordinates'] as List;
          targetLatLng = LatLng(
            (coordinates[1] as num).toDouble(),
            (coordinates[0] as num).toDouble(),
          );
        }
      } else {
        final locations = await _geocoding!.locationFromAddress(searchQuery);
        if (locations.isNotEmpty) {
          targetLatLng = LatLng(
            locations.first.latitude,
            locations.first.longitude,
          );
        }
      }
      if (!mounted) return;

      final result = targetLatLng;
      if (result != null) {
        setState(() {
          _currentPin = result;
          _isPinned = true;
          _pinnedLocations.add(result);
        });

        _mapController.move(result, 15.0);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã tìm thấy vị trí cho: $address')),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Không tìm thấy địa chỉ này tại Việt Nam. Vui lòng thử lại!',
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
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(initialCenter: _currentPin, initialZoom: 13.0),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.de/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.g_shipping',
              ),
              StreamBuilder<List<Map<String, dynamic>>>(
                stream: _customersStream,
                builder: (context, snapshot) {
                  List<Customer> customers = [];
                  if (snapshot.hasData) {
                    customers = snapshot.data!
                        .map((map) => Customer.fromMap(map))
                        .toList();
                  }

                  return MarkerLayer(
                    markers: [
                      ...customers.map((customer) {
                        final location = LatLng(
                          customer.latitude,
                          customer.longitude,
                        );
                        return Marker(
                          point: location,
                          width: 40,
                          height: 40,
                          child: GestureDetector(
                            onTap: () {
                              print(
                                'DEBUG: Marker tap for customer: ${customer.fullName}',
                              );
                              _handleMarkerTap(location, customer: customer);
                            },
                            child: const Icon(
                              Icons.person_pin_circle,
                              color: Colors.blue,
                              size: 40,
                            ),
                          ),
                        );
                      }),
                      ..._pinnedLocations.map((point) {
                        final matchingCustomer = customers.firstWhere(
                          (c) =>
                              (c.latitude - point.latitude).abs() < 0.0001 &&
                              (c.longitude - point.longitude).abs() < 0.0001,
                          orElse: () => Customer(
                            id: '',
                            fullName: '',
                            phoneNumber: '',
                            address: '',
                            latitude: 0,
                            longitude: 0,
                          ),
                        );

                        final hasCustomer = matchingCustomer.id.isNotEmpty;

                        return Marker(
                          point: point,
                          width: 40,
                          height: 40,
                          child: GestureDetector(
                            onTap: () => _handleMarkerTap(
                              point,
                              customer: hasCustomer ? matchingCustomer : null,
                            ),
                            child: Icon(
                              Icons.location_on,
                              color: hasCustomer ? Colors.blue : Colors.red,
                              size: 40,
                            ),
                          ),
                        );
                      }),
                    ],
                  );
                },
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
                  onPressed: _determinePosition,
                  mini: true,
                  elevation: 2,
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.my_location,
                    color: Color(0xFF2563EB),
                  ),
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
