import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/customer_model.dart';
import '../services/firestore_customer_service.dart';
import '../../shifts/screens/customer_map_screen.dart';
import '../../../shared/widgets/location_picker_screen.dart';
import '../../../shared/services/image_upload_service.dart';

import 'package:latlong2/latlong.dart';

class CustomerDetailScreen extends StatefulWidget {
  final Customer customer;

  const CustomerDetailScreen({super.key, required this.customer});

  @override
  State<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen> {
  final FirestoreCustomerService _customerService = FirestoreCustomerService();
  bool _isEditing = false;
  LatLng? _selectedLocation;
  bool _locationChanged = false;
  late String _displayName = widget.customer.fullName;
  late String _savedPhone = widget.customer.phoneNumber;
  late String _savedAddress = widget.customer.address;
  late String _savedNote = widget.customer.note ?? '';
  late LatLng? _savedLocation = widget.customer.location;
  late List<String> _imageUrls = [...?widget.customer.imageUrls];
  final List<XFile> _newImages = [];
  final _picker = ImagePicker();

  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.customer.fullName);
    _phoneController = TextEditingController(text: widget.customer.phoneNumber);
    _addressController = TextEditingController(text: widget.customer.address);
    _noteController = TextEditingController(text: widget.customer.note);
    _selectedLocation = _savedLocation;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _updateCustomer() async {
    if (_nameController.text.trim().isEmpty ||
        _phoneController.text.trim().isEmpty ||
        _addressController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập đủ tên, số điện thoại và địa chỉ.'),
        ),
      );
      return;
    }
    if (_addressController.text.trim() != _savedAddress && !_locationChanged) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Địa chỉ đã đổi. Hãy chọn lại vị trí trên bản đồ.'),
        ),
      );
      return;
    }
    try {
      for (final image in _newImages) {
        _imageUrls.add(await ImageUploadService.upload(image));
      }
      await _customerService.updateCustomer(widget.customer.id, {
        'fullName': _nameController.text,
        'phoneNumber': _phoneController.text,
        'address': _addressController.text,
        'note': _noteController.text,
        'imageUrls': _imageUrls,
        if (_locationChanged && _selectedLocation != null) ...{
          'latitude': _selectedLocation!.latitude,
          'longitude': _selectedLocation!.longitude,
        },
      });
      if (!mounted) return;
      setState(() {
        _isEditing = false;
        _displayName = _nameController.text.trim();
        _savedPhone = _phoneController.text.trim();
        _savedAddress = _addressController.text.trim();
        _savedNote = _noteController.text.trim();
        _savedLocation = _selectedLocation;
        _newImages.clear();
        _locationChanged = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cập nhật thông tin khách hàng thành công!'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Lỗi cập nhật: $e')));
    }
  }

  Future<void> _viewOnMap() async {
    try {
      final allCustomers = await _customerService.getCustomers();
      if (!mounted) return;
      final customerData = allCustomers.firstWhere(
        (customer) => customer['id'] == widget.customer.id,
      );
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CustomerMapScreen(customers: [customerData]),
        ),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Không mở được bản đồ: $error')));
      }
    }
  }

  Future<void> _pickLocation() async {
    final selected = await Navigator.push<LatLng>(
      context,
      MaterialPageRoute(
        builder: (_) => LocationPickerScreen(initial: _selectedLocation),
      ),
    );
    if (selected != null && mounted) {
      setState(() {
        _selectedLocation = selected;
        _locationChanged = true;
      });
    }
  }

  Future<void> _addImages() async {
    final files = await _picker.pickMultiImage(imageQuality: 80, maxWidth: 1600);
    if (mounted && files.isNotEmpty) setState(() => _newImages.addAll(files));
  }

  Future<void> _deleteCustomer() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa khách hàng?'),
        content: Text('Bạn có chắc muốn xóa ${widget.customer.fullName}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Xóa')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await _customerService.deleteCustomer(widget.customer.id);
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Xóa thất bại: $error')));
    }
  }

  void _showImage(String url) => showDialog<void>(
    context: context,
    builder: (_) => Dialog.fullscreen(
      backgroundColor: Colors.black,
      child: Stack(children: [
        Center(child: InteractiveViewer(child: Image.network(url, fit: BoxFit.contain))),
        Positioned(top: 32, right: 12, child: IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, color: Colors.white))),
      ]),
    ),
  );

  void _toggleEditing() {
    if (_isEditing) {
      _nameController.text = _displayName;
      _phoneController.text = _savedPhone;
      _addressController.text = _savedAddress;
      _noteController.text = _savedNote;
      _selectedLocation = _savedLocation;
      _locationChanged = false;
      _newImages.clear();
      _imageUrls = [...?widget.customer.imageUrls];
    }
    setState(() => _isEditing = !_isEditing);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Chi tiết khách hàng',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: const Color(0xFF0F172A),
        actions: [
          if (!_isEditing) IconButton(onPressed: _deleteCustomer, tooltip: 'Xóa khách hàng', icon: const Icon(Icons.delete_outline, color: Colors.red)),
          IconButton(
            icon: Icon(
              _isEditing ? Icons.close : Icons.edit,
              color: const Color(0xFF2563EB),
            ),
            onPressed: _toggleEditing,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  _buildImageGallery(),
                  const SizedBox(height: 16),
                  Text(
                    _displayName,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            _buildInfoField('Họ và Tên', _nameController),
            const SizedBox(height: 20),
            _buildInfoField('Số điện thoại', _phoneController),
            const SizedBox(height: 20),
            _buildInfoField('Địa chỉ', _addressController),
            if (_isEditing) ...[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _pickLocation,
                icon: const Icon(Icons.location_on_outlined),
                label: Text(
                  _locationChanged
                      ? 'Đã chọn tọa độ mới'
                      : 'Chọn lại vị trí trên bản đồ',
                ),
              ),
            ],
            const SizedBox(height: 20),
            _buildInfoField('Ghi chú', _noteController),
            const SizedBox(height: 40),
            if (_isEditing)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _updateCustomer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Lưu thay đổi',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              )
            else
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _viewOnMap,
                  icon: const Icon(Icons.map),
                  label: const Text('Xem địa chỉ trên bản đồ'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF2563EB),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageGallery() {
    final images = _imageUrls;
    if (images.isEmpty && _newImages.isEmpty && !_isEditing) {
      return CircleAvatar(
        radius: 50,
        backgroundColor: const Color(0xFF2563EB),
        child: Text(
          widget.customer.fullName.isNotEmpty
              ? widget.customer.fullName[0].toUpperCase()
              : '?',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        shrinkWrap: true,
      itemCount: images.length + _newImages.length + (_isEditing ? 1 : 0),
        itemBuilder: (context, index) {
        if (index >= images.length + _newImages.length) return IconButton(onPressed: _addImages, icon: const Icon(Icons.add_a_photo, size: 36));
        if (index >= images.length) {
          final i = index - images.length;
          return Stack(children: [GestureDetector(onTap: () async { final bytes = await _newImages[i].readAsBytes(); if (mounted) showDialog<void>(context: context, builder: (_) => Dialog.fullscreen(child: InteractiveViewer(child: Image.memory(bytes)))); }, child: FutureBuilder(future: _newImages[i].readAsBytes(), builder: (_, s) => s.hasData ? Image.memory(s.data!, width: 100, height: 100, fit: BoxFit.cover) : const SizedBox(width: 100, height: 100))), if (_isEditing) Positioned(right: 0, child: IconButton(onPressed: () => setState(() => _newImages.removeAt(i)), icon: const Icon(Icons.cancel, color: Colors.red)))]);
        }
          return Stack(
            children: [
              Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: GestureDetector(onTap: () => _showImage(images[index]), child: Image.network(
                images[index],
                width: 100,
                height: 100,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 100,
                  height: 100,
                  color: const Color(0xFFF1F5F9),
                  child: const Icon(
                    Icons.broken_image,
                    color: Color(0xFFCBD5E1),
                  ),
                ),
              )),
            ),
              ),
              if (_isEditing)
                Positioned(
                  right: 0,
                  top: 0,
                  child: IconButton(
                    onPressed: () => setState(() => _imageUrls.removeAt(index)),
                    icon: const Icon(Icons.cancel, color: Colors.red),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildInfoField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        _isEditing
            ? TextField(
                controller: controller,
                decoration: InputDecoration(
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
                ),
              )
            : Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Text(
                  controller.text,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
      ],
    );
  }
}
