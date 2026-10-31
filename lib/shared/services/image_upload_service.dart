import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class ImageUploadService {
  static Future<String> upload(XFile image) async {
    final request =
        http.MultipartRequest(
            'POST',
            Uri.parse('https://api.cloudinary.com/v1_1/dbbliokko/image/upload'),
          )
          ..fields['upload_preset'] = 'gshipping_preset'
          ..files.add(
            http.MultipartFile.fromBytes(
              'file',
              await image.readAsBytes(),
              filename: image.name,
            ),
          );
    final response = await request.send();
    final body = jsonDecode(await response.stream.bytesToString());
    if (response.statusCode != 200 || body['secure_url'] is! String) {
      throw Exception('Tải ảnh thất bại. Vui lòng thử lại.');
    }
    return body['secure_url'] as String;
  }
}
