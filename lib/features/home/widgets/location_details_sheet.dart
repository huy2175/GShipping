import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:image_picker/image_picker.dart';

import '../../contacts/services/i_customer_service.dart';
import '../../contacts/services/firestore_customer_service.dart';
import '../../../shared/services/image_upload_service.dart';

class LocationDetailsSheet extends StatefulWidget {
  final LatLng location;
  final VoidCallback? onDeletePin;
  final VoidCallback? onSaved;

  const LocationDetailsSheet({
    super.key,
    required this.location,
    this.onDeletePin,
    this.onSaved,
  });

  @override
  State<LocationDetailsSheet> createState() => _LocationDetailsSheetState();
}

class _LocationDetailsSheetState extends State<LocationDetailsSheet> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final ICustomerService _customerService = FirestoreCustomerService();

  final List<XFile> _imageFiles = [];
  final ImagePicker _picker = ImagePicker();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      if (_isSubmitting) return; // Ngăn chặn nhấn nhiều lần

      setState(() {
        _isSubmitting = true;
      });

      _formKey.currentState!.save();

      try {
        List<String> imageUrls = [];

        for (var file in _imageFiles) {
          final uploadedUrl = await ImageUploadService.upload(file);
          imageUrls.add(uploadedUrl);
        }

        await _customerService.addCustomer(
          name: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
          address: _addressController.text.trim(),
          location: widget.location,
          imageUrls: imageUrls,
        );

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã lưu khách hàng và ảnh thành công!'),
            backgroundColor: Color(0xFF15803D),
          ),
        );
        widget.onSaved?.call();
        Navigator.pop(context);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi lưu dữ liệu: ${e.toString()}'),
            backgroundColor: const Color(0xFFB91C1C),
          ),
        );
      } finally {
        if (mounted) {
          setState(() {
            _isSubmitting = false;
          });
        }
      }
    }
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1600,
    );
    if (pickedFile != null) {
      setState(() {
        _imageFiles.add(pickedFile);
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _imageFiles.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 25),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Thêm Khách Hàng Mới',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  if (widget.onDeletePin != null)
                    IconButton(
                      onPressed: () {
                        widget.onDeletePin?.call();
                        Navigator.pop(context);
                      },
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Color(0xFFB91C1C),
                      ),
                      tooltip: 'Xóa ghim này',
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Vui lòng nhập thông tin khách hàng cho vị trí này',
                style: TextStyle(fontSize: 14, color: const Color(0xFF64748B)),
              ),
              const SizedBox(height: 25),

              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _imageFiles.length + 1,
                  itemBuilder: (context, index) {
                    if (index == _imageFiles.length) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            width: 100,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: const Icon(
                              Icons.add_a_photo_outlined,
                              color: Color(0xFF64748B),
                              size: 30,
                            ),
                          ),
                        ),
                      );
                    }
                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: FutureBuilder(
                              future: _imageFiles[index].readAsBytes(),
                              builder: (context, snapshot) => snapshot.hasData
                                  ? Image.memory(
                                      snapshot.data!,
                                      width: 100,
                                      height: 100,
                                      fit: BoxFit.cover,
                                    )
                                  : const SizedBox(width: 100, height: 100),
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () => _removeImage(index),
                              child: Container(
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 25),

              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Họ và Tên',
                  prefixIcon: const Icon(
                    Icons.person_outline,
                    color: Color(0xFF64748B),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                ),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'Vui lòng nhập họ tên'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Số điện thoại',
                  prefixIcon: const Icon(
                    Icons.phone_outlined,
                    color: Color(0xFF64748B),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập số điện thoại';
                  }
                  if (value.length < 10) return 'Số điện thoại không hợp lệ';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                decoration: InputDecoration(
                  labelText: 'Địa chỉ chi tiết',
                  prefixIcon: const Icon(
                    Icons.location_on_outlined,
                    color: Color(0xFF64748B),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                ),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'Vui lòng nhập địa chỉ'
                    : null,
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFDBEAFE)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.map, color: Color(0xFF2563EB), size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Tọa độ: ${widget.location.latitude.toStringAsFixed(5)}, ${widget.location.longitude.toStringAsFixed(5)}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isSubmitting
                        ? Colors.grey
                        : const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  onPressed: _isSubmitting ? null : _submitForm,
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3,
                          ),
                        )
                      : const Text(
                          'LƯU KHÁCH HÀNG',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}
