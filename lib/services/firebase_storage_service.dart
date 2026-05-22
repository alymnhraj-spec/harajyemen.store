import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

class FirebaseStorageService {
  static final FirebaseStorageService _instance = FirebaseStorageService._internal();
  factory FirebaseStorageService() => _instance;
  FirebaseStorageService._internal();

  final _storage = FirebaseStorage.instance;
  final _uuid = const Uuid();

  Future<String> uploadImage(XFile xfile) async {
    final ext = _getExtension(xfile.name, xfile.mimeType);
    final key = 'posts/${_uuid.v4()}.$ext';
    final ref = _storage.ref().child(key);

    final bytes = await xfile.readAsBytes();
    final metadata = SettableMetadata(contentType: 'image/jpeg');

    await ref.putData(bytes, metadata).timeout(const Duration(seconds: 60));
    return await ref.getDownloadURL();
  }

  Future<List<String>> uploadImages(List<XFile> images) async {
    final urls = <String>[];
    for (final image in images.take(6)) {
      final url = await uploadImage(image);
      urls.add(url);
    }
    return urls;
  }

  Future<void> deleteImage(String url) async {
    try {
      await _storage.refFromURL(url).delete();
    } catch (_) {}
  }

  String _getExtension(String name, String? mime) {
    if (mime == 'image/png') return 'png';
    if (mime == 'image/webp') return 'webp';
    final parts = name.split('.');
    if (parts.length > 1) return parts.last.toLowerCase();
    return 'jpg';
  }
}
