import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../services/location_tools.dart';

class PlaceInfoSheet extends StatelessWidget {
  const PlaceInfoSheet({
    super.key,
    required this.point,
    this.name,
    this.address,
    this.phone,
    this.imageUrl,
    this.imageUrls = const [],
    this.onSave,
    this.onDelete,
  });

  final LatLng point;
  final String? name;
  final String? address;
  final String? phone;
  final String? imageUrl;
  final List<String> imageUrls;
  final VoidCallback? onSave;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final coordinates =
        '${point.latitude.toStringAsFixed(6)}, '
        '${point.longitude.toStringAsFixed(6)}';
    Future<void> run(Future<void> Function() action) async {
      try {
        await action();
      } catch (error) {
        if (context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(error.toString())));
        }
      }
    }

    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (imageUrls.isNotEmpty || (imageUrl?.isNotEmpty ?? false))
                SizedBox(
                  height: 150,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: (imageUrls.isNotEmpty ? imageUrls : [imageUrl!])
                        .map((url) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: GestureDetector(
                                onTap: () => showDialog<void>(
                                  context: context,
                                  builder: (_) => Dialog.fullscreen(
                                    backgroundColor: Colors.black,
                                    child: Stack(children: [
                                      Center(child: InteractiveViewer(child: Image.network(url, fit: BoxFit.contain))),
                                      Positioned(top: 32, right: 12, child: IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, color: Colors.white))),
                                    ]),
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(url, width: 180, height: 140, fit: BoxFit.cover),
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                ),
              Text(
                name ?? 'Vị trí đã chọn',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              if (address != null && address!.isNotEmpty) Text(address!),
              if (phone != null && phone!.isNotEmpty) Text('SĐT: $phone'),
              FutureBuilder<String?>(
                future: LocationTools.addressAt(point),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: LinearProgressIndicator(),
                    );
                  }
                  if (snapshot.hasData &&
                      snapshot.data!.isNotEmpty &&
                      snapshot.data != address) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text('Địa chỉ gần đây: ${snapshot.data}'),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
              const SizedBox(height: 8),
              Text('Tọa độ: $coordinates'),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => run(() => LocationTools.openPlace(point)),
                    icon: const Icon(Icons.place_outlined),
                    label: const Text('Xem trên Google Maps'),
                  ),
                  FilledButton.icon(
                    onPressed: () => run(() => LocationTools.navigateTo(point)),
                    icon: const Icon(Icons.directions),
                    label: const Text('Chỉ đường'),
                  ),
                  if (onSave != null)
                    OutlinedButton.icon(
                      onPressed: onSave,
                      icon: const Icon(Icons.person_add_alt_1),
                      label: const Text('Lưu khách hàng'),
                    ),
                  if (onDelete != null)
                    TextButton.icon(
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Xóa ghim'),
                    ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'Tên địa điểm phụ thuộc dữ liệu bản đồ; có thể xem thêm trên Google Maps.',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
