import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class CustomerMapScreen extends StatelessWidget {
  final List<Map<String, dynamic>> customers;

  const CustomerMapScreen({super.key, required this.customers});

  @override
  Widget build(BuildContext context) {
    // Tạo danh sách markers từ dữ liệu khách hàng
    List<Marker> markers = customers.map((customer) {
      return Marker(
        point: LatLng(
          (customer['latitude'] as num).toDouble(),
          (customer['longitude'] as num).toDouble(),
        ),
        width: 80,
        height: 80,
        child: GestureDetector(
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Khách hàng: ${customer['fullName']}\nSĐT: ${customer['phoneNumber']}')),
            );
          },
          child: const Icon(
            Icons.location_on,
            color: Colors.red,
            size: 40,
          ),
        ),
      );
    }).toList();

    // Tính toán tâm bản đồ (trung bình cộng các tọa độ)
    LatLng center = LatLng(0, 0);
    if (customers.isNotEmpty) {
      double latSum = 0;
      double lngSum = 0;
      for (var c in customers) {
        latSum += (c['latitude'] as num).toDouble();
        lngSum += (c['longitude'] as num).toDouble();
      }
      center = LatLng(latSum / customers.length, lngSum / customers.length);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bản đồ khách hàng'),
      ),
      body: FlutterMap(
        options: MapOptions(
          initialCenter: center,
          initialZoom: 13.0,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.de/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.g_shipping',
          ),
          MarkerLayer(
            markers: markers,
          ),
        ],
      ),
    );
  }
}
