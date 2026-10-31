import 'package:latlong2/latlong.dart';

class Customer {
  final String id;
  final String fullName;
  final String phoneNumber;
  final String address;
  final String? note;
  final List<String>? imageUrls;
  final LatLng? location;

  Customer({
    required this.id,
    required this.fullName,
    required this.phoneNumber,
    required this.address,
    this.note,
    this.imageUrls,
    this.location,
  });

  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id'] ?? '',
      fullName: map['fullName'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      address: map['address'] ?? '',
      note: map['note'],
      imageUrls: map['imageUrls'] != null
          ? List<String>.from(map['imageUrls'])
          : null,
      location: map['latitude'] is num && map['longitude'] is num
          ? LatLng(
              (map['latitude'] as num).toDouble(),
              (map['longitude'] as num).toDouble(),
            )
          : null,
    );
  }
}
