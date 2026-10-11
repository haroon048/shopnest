import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

// Cloudinary par image upload (unsigned preset).
// Sirf image ka URL wapas aata hai, wo Firestore me save hota hai.
class CloudinaryService {
  static const _cloudName = 'kdgf3mee';
  static const _preset = 'shopnest_unsigned';

  // Image ka secure URL wapas deta hai, fail ho to null
  static Future<String?> uploadImage(XFile file) async {
    try {
      final bytes = await file.readAsBytes();
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/image/upload'),
      );
      request.fields['upload_preset'] = _preset;
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: file.name,
        ),
      );
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      if (response.statusCode == 200) {
        final body = jsonDecode(responseBody) as Map<String, dynamic>;
        return body['secure_url'] as String?;
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
