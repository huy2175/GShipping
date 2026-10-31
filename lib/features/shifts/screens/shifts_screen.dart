import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

import '../../contacts/services/firestore_customer_service.dart';
import '../../../shared/services/location_tools.dart';
import '../../../shared/widgets/location_picker_screen.dart';
import '../models/shift_model.dart';
import '../services/firestore_shift_service.dart';
import '../widgets/customer_picker_dialog.dart';
import 'customer_map_screen.dart';
import 'shift_detail_screen.dart';

class ShiftsScreen extends StatefulWidget {
  const ShiftsScreen({super.key});

  @override
  State<ShiftsScreen> createState() => _ShiftsScreenState();
}

class _ShiftsScreenState extends State<ShiftsScreen> {
  final _service = FirestoreShiftService();
  late final _stream = _service.getShiftsStream();
  String _filter = 'all';

  bool _matchesFilter(Shift shift) {
    final today = DateUtils.dateOnly(DateTime.now());
    final date = DateUtils.dateOnly(shift.startTime);
    switch (_filter) {
      case 'today':
        return date == today;
      case 'tomorrow':
        return date == today.add(const Duration(days: 1));
      case 'week':
        return !date.isBefore(today) &&
            date.isBefore(today.add(const Duration(days: 7)));
      default:
        return true;
    }
  }

