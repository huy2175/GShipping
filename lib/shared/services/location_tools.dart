import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

class LocationTools {
  static const fallback = LatLng(10.762622, 106.660172);

  static bool get supportsGeocoding =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  static Future<http.Response> _photonGet(Uri uri) async {
    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        final response = await http
            .get(
              uri,
              headers: kIsWeb ? const {} : {'User-Agent': 'GShipping/1.0'},
            )
            .timeout(const Duration(seconds: 12));
        if (response.statusCode == 200) return response;

        final temporary =
            response.statusCode == 429 || response.statusCode >= 500;
        if (attempt == 0 && temporary) {
          final retryAfter = int.tryParse(
            response.headers['retry-after'] ?? '',
          );
          final seconds = retryAfter == null ? 2 : retryAfter.clamp(1, 5);
          await Future<void>.delayed(Duration(seconds: seconds));
          continue;
        }
        if (response.statusCode == 429) {
          throw Exception(
            'Tìm kiếm đang bị giới hạn tạm thời. Chờ một chút hoặc chạm lên bản đồ.',
          );
        }
        throw Exception(
          'Dịch vụ tìm kiếm trả lỗi ${response.statusCode}. Thử lại hoặc chạm lên bản đồ.',
        );
      } on TimeoutException {
        if (attempt == 0) {
          await Future<void>.delayed(const Duration(seconds: 1));
          continue;
        }
        throw Exception(
          'Dịch vụ tìm kiếm không phản hồi. Kiểm tra mạng hoặc chạm lên bản đồ.',
        );
      } on http.ClientException {
        if (attempt == 0) {
          await Future<void>.delayed(const Duration(seconds: 1));
          continue;
        }
        throw Exception(
          'Không kết nối được dịch vụ tìm kiếm. Kiểm tra mạng hoặc chạm lên bản đồ.',
        );
      }
    }
    throw Exception('Dịch vụ tìm kiếm tạm thời không khả dụng.');
  }

  static Future<LatLng> currentPosition() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw Exception('Hãy bật dịch vụ định vị.');
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw Exception('Ứng dụng chưa được cấp quyền vị trí.');
    }
    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
      timeLimit: const Duration(seconds: 20),
    );
    return LatLng(position.latitude, position.longitude);
  }

  static Future<LatLng?> searchAddress(String address) async {
    if (address.trim().isEmpty) return null;
    if (supportsGeocoding) {
      try {
        final results = await Geocoding().locationFromAddress(
          '${address.trim()}, Việt Nam',
        );
        if (results.isNotEmpty) {
          return LatLng(results.first.latitude, results.first.longitude);
        }
      } catch (_) {
        // Try the shared web and desktop geocoder below.
      }
    }
    final response = await _photonGet(
      Uri.https('photon.komoot.io', '/api/', {
        // Keep the user's query intact; adding a country suffix and a language
        // filter can make short/local business names fail on some Photon data.
        'q': address.trim(),
        'limit': '5',
      }),
    );
    final List features;
    try {
      features = (jsonDecode(response.body)['features'] as List?) ?? [];
    } catch (_) {
      throw Exception('Không đọc được kết quả tìm địa chỉ.');
    }
    if (features.isEmpty) return null;
    final coordinates = features.first['geometry']['coordinates'] as List;
    return LatLng(
      (coordinates[1] as num).toDouble(),
      (coordinates[0] as num).toDouble(),
    );
  }

  static Future<String?> addressAt(LatLng point) async {
    if (supportsGeocoding) {
      try {
        final places = await Geocoding().placemarkFromCoordinates(
          point.latitude,
          point.longitude,
        );
        if (places.isNotEmpty) {
          final place = places.first;
          final parts =
              [
                    place.name,
                    place.street,
                    place.subLocality,
                    place.locality,
                    place.administrativeArea,
                  ]
                  .where((part) => part != null && part.trim().isNotEmpty)
                  .cast<String>();
          final address = parts.toSet().join(', ');
          if (address.isNotEmpty) return address;
        }
      } catch (_) {
        // Fall back to Photon if native reverse geocoding is unavailable.
      }
    }
    final response = await http
        .get(
          Uri.https('photon.komoot.io', '/reverse', {
            'lat': '${point.latitude}',
            'lon': '${point.longitude}',
            'lang': 'vi',
          }),
          headers: kIsWeb ? const {} : {'User-Agent': 'GShipping/1.0'},
        )
        .timeout(const Duration(seconds: 12));
    if (response.statusCode != 200) return null;
    final List features;
    try {
      features = (jsonDecode(response.body)['features'] as List?) ?? [];
    } catch (_) {
      return null;
    }
    if (features.isEmpty) return null;
    final properties = features.first['properties'] as Map<String, dynamic>;
    return [
      properties['name'],
      properties['housenumber'],
      properties['street'],
      properties['district'],
      properties['city'],
      properties['state'],
    ].where((part) => part != null && part.toString().isNotEmpty).join(', ');
  }

  static Future<void> openPlace(LatLng point) => _open(
    Uri.https('www.google.com', '/maps/search/', {
      'api': '1',
      'query': '${point.latitude},${point.longitude}',
    }),
  );

  static Future<void> navigateTo(LatLng point) => _open(
    Uri.https('www.google.com', '/maps/dir/', {
      'api': '1',
      'destination': '${point.latitude},${point.longitude}',
      'travelmode': 'driving',
      'dir_action': 'navigate',
    }),
  );

  static Future<void> _open(Uri uri) async {
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Không mở được Google Maps.');
    }
  }
}
