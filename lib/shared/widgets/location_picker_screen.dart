import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../features/contacts/services/firestore_customer_service.dart';
import '../services/location_tools.dart';

class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({super.key, this.initial});

  final LatLng? initial;

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  final MapController _controller = MapController();
  final TextEditingController _search = TextEditingController();
  late final _customerStream = FirestoreCustomerService().getCustomersStream();
  late LatLng _selected = widget.initial ?? LocationTools.fallback;
  late bool _hasSelection = widget.initial != null;

  @override
  void dispose() {
    _controller.dispose();
    _search.dispose();
    super.dispose();
  }

  Future<void> _find() async {
    try {
      final point = await LocationTools.searchAddress(_search.text);
      if (!mounted) return;
      if (point == null) {
        throw Exception(
          'Không tìm thấy địa chỉ. Hãy chạm trực tiếp lên bản đồ.',
        );
      }
      setState(() {
        _selected = point;
        _hasSelection = true;
      });
      _controller.move(point, 16);
    } catch (error) {
      if (mounted) {
        final message = error.toString().replaceFirst('Exception: ', '');
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
      }
    }
  }

  Future<void> _locate() async {
    try {
      final point = await LocationTools.currentPosition();
      if (!mounted) return;
      setState(() {
        _selected = point;
        _hasSelection = true;
      });
      _controller.move(point, 16);
    } catch (error) {
      if (mounted) {
        final message = error.toString().replaceFirst('Exception: ', '');
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Chọn vị trí')),
    body: Stack(
      children: [
        FlutterMap(
          mapController: _controller,
          options: MapOptions(
            initialCenter: _selected,
            initialZoom: 15,
            onTap: (_, point) => setState(() {
              _selected = point;
              _hasSelection = true;
            }),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.de/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.g_shipping',
            ),
            if (_hasSelection)
              MarkerLayer(
                markers: [
                  Marker(
                    point: _selected,
                    width: 48,
                    height: 48,
                    child: const Icon(
                      Icons.location_on,
                      color: Colors.red,
                      size: 42,
                    ),
                  ),
                ],
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
                          onTap: () {
                            final point = LatLng(
                              (customer['latitude'] as num).toDouble(),
                              (customer['longitude'] as num).toDouble(),
                            );
                            setState(() {
                              _selected = point;
                              _hasSelection = true;
                            });
                            _controller.move(point, 16);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Đã chọn ${customer['fullName'] ?? 'khách hàng'}',
                                ),
                              ),
                            );
                          },
                          child: const Icon(
                            Icons.location_on,
                            color: Color(0xFF2563EB),
                            size: 38,
                          ),
                        ),
                      ),
                ],
              ),
            ),
          ],
        ),
        Positioned(
          top: 12,
          left: 12,
          right: 12,
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _search,
                  onSubmitted: (_) => _find(),
                  decoration: const InputDecoration(
                    hintText: 'Tìm địa chỉ hoặc chạm lên bản đồ',
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
              ),
              IconButton.filledTonal(
                onPressed: _find,
                icon: const Icon(Icons.search),
              ),
            ],
          ),
        ),
        Positioned(
          right: 12,
          bottom: 80,
          child: FloatingActionButton.small(
            onPressed: _locate,
            child: const Icon(Icons.my_location),
          ),
        ),
      ],
    ),
    bottomNavigationBar: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: FilledButton(
          onPressed: _hasSelection
              ? () => Navigator.pop(context, _selected)
              : null,
          child: Text(
            _hasSelection
                ? 'Dùng tọa độ ${_selected.latitude.toStringAsFixed(5)}, '
                      '${_selected.longitude.toStringAsFixed(5)}'
                : 'Chạm lên bản đồ để chọn vị trí',
          ),
        ),
      ),
    ),
  );
}