  Future<DateTime?> _pickDateTime(DateTime initial) async {
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateUtils.dateOnly(DateTime.now()),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return null;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null) return null;
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  Future<void> _addShift() async {
    final address = TextEditingController();
    var start = DateTime.now().add(const Duration(days: 1));
    var end = start.add(const Duration(hours: 4));
    LatLng? point;
    List<String> customerIds = [];
    var saving = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, refresh) => AlertDialog(
          title: const Text('Đăng ký ca mới'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: address,
                  decoration: const InputDecoration(
                    labelText: 'Địa điểm / tên ca',
                    hintText: 'Ví dụ: Giao hàng tại Quận 1',
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () async {
                    final chosen = await Navigator.push<LatLng>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => LocationPickerScreen(initial: point),
                      ),
                    );
                    if (chosen == null || !dialogContext.mounted) return;
                    refresh(() => point = chosen);
                    if (address.text.trim().isEmpty) {
                      try {
                        final label = await LocationTools.addressAt(chosen);
                        if (label != null && dialogContext.mounted) {
                          address.text = label;
                        }
                      } catch (_) {
                        // Tên địa điểm vẫn có thể nhập thủ công.
                      }
                    }
                  },
                  icon: const Icon(Icons.location_on_outlined),
                  label: Text(
                    point == null
                        ? 'Chọn vị trí trên bản đồ'
                        : '${point!.latitude.toStringAsFixed(5)}, ${point!.longitude.toStringAsFixed(5)}',
                  ),
                ),
                const SizedBox(height: 8),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Bắt đầu'),
                  subtitle: Text(DateFormat('dd/MM/yyyy HH:mm').format(start)),
                  trailing: const Icon(Icons.edit_calendar),
                  onTap: () async {
                    final chosen = await _pickDateTime(start);
                    if (chosen != null && dialogContext.mounted) {
                      refresh(() => start = chosen);
                    }
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Kết thúc'),
                  subtitle: Text(DateFormat('dd/MM/yyyy HH:mm').format(end)),
                  trailing: const Icon(Icons.edit_calendar),
                  onTap: () async {
                    final chosen = await _pickDateTime(end);
                    if (chosen != null && dialogContext.mounted) {
                      refresh(() => end = chosen);
                    }
                  },
                ),
                OutlinedButton.icon(
                  onPressed: () async {
                    final chosen = await showCustomerPicker(
                      context,
                      customerIds,
                    );
                    if (chosen != null && dialogContext.mounted) {
                      refresh(() => customerIds = chosen);
                    }
                  },
                  icon: const Icon(Icons.people_outline),
                  label: Text('Khách hàng trong ca (${customerIds.length})'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.pop(dialogContext),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: saving
                  ? null
                  : () async {
                      if (address.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Vui lòng nhập địa điểm hoặc tên ca.',
                            ),
                          ),
                        );
                        return;
                      }
                      if (!end.isAfter(start) ||
                          start.isBefore(DateTime.now())) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Thời gian ca không hợp lệ.'),
                          ),
                        );
                        return;
                      }
                      refresh(() => saving = true);
                      try {
                        await _service.addShift(
                          startTime: start,
                          endTime: end,
                          location: address.text.trim(),
                          locationCoord: point,
                          customerIds: customerIds,
                        );
                        if (dialogContext.mounted) Navigator.pop(dialogContext);
                      } catch (error) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Không tạo được ca: $error'),
                            ),
                          );
                        }
                        if (dialogContext.mounted) {
                          refresh(() => saving = false);
                        }
                      }
                    },
              child: Text(saving ? 'Đang lưu...' : 'Tạo ca'),
            ),
          ],
        ),
      ),
    );
    address.dispose();
  }

  Future<void> _showAllCustomers() async {
    try {
      final customers = await FirestoreCustomerService().getCustomers();
      if (!mounted) return;
      if (customers.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Chưa có khách hàng nào.')),
        );
        return;
      }
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CustomerMapScreen(customers: customers),
        ),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không tải được khách hàng: $error')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF8FAFC),
    appBar: AppBar(
      title: const Text('Ca làm việc'),
      centerTitle: true,
      actions: [
        IconButton(
          onPressed: _showAllCustomers,
          tooltip: 'Xem tất cả khách hàng',
          icon: const Icon(Icons.map_outlined),
        ),
      ],
    ),
    body: Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _chip('all', 'Tất cả'),
              _chip('today', 'Hôm nay'),
              _chip('tomorrow', 'Ngày mai'),
              _chip('week', '7 ngày tới'),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: _stream,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Text('Không tải được ca: ${snapshot.error}'),
                );
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final shifts = snapshot.data!
                  .map(Shift.fromMap)
                  .where(_matchesFilter)
                  .toList();
              if (shifts.isEmpty) {
                return const Center(
                  child: Text('Chưa có ca làm việc trong khoảng này.'),
                );
              }
              final open = shifts.where((s) => !s.isCompleted).toList()
                ..sort((a, b) => a.startTime.compareTo(b.startTime));
              final completed = shifts.where((s) => s.isCompleted).toList()
                ..sort((a, b) => b.startTime.compareTo(a.startTime));
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
                children: [
                  _summary(open.length, completed.length),
                  if (open.isNotEmpty) ...[
                    const _SectionTitle('Chưa hoàn thành'),
                    ...open.map(_shiftCard),
                  ],
                  if (completed.isNotEmpty) ...[
                    const _SectionTitle('Đã hoàn thành'),
                    ...completed.map(_shiftCard),
                  ],
                ],
              );
            },
          ),
        ),
      ],
    ),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: _addShift,
      icon: const Icon(Icons.add),
      label: const Text('Đăng ký ca mới'),
    ),
  );

  Widget _chip(String value, String label) => Padding(
    padding: const EdgeInsets.only(right: 8),
    child: ChoiceChip(
      selected: _filter == value,
      label: Text(label),
      onSelected: (_) => setState(() => _filter = value),
    ),
  );

  Widget _summary(int open, int completed) => Card(
    color: const Color(0xFFEFF6FF),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Text('Chưa hoàn thành: $open'),
          Text('Đã hoàn thành: $completed'),
        ],
      ),
    ),
  );

  Widget _shiftCard(Shift shift) => Card(
    color: Colors.white,
    child: ListTile(
      title: Text(shift.location, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        '${DateFormat('dd/MM HH:mm').format(shift.startTime)} – '
        '${DateFormat('dd/MM HH:mm').format(shift.endTime)}\n'
        '${shift.customerIds.length} khách hàng • ${shift.statusLabel}',
      ),
      isThreeLine: true,
      trailing: const Icon(Icons.chevron_right),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ShiftDetailScreen(shift: shift)),
      ),
    ),
  );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);
  final String title;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
    child: Text(title, style: Theme.of(context).textTheme.titleMedium),
  );
}
