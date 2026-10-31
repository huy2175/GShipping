import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';

class Shift {
  final String id;
  final DateTime startTime;
  final DateTime endTime;
  final String location;
  final String status; // 'pending', 'confirmed', 'completed'
  final LatLng? locationCoord;
  final List<String> customerIds;
  final String? proofImageUrl;
  final DateTime? completedAt;

  Shift({
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.location,
    required this.status,
    this.locationCoord,
    this.customerIds = const [],
    this.proofImageUrl,
    this.completedAt,
  });

  factory Shift.fromMap(Map<String, dynamic> map) {
    return Shift(
      id: map['id'] ?? '',
      startTime: _parseDateTime(map['startTime']),
      endTime: _parseDateTime(map['endTime']),
      location: map['location'] ?? '',
      status: map['status'] ?? 'pending',
      locationCoord: map['latitude'] is num && map['longitude'] is num
          ? LatLng(
              (map['latitude'] as num).toDouble(),
              (map['longitude'] as num).toDouble(),
            )
          : null,
      customerIds: List<String>.from(map['customerIds'] ?? const []),
      proofImageUrl: map['proofImageUrl'] as String?,
      completedAt: map['completedAt'] == null
          ? null
          : _parseDateTime(map['completedAt']),
    );
  }

  bool get isCompleted => status == 'completed';

  String get statusLabel {
    if (isCompleted) return 'Đã hoàn thành';
    final now = DateTime.now();
    if (now.isAfter(endTime)) return 'Quá hạn';
    if (now.isAfter(startTime)) return 'Đang thực hiện';
    return 'Sắp tới';
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.parse(value);
    return DateTime.now();
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'location': location,
      'status': status,
      'startTime': startTime,
      'endTime': endTime,
    };
  }
}
