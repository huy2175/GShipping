import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';

import 'i_customer_service.dart';

class FirestoreCustomerService implements ICustomerService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String _collection = 'customers';

  @override
  Future<void> addCustomer({
    required String name,
    required String phone,
    required String address,
    required LatLng location,
    List<String>? imageUrls,
  }) async {
    try {
      await _db.collection(_collection).add({
        'fullName': name,
        'phoneNumber': phone,
        'address': address,
        'latitude': location.latitude,
        'longitude': location.longitude,
        'imageUrls': imageUrls,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Firestore Error (add): $e');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getCustomers() async {
    try {
      QuerySnapshot snapshot = await _db
          .collection(_collection)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        return {'id': doc.id, ...doc.data() as Map<String, dynamic>};
      }).toList();
    } catch (e) {
      throw Exception('Firestore Error (get): $e');
    }
  }

  Stream<List<Map<String, dynamic>>> getCustomersStream() {
    return _db
        .collection(_collection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return {'id': doc.id, ...doc.data()};
          }).toList();
        });
  }

  @override
  Future<void> updateCustomer(String id, Map<String, dynamic> data) async {
    try {
      await _db.collection(_collection).doc(id).update(data);
    } catch (e) {
      throw Exception('Firestore Error (update): $e');
    }
  }

  @override
  Future<void> deleteCustomer(String id) async {
    try {
      await _db.collection(_collection).doc(id).delete();
    } catch (e) {
      throw Exception('Firestore Error (delete): $e');
    }
  }
}
