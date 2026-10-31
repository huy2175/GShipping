import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

import '../../contacts/services/firestore_customer_service.dart';
import '../../../shared/services/image_upload_service.dart';
import '../../../shared/services/location_tools.dart';
import '../../../shared/widgets/place_info_sheet.dart';
import '../models/shift_model.dart';
import '../services/firestore_shift_service.dart';
import '../widgets/customer_picker_dialog.dart';
import 'customer_map_screen.dart';

class ShiftDetailScreen extends StatefulWidget {
  const ShiftDetailScreen({super.key, required this.shift});
  final Shift shift;

  @override
  State<ShiftDetailScreen> createState() => _ShiftDetailScreenState();
}

class _ShiftDetailScreenState extends State<ShiftDetailScreen> {
  final _service = FirestoreShiftService();
  final _customerService = FirestoreCustomerService();
  late final _customerStream = _customerService.getCustomersStream();
  late List<String> _customerIds = [...widget.shift.customerIds];
  late bool _completed = widget.shift.isCompleted;
  late String? _proofUrl = widget.shift.proofImageUrl;
  XFile? _proofPhoto;
  bool _saving = false;

  Future<void> _chooseCustomers() async {
    final selected = await showCustomerPicker(context, _customerIds);
    if (selected == null || !mounted) return;
    try {
      await _service.updateCustomerIds(widget.shift.id, selected);
      if (mounted) setState(() => _customerIds = selected);
    } catch (error) {
      _showError('Không lưu được khách hàng: $error');
    }
  }

  Future<void> _takeProofPhoto() async {
    try {
      final photo = await ImagePicker().pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 1600,
      );
      if (photo != null && mounted) setState(() => _proofPhoto = photo);
    } catch (error) {
      _showError('Không mở được camera: $error');
    }
  }

  Future<void> _complete() async {
    if (_proofPhoto == null || _saving) return;
    setState(() => _saving = true);
    try {
      final url = await ImageUploadService.upload(_proofPhoto!);
      await _service.completeShift(widget.shift.id, url);
      if (!mounted) return;
      setState(() {
        _proofUrl = url;
        _proofPhoto = null;
        _completed = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã hoàn thành ca và lưu ảnh đơn hàng.')),
      );
    } catch (error) {
      _showError('Không hoàn thành được ca: $error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa ca làm?'),
        content: const Text('Ca sẽ bị xóa khỏi danh sách.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _service.deleteShift(widget.shift.id);
      if (mounted) Navigator.pop(context);
    } catch (error) {
      _showError('Không xóa được ca: $error');
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }

  void _showLocation() {
    final point = widget.shift.locationCoord;
    if (point == null) {
      _showError(
        'Ca cũ chưa lưu tọa độ. Hãy tạo ca mới với vị trí trên bản đồ.',
      );
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => PlaceInfoSheet(point: point, name: widget.shift.location),
    );
  }

  Future<void> _navigateToCustomer(Map<String, dynamic> customer) async {
    final latitude = customer['latitude'];
    final longitude = customer['longitude'];
    if (latitude is! num || longitude is! num) {
      _showError('Khách hàng này chưa lưu tọa độ.');
      return;
    }
    try {
      await LocationTools.navigateTo(
        LatLng(latitude.toDouble(), longitude.toDouble()),
      );
    } catch (error) {
      _showError('Không mở được chỉ đường: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final shift = widget.shift;
    final date = DateFormat('dd/MM/yyyy HH:mm');
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Chi tiết ca làm'),
        actions: [
          if (!_completed)
            IconButton(
              onPressed: _delete,
              tooltip: 'Xóa ca',
              icon: const Icon(Icons.delete_outline),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    shift.location,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Trạng thái: ${_completed ? 'Đã hoàn thành' : shift.statusLabel}',
                  ),
                  Text('Bắt đầu: ${date.format(shift.startTime)}'),
                  Text('Kết thúc: ${date.format(shift.endTime)}'),
                  Text('Mã ca: ${shift.id}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _showLocation,
            icon: const Icon(Icons.directions_outlined),
            label: const Text('Xem địa điểm và chỉ đường'),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Khách hàng trong ca (${_customerIds.length})',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              if (!_completed)
                TextButton(
                  onPressed: _chooseCustomers,
                  child: const Text('Chỉnh sửa'),
                ),
            ],
          ),
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: _customerStream,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Text('Không tải được khách hàng.');
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final customers = snapshot.data!
                  .where((customer) => _customerIds.contains(customer['id']))
                  .toList();
              if (customers.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('Chưa có khách hàng trong ca.'),
                );
              }
              return Column(
                children: [
                  ...customers.map(
                    (customer) => Card(
                      child: ListTile(
                        title: Text((customer['fullName'] ?? '').toString()),
                        subtitle: Text((customer['address'] ?? '').toString()),
                        trailing: const Icon(Icons.directions),
                        onTap: () => _navigateToCustomer(customer),
                      ),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CustomerMapScreen(customers: customers),
                      ),
                    ),
                    icon: const Icon(Icons.map_outlined),
                    label: const Text('Xem khách hàng trên bản đồ'),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 20),
          if (_completed) ...[
            Text(
              'Ảnh đơn hàng khi hoàn thành',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (_proofUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  _proofUrl!,
                  height: 220,
                  fit: BoxFit.contain,
                ),
              )
            else
              const Text('Ca cũ chưa có ảnh chứng từ.'),
          ] else ...[
            Text(
              'Hoàn thành ca',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text('Chụp ảnh đơn hàng hoặc biên nhận trước khi xác nhận.'),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _saving ? null : _takeProofPhoto,
              icon: const Icon(Icons.camera_alt_outlined),
              label: Text(_proofPhoto == null ? 'Chụp đơn hàng' : 'Chụp lại'),
            ),
            if (_proofPhoto != null) ...[
              FutureBuilder(
                future: _proofPhoto!.readAsBytes(),
                builder: (context, snapshot) => snapshot.hasData
                    ? Image.memory(
                        snapshot.data!,
                        height: 220,
                        fit: BoxFit.contain,
                      )
                    : const Center(child: CircularProgressIndicator()),
              ),
              const SizedBox(height: 12),
            ],
            FilledButton.icon(
              onPressed: _proofPhoto == null || _saving ? null : _complete,
              icon: const Icon(Icons.check_circle_outline),
              label: Text(
                _saving
                    ? 'Đang tải ảnh và lưu...'
                    : 'Xác nhận đã hoàn thành ca',
              ),
            ),
          ],
        ],
      ),
    );
  }
}
