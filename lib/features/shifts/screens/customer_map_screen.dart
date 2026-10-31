import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../shared/widgets/place_info_sheet.dart';

class CustomerMapScreen extends StatelessWidget {
  final List<Map<String, dynamic>> customers;

  const CustomerMapScreen({super.key, required this.customers});

  @override
  Widget build(BuildContext context) {
    final mappedCustomers = customers
        .where(
          (customer) =>
              customer['latitude'] is num && customer['longitude'] is num,
        )
        .toList();
    // Tạo danh sách markers từ dữ liệu khách hàng
    List<Marker> markers = mappedCustomers.map((customer) {
      return Marker(
        point: LatLng(
          (customer['latitude'] as num).toDouble(),
          (customer['longitude'] as num).toDouble(),
        ),
        width: 80,
        height: 80,
        child: GestureDetector(
          onTap: () => showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (_) => PlaceInfoSheet(
              point: LatLng(
                (customer['latitude'] as num).toDouble(),
                (customer['longitude'] as num).toDouble(),
              ),
              name: customer['fullName'] as String?,
              address: customer['address'] as String?,
              phone: customer['phoneNumber'] as String?,
            ),
          ),
          child: const Icon(Icons.location_on, color: Colors.red, size: 40),
        ),
      );
    }).toList();

    if (markers.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Bản đồ khách hàng')),
        body: const Center(
          child: Text('Khách hàng chưa có tọa độ để hiển thị.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Bản đồ khách hàng')),
      body: FlutterMap(
        options: MapOptions(
          initialCenter: markers.first.point,
          initialZoom: 13.0,
          initialCameraFit: markers.length > 1
              ? CameraFit.coordinates(
                  coordinates: markers.map((marker) => marker.point).toList(),
                  padding: const EdgeInsets.all(48),
                  maxZoom: 16,
                )
              : null,
          onTap: (_, point) => showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (_) => PlaceInfoSheet(point: point),
          ),
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.de/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.g_shipping',
          ),
          MarkerLayer(markers: markers),
        ],
      ),
    );
  }
}
