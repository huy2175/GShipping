import 'package:flutter/material.dart';

import '../../contacts/services/firestore_customer_service.dart';

Future<List<String>?> showCustomerPicker(
  BuildContext context,
  List<String> initialIds,
) {
  final selected = initialIds.toSet();
  final stream = FirestoreCustomerService().getCustomersStream();
  var query = '';

  return showDialog<List<String>>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, refresh) => AlertDialog(
        title: const Text('Khách hàng trong ca'),
        content: SizedBox(
          width: 420,
          height: 380,
          child: Column(
            children: [
              TextField(
                onChanged: (value) =>
                    refresh(() => query = value.toLowerCase().trim()),
                decoration: const InputDecoration(
                  hintText: 'Tìm tên hoặc số điện thoại',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
              Expanded(
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: stream,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return const Center(
                        child: Text('Không tải được khách hàng'),
                      );
                    }
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final customers = snapshot.data!.where((customer) {
                      if (customer['latitude'] is! num ||
                          customer['longitude'] is! num) {
                        return false;
                      }
                      final name = (customer['fullName'] ?? '')
                          .toString()
                          .toLowerCase();
                      final phone = (customer['phoneNumber'] ?? '').toString();
                      return name.contains(query) || phone.contains(query);
                    }).toList();
                    if (customers.isEmpty) {
                      return const Center(
                        child: Text(
                          'Không có khách hàng phù hợp đã lưu vị trí',
                        ),
                      );
                    }
                    return ListView.builder(
                      itemCount: customers.length,
                      itemBuilder: (context, index) {
                        final customer = customers[index];
                        final id = customer['id'] as String;
                        return CheckboxListTile(
                          value: selected.contains(id),
                          title: Text((customer['fullName'] ?? '').toString()),
                          subtitle: Text(
                            '${customer['phoneNumber'] ?? ''}\n${customer['address'] ?? ''}',
                          ),
                          onChanged: (value) => refresh(() {
                            if (value == true) {
                              selected.add(id);
                            } else {
                              selected.remove(id);
                            }
                          }),
                        );
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
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, selected.toList()),
            child: Text('Lưu (${selected.length})'),
          ),
        ],
      ),
    ),
  );
}
