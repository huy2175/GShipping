import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../services/firestore_customer_service.dart';
import 'customer_detail_screen.dart';
import '../models/customer_model.dart';

import 'package:g_shipping/shared/widgets/animated_card.dart';

import '../../../shared/widgets/location_picker_screen.dart';
import '../../home/widgets/location_details_sheet.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  final FirestoreCustomerService _customerService = FirestoreCustomerService();
  String _searchQuery = '';
  bool _isSelectionMode = false;
  final Set<String> _selectedCustomerIds = {};

  Future<void> _addCustomer() async {
    final point = await Navigator.push<LatLng>(
      context,
      MaterialPageRoute(builder: (_) => const LocationPickerScreen()),
    );
    if (point == null || !mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => LocationDetailsSheet(location: point),
    );
  }

  List<Customer> _filterCustomers(List<Customer> customers) {
    if (_searchQuery.isEmpty) return customers;
    return customers.where((c) {
      final query = _searchQuery.toLowerCase();
      return c.fullName.toLowerCase().contains(query) ||
          c.phoneNumber.contains(query) ||
          c.address.toLowerCase().contains(query);
    }).toList();
  }

  Future<void> _deleteSelectedCustomers() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text(
          'Bạn có chắc chắn muốn xóa ${_selectedCustomerIds.length} khách hàng đã chọn?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (!mounted) return;
    if (confirm == true) {
      try {
        for (var id in _selectedCustomerIds) {
          await _customerService.deleteCustomer(id);
        }
        if (!mounted) return;
        setState(() {
          _isSelectionMode = false;
          _selectedCustomerIds.clear();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xóa các khách hàng được chọn!')),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Lỗi khi xóa: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          _isSelectionMode ? 'Chọn khách hàng' : 'Khách hàng',
          style: const TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: const Color(0xFF0F172A),
        actions: [
          if (_isSelectionMode)
            IconButton(
              icon: const Icon(Icons.delete_sweep, color: Colors.red),
              onPressed: _deleteSelectedCustomers,
              tooltip: 'Xóa các mục đã chọn',
            )
          else
            IconButton(
              icon: const Icon(Icons.select_all),
              onPressed: () {
                setState(() {
                  _isSelectionMode = true;
                });
              },
              tooltip: 'Chọn nhiều khách hàng',
            ),
        ],
      ),
      body: Column(
        children: [
          if (!_isSelectionMode)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: TextField(
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Tìm tên, SĐT hoặc địa chỉ...',
                  hintStyle: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 14,
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: Color(0xFF64748B),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFF2563EB),
                      width: 2,
                    ),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                ),
              ),
            ),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _customerService.getCustomersStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFF2563EB)),
                  );
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Lỗi tải dữ liệu: ${snapshot.error}',
                      style: const TextStyle(color: Color(0xFFB91C1C)),
                    ),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text(
                      'Không có khách hàng nào',
                      style: TextStyle(color: Color(0xFF64748B)),
                    ),
                  );
                }

                final customers = snapshot.data!
                    .map((map) => Customer.fromMap(map))
                    .toList();
                final filteredCustomers = _filterCustomers(customers);

                if (filteredCustomers.isEmpty) {
                  return const Center(
                    child: Text(
                      'Không tìm thấy khách hàng nào',
                      style: TextStyle(color: Color(0xFF64748B)),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                  itemCount: filteredCustomers.length,
                  itemBuilder: (context, index) {
                    final customer = filteredCustomers[index];
                    return CustomerCard(
                      customer: customer,
                      isSelectionMode: _isSelectionMode,
                      isSelected: _selectedCustomerIds.contains(customer.id),
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedCustomerIds.add(customer.id);
                          } else {
                            _selectedCustomerIds.remove(customer.id);
                          }
                        });
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: _isSelectionMode
          ? null
          : FloatingActionButton.extended(
              onPressed: _addCustomer,
              icon: const Icon(Icons.person_add_alt_1),
              label: const Text('Thêm khách'),
            ),
    );
  }
}

class CustomerCard extends StatelessWidget {
  final Customer customer;
  final bool isSelectionMode;
  final bool isSelected;
  final ValueChanged<bool> onSelected;

  const CustomerCard({
    super.key,
    required this.customer,
    required this.isSelectionMode,
    required this.isSelected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedCard(
      onTap: () {
        if (isSelectionMode) {
          onSelected(!isSelected);
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CustomerDetailScreen(customer: customer),
            ),
          );
        }
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isSelected
                ? const Color(0xFF2563EB)
                : const Color(0xFFE2E8F0),
            width: isSelected ? 2 : 1,
          ),
        ),
        color: isSelected ? const Color(0xFFEFF6FF) : Colors.white,
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          leading: isSelectionMode
              ? Checkbox(
                  value: isSelected,
                  onChanged: (val) => onSelected(val ?? false),
                  activeColor: const Color(0xFF2563EB),
                )
              : CircleAvatar(
                  radius: 24,
                  backgroundColor: const Color(0xFF2563EB),
                  child: Text(
                    customer.fullName.isNotEmpty
                        ? customer.fullName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
          title: Text(
            customer.fullName,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: Color(0xFF0F172A),
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.phone, size: 14, color: Color(0xFF64748B)),
                  const SizedBox(width: 6),
                  Text(
                    customer.phoneNumber,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(
                    Icons.location_on,
                    size: 14,
                    color: Color(0xFF64748B),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      customer.address,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF0F172A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              if (customer.note != null) ...[
                const SizedBox(height: 6),
                Text(
                  'Note: ${customer.note}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ],
          ),
          trailing: isSelectionMode
              ? null
              : const Icon(Icons.chevron_right, color: Color(0xFF64748B)),
        ),
      ),
    );
  }
}
