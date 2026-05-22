import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'dart:convert';

class CloudinaryService {
  static const String _cloudName = 'dh4jyyirw';
  static const String _uploadPreset = 'haraj_yemen';
  static const String _uploadUrl = 'https://api.cloudinary.com/v1_1/$_cloudName/image/upload';

  Future<String> uploadImage(XFile xfile) async {
    for (int attempt = 1; attempt <= 3; attempt++) {
      try {
        final bytes = await xfile.readAsBytes();
        final request = http.MultipartRequest('POST', Uri.parse(_uploadUrl));
        request.fields['upload_preset'] = _uploadPreset;
        request.fields['folder'] = 'posts';
        request.files.add(http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: 'image_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ));

        final response = await request.send().timeout(
          const Duration(seconds: 40),
          onTimeout: () => throw Exception('timeout'),
        );
        final body = await response.stream.bytesToString();

        if (response.statusCode != 200) {
          final error = jsonDecode(body);
          throw Exception('فشل رفع الصورة: ${error['error']?['message'] ?? response.statusCode}');
        }

        final json = jsonDecode(body);
        return json['secure_url'] as String;
      } catch (e) {
        if (attempt == 3) rethrow;
        await Future.delayed(const Duration(seconds: 2));
      }
    }
    throw Exception('فشل رفع الصورة بعد عدة محاولات');
  }

  Future<List<String>> uploadImages(List<XFile> images) async {
    final urls = <String>[];
    for (final image in images.take(6)) {
      final url = await uploadImage(image);
      urls.add(url);
    }
    return urls;
  }
}
