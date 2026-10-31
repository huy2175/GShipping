import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

import '../services/firestore_shift_service.dart';
import '../../contacts/services/firestore_customer_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'shift_detail_screen.dart';
import 'customer_map_screen.dart';
import '../models/shift_model.dart';
import 'package:g_shipping/shared/widgets/animated_card.dart';

class ShiftsScreen extends StatefulWidget {
  const ShiftsScreen({super.key});

  @override
  State<ShiftsScreen> createState() => _ShiftsScreenState();
}

class _ShiftsScreenState extends State<ShiftsScreen> {
  final FirestoreShiftService _shiftService = FirestoreShiftService();
  final FirestoreCustomerService _customerService = FirestoreCustomerService();
  String _selectedFilter = 'all'; // 'all', 'today', 'tomorrow', 'this_week'

  final TextEditingController _phoneSearchController = TextEditingController();
  List<Map<String, dynamic>> _searchedCustomers = [];
  Set<String> _selectedCustomerIds = {};

  Color _getStatusColor(String status, Shift shift) {
    final now = DateTime.now();
    if (now.isAfter(shift.startTime) && now.isBefore(shift.endTime)) {
      return const Color(0xFF2563EB); // Active Blue
    } else if (now.isAfter(shift.endTime)) {
      return const Color(0xFF64748B); // Completed Slate
    }

    switch (status) {
      case 'confirmed':
        return const Color(0xFF15803D); // Success Green
      case 'pending':
        return const Color(0xFFB45309); // Warning Amber
      case 'completed':
        return const Color(0xFF64748B); // Slate
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status, Shift shift) {
    final now = DateTime.now();
    if (now.isAfter(shift.startTime) && now.isBefore(shift.endTime)) {
      return 'Đang thực hiện';
    } else if (now.isAfter(shift.endTime)) {
      return 'Hoàn thành';
    }

    switch (status) {
      case 'confirmed':
        return 'Đã xác nhận';
      case 'pending':
        return 'Đang chờ';
      case 'completed':
        return 'Hoàn thành';
      default:
        return 'Không xác định';
    }
  }

  Future<void> _searchCustomerByPhone(String phone) async {
    if (phone.isEmpty) {
      setState(() {
        _searchedCustomers = [];
      });
      return;
    }

    try {
      final data = await _customerService.getCustomers();
      setState(() {
        _searchedCustomers = data.where((c) => c['phoneNumber'].toString().contains(phone)).toList();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi tìm kiếm: $e')));
    }
  }

  void _showCustomerSelectionDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text(
                'Tìm & Chọn khách hàng',
                style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w600),
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _phoneSearchController,
                      decoration: InputDecoration(
                        labelText: 'Nhập SĐT khách hàng',
                        prefixIcon: const Icon(Icons.phone, color: Color(0xFF64748B)),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF2563EB), width: 2),
                        ),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onChanged: (value) {
                        _searchCustomerByPhone(value);
                        setState(() {});
                      },
                    ),
                    const SizedBox(height: 16),
                    Flexible(
                      child: _searchedCustomers.isEmpty
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(20),
                                child: Text('Không tìm thấy khách hàng nào', style: TextStyle(color: Color(0xFF64748B))),
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              itemCount: _searchedCustomers.length,
                              itemBuilder: (context, index) {
                                final customer = _searchedCustomers[index];
                                final id = customer['id'];
                                final isSelected = _selectedCustomerIds.contains(id);

                                return CheckboxListTile(
                                  title: Text(
                                    customer['fullName'],
                                    style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w500),
                                  ),
                                  subtitle: Text(customer['phoneNumber'], style: const TextStyle(color: Color(0xFF64748B))),
                                  value: isSelected,
                                  activeColor: const Color(0xFF2563EB),
                                  onChanged: (val) {
                                    setState(() {
                                      if (val == true) {
                                        _selectedCustomerIds.add(id);
                                      } else {
                                        _selectedCustomerIds.remove(id);
                                      }
                                    });
                                    setStateDialog(() {});
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Hủy', style: TextStyle(color: Color(0xFF64748B))),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (_selectedCustomerIds.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng chọn ít nhất một khách hàng')));
                      return;
                    }
                    Navigator.pop(context);
                    _showMapWithSelectedCustomers();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Xem bản đồ'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showMapWithSelectedCustomers() async {
    List<Map<String, dynamic>> selectedData = [];
    final allCustomers = await _customerService.getCustomers();

    for (var id in _selectedCustomerIds) {
      final customer = allCustomers.firstWhere((c) => c['id'] == id);
      selectedData.add(customer);
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CustomerMapScreen(customers: selectedData),
      ),
    );
  }

  List<Shift> _filterShiftsByTime(List<Shift> shifts) {
    if (_selectedFilter == 'all') return shifts;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    return shifts.where((shift) {
      final shiftDate = DateTime(shift.startTime.year, shift.startTime.month, shift.startTime.day);

      switch (_selectedFilter) {
        case 'today':
          return shiftDate.isAtSameMomentAs(today);
        case 'tomorrow':
          return shiftDate.isAtSameMomentAs(tomorrow);
        case 'this_week':
          return shift.startTime.isAfter(today) &&
                 shift.startTime.isBefore(today.add(const Duration(days: 7)));
        default:
          return true;
      }
    }).toList();
  }

  void _showAddShiftDialog() {
    final pageContext = context;
    final TextEditingController locationController = TextEditingController();
    DateTime selectedStart = DateTime.now().add(const Duration(days: 1));
    DateTime selectedEnd = DateTime.now().add(const Duration(days: 1, hours: 4));
    final customersFuture = _customerService.getCustomers();
    final selectedCustomerIds = <String>{};

    showDialog(
      context: pageContext,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setStateDialog) {
            return AlertDialog(
              scrollable: true,
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text(
                'Đăng ký ca làm mới',
                style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w600),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                    TextField(
                      controller: locationController,
                      decoration: InputDecoration(
                        labelText: 'Địa điểm',
                        hintText: 'Nhập địa chỉ ca làm...',
                        prefixIcon: const Icon(Icons.location_on, color: Color(0xFF64748B)),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF2563EB), width: 2),
                        ),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton.icon(
                            icon: const Icon(Icons.calendar_today, size: 18),
                            label: Text(DateFormat('dd/MM HH:mm').format(selectedStart)),
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFF0F172A),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: dialogContext,
                                initialDate: selectedStart,
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now().add(const Duration(days: 365)),
                              );
                              if (picked != null) {
                                final time = await showTimePicker(
                                  context: dialogContext,
                                  initialTime: TimeOfDay.fromDateTime(selectedStart),
                                );
                                if (time != null) {
                                  setStateDialog(() {
                                    selectedStart = DateTime(picked.year, picked.month, picked.day, time.hour, time.minute);
                                  });
                                }
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward, size: 16, color: Color(0xFF64748B)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextButton.icon(
                            icon: const Icon(Icons.calendar_today, size: 18),
                            label: Text(DateFormat('dd/MM HH:mm').format(selectedEnd)),
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFF0F172A),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: dialogContext,
                                initialDate: selectedEnd,
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now().add(const Duration(days: 365)),
                              );
                              if (picked != null) {
                                final time = await showTimePicker(
                                  context: dialogContext,
                                  initialTime: TimeOfDay.fromDateTime(selectedEnd),
                                );
                                if (time != null) {
                                  setStateDialog(() {
                                    selectedEnd = DateTime(picked.year, picked.month, picked.day, time.hour, time.minute);
                                  });
                                }
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Khách hàng trong ca',
                        style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(height: 8),
                    FutureBuilder<List<Map<String, dynamic>>>(
                      future: customersFuture,
                      builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator(color: Color(0xFF2563EB)));
                          }
                          if (snapshot.hasError) {
                            return Center(
                              child: Text('Lỗi tải khách hàng: ${snapshot.error}', style: const TextStyle(color: Color(0xFFB91C1C))),
                            );
                          }
                          final customers = snapshot.data ?? [];
                          if (customers.isEmpty) {
                            return const Center(
                              child: Text('Chưa có khách hàng đã lưu', style: TextStyle(color: Color(0xFF64748B))),
                            );
                          }

                          return Column(
                            children: customers.map((customer) {
                              final id = customer['id']?.toString() ?? '';
                              if (id.isEmpty) return const SizedBox.shrink();

                              return CheckboxListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(
                                  customer['fullName']?.toString() ?? 'Khách hàng',
                                  style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w500),
                                ),
                                subtitle: Text(
                                  customer['phoneNumber']?.toString() ?? '',
                                  style: const TextStyle(color: Color(0xFF64748B)),
                                ),
                                value: selectedCustomerIds.contains(id),
                                activeColor: const Color(0xFF2563EB),
                                onChanged: (selected) {
                                  setStateDialog(() {
                                    if (selected == true) {
                                      selectedCustomerIds.add(id);
                                    } else {
                                      selectedCustomerIds.remove(id);
                                    }
                                  });
                                },
                              );
                            }).toList(),
                          );
                      },
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Hủy', style: TextStyle(color: Color(0xFF64748B))),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (locationController.text.isEmpty) {
                      ScaffoldMessenger.of(pageContext).showSnackBar(const SnackBar(content: Text('Vui lòng nhập địa điểm')));
                      return;
                    }
                    try {
                      await _shiftService.addShift(
                        startTime: selectedStart,
                        endTime: selectedEnd,
                        location: locationController.text,
                        locationCoord: const LatLng(10.762622, 106.660172),
                        customerIds: selectedCustomerIds.toList(),
                      );
                      if (!mounted || !dialogContext.mounted) return;
                      Navigator.pop(dialogContext);
                      ScaffoldMessenger.of(pageContext).showSnackBar(const SnackBar(content: Text('Đăng ký ca làm thành công!')));
                    } catch (e) {
                      if (mounted && pageContext.mounted) {
                        ScaffoldMessenger.of(pageContext).showSnackBar(SnackBar(content: Text('Lỗi khi tạo ca: $e')));
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Tạo ca'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Ca làm việc',
          style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: const Color(0xFF0F172A),
        actions: [
          IconButton(
            icon: const Icon(Icons.map, color: Color(0xFF2563EB)),
            onPressed: _showCustomerSelectionDialog,
            tooltip: 'Tìm khách hàng và xem bản đồ',
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('all', 'Tất cả'),
                  const SizedBox(width: 8),
                  _buildFilterChip('today', 'Hôm nay'),
                  const SizedBox(width: 8),
                  _buildFilterChip('tomorrow', 'Ngày mai'),
                  const SizedBox(width: 8),
                  _buildFilterChip('this_week', 'Tuần này'),
                ],
              ),
            ),
          ),
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: _shiftService.getShiftsStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Expanded(child: Center(child: CircularProgressIndicator(color: Color(0xFF2563EB))));
              }
              if (snapshot.hasError) {
                return Expanded(child: Center(child: Text('Lỗi tải dữ liệu: ${snapshot.error}', style: const TextStyle(color: Color(0xFFB91C1C)))));
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Expanded(child: Center(child: Text('Chưa có ca làm việc nào', style: TextStyle(color: Color(0xFF64748B)))));
              }

              final allShifts = snapshot.data!.map((map) => Shift.fromMap(map)).toList();
              final filteredShifts = _filterShiftsByTime(allShifts);

              final upcomingShifts = filteredShifts.where((s) => s.startTime.isAfter(DateTime.now())).toList();
              final completedShifts = filteredShifts.where((s) => s.startTime.isBefore(DateTime.now())).toList();

              return Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF), // primaryTint
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFDBEAFE)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildSummaryItem('Ca sắp tới', upcomingShifts.length.toString()),
                          _buildSummaryItem('Hoàn thành', completedShifts.length.toString()),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.all(20),
                        children: [
                          if (upcomingShifts.isNotEmpty) ...[
                            const SectionHeader(title: 'Ca sắp tới'),
                            ...upcomingShifts.map((shift) => ShiftCard(
                              shift: shift,
                              statusColor: _getStatusColor(shift.status, shift),
                              statusText: _getStatusText(shift.status, shift),
                            )),
                          ],
                          if (upcomingShifts.isEmpty && completedShifts.isEmpty)
                            const Center(child: Padding(padding: EdgeInsets.all(40.0), child: Text('Không có ca nào trong khoảng thời gian này', style: TextStyle(color: Color(0xFF64748B))))),
                          const SizedBox(height: 24),
                          if (completedShifts.isNotEmpty) ...[
                            const SectionHeader(title: 'Lịch sử ca làm'),
                            ...completedShifts.map((shift) => ShiftCard(
                              shift: shift,
                              statusColor: _getStatusColor(shift.status, shift),
                              statusText: _getStatusText(shift.status, shift),
                            )),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddShiftDialog,
        label: const Text('Đăng ký ca mới', style: TextStyle(fontWeight: FontWeight.w600)),
        icon: const Icon(Icons.add),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        elevation: 2,
      ),
    );
  }

  Widget _buildFilterChip(String filter, String label) {
    final isSelected = _selectedFilter == filter;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() { _selectedFilter = filter; });
      },
      selectedColor: const Color(0xFF2563EB),
      backgroundColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : const Color(0xFF64748B),
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 13,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0)),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
        Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
      ],
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  const SectionHeader({super.key, required this.title});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Color(0xFF0F172A),
        ),
      ),
    );
  }
}

class ShiftCard extends StatelessWidget {
  final Shift shift;
  final Color statusColor;
  final String statusText;
  const ShiftCard({super.key, required this.shift, required this.statusColor, required this.statusText});
  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final timeFormat = DateFormat('HH:mm');
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      color: Colors.white,
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ShiftDetailScreen(shift: shift))),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Text(
                      dateFormat.format(shift.startTime),
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    ),
                    Text(
                      timeFormat.format(shift.startTime),
                      style: TextStyle(color: Colors.grey[600], fontSize: 11),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      shift.location,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.access_time, size: 14, color: Color(0xFF64748B)),
                        const SizedBox(width: 4),
                        Text(
                          '${timeFormat.format(shift.startTime)} - ${timeFormat.format(shift.endTime)}',
                          style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statusText,
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
