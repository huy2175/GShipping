import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';

import 'i_shift_service.dart';

class FirestoreShiftService implements IShiftService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String _collection = 'shifts';

  @override
  Future<List<Map<String, dynamic>>> getShifts() async {
    try {
      QuerySnapshot snapshot = await _db
          .collection(_collection)
          .orderBy('startTime', descending: false)
          .get();

      return snapshot.docs.map((doc) {
        return {'id': doc.id, ...doc.data() as Map<String, dynamic>};
      }).toList();
    } catch (e) {
      throw Exception('Firestore Error (getShifts): $e');
    }
  }

  @override
  Stream<List<Map<String, dynamic>>> getShiftsStream() {
    return _db
        .collection(_collection)
        .orderBy('startTime', descending: false)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return {'id': doc.id, ...doc.data()};
          }).toList();
        });
  }

  @override
  Future<void> addShift({
    required DateTime startTime,
    required DateTime endTime,
    required String location,
    LatLng? locationCoord,
    required List<String> customerIds,
    String status = 'pending',
  }) async {
    if (location.trim().isEmpty || !endTime.isAfter(startTime)) {
      throw ArgumentError('Địa điểm hoặc thời gian ca không hợp lệ.');
    }
    try {
      await _db.collection(_collection).add({
        'startTime': Timestamp.fromDate(startTime),
        'endTime': Timestamp.fromDate(endTime),
        'location': location,
        if (locationCoord != null) ...{
          'latitude': locationCoord.latitude,
          'longitude': locationCoord.longitude,
        },
        'status': status,
        'customerIds': customerIds,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Firestore Error (addShift): $e');
    }
  }

  @override
  Future<void> completeShift(String id, String proofImageUrl) async {
    if (proofImageUrl.trim().isEmpty) {
      throw ArgumentError('Cần ảnh đơn hàng để hoàn thành ca.');
    }
    try {
      final reference = _db.collection(_collection).doc(id);
      await _db.runTransaction((transaction) async {
        final snapshot = await transaction.get(reference);
        if (!snapshot.exists || snapshot.data()?['status'] == 'completed') {
          throw StateError('Ca không tồn tại hoặc đã hoàn thành.');
        }
        transaction.update(reference, {
          'status': 'completed',
          'proofImageUrl': proofImageUrl,
          'completedAt': FieldValue.serverTimestamp(),
        });
      });
    } catch (e) {
      throw Exception('Firestore Error (completeShift): $e');
    }
  }

  @override
  Future<void> updateCustomerIds(String id, List<String> customerIds) async {
    await _db.collection(_collection).doc(id).update({
      'customerIds': customerIds,
    });
  }

  @override
  Future<void> deleteShift(String id) async {
    try {
      await _db.collection(_collection).doc(id).delete();
    } catch (e) {
      throw Exception('Firestore Error (deleteShift): $e');
    }
  }
}
