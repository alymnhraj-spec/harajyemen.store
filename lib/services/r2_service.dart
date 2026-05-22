import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'notification_secrets.dart';

class R2Service {
  static final R2Service _instance = R2Service._internal();
  factory R2Service() => _instance;
  R2Service._internal();

  static const _accessKeyId     = NotificationSecrets.r2AccessKeyId;
  static const _secretAccessKey = NotificationSecrets.r2SecretAccessKey;
  static const _bucket          = 'haraj-yemen';
  static const _endpoint        = 'https://8511980a3826f782ba87ff65ac609922.r2.cloudflarestorage.com';
  static const _publicUrl       = 'https://pub-bce8f2e609b447c8a647dc885a8e9c85.r2.dev';
  static const _region          = 'auto';
  static const _service         = 's3';

  final _uuid = const Uuid();

  // رفع صورة والحصول على الرابط العام
  Future<String> uploadImage(XFile xfile) async {
    final bytes = await xfile.readAsBytes();
    final ext = _getExtension(xfile.name, xfile.mimeType);
    final key = 'posts/${_uuid.v4()}.$ext';
    await _putObject(key: key, bytes: bytes, contentType: 'image/jpeg');
    return '$_publicUrl/$key';
  }

  // رفع object إلى R2 مع توقيع AWS Signature V4
  Future<void> _putObject({
    required String key,
    required Uint8List bytes,
    required String contentType,
  }) async {
    final now = DateTime.now().toUtc();
    final dateStamp  = _dateStamp(now);   // YYYYMMDD
    final amzDate    = _amzDate(now);     // YYYYMMDDTHHMMSSZ

    final payloadHash = sha256.convert(bytes).toString();

    final host = '${_endpoint.replaceFirst('https://', '')}';

    final canonicalHeaders =
        'content-type:$contentType\n'
        'host:$host\n'
        'x-amz-content-sha256:$payloadHash\n'
        'x-amz-date:$amzDate\n';

    const signedHeaders = 'content-type;host;x-amz-content-sha256;x-amz-date';

    final canonicalRequest =
        'PUT\n'
        '/$_bucket/$key\n'
        '\n'
        '$canonicalHeaders\n'
        '$signedHeaders\n'
        '$payloadHash';

    final credentialScope = '$dateStamp/$_region/$_service/aws4_request';
    final stringToSign =
        'AWS4-HMAC-SHA256\n'
        '$amzDate\n'
        '$credentialScope\n'
        '${sha256.convert(utf8.encode(canonicalRequest))}';

    final signingKey = _signingKey(dateStamp);
    final signature  = Hmac(sha256, signingKey)
        .convert(utf8.encode(stringToSign))
        .toString();

    final authorization =
        'AWS4-HMAC-SHA256 '
        'Credential=$_accessKeyId/$credentialScope, '
        'SignedHeaders=$signedHeaders, '
        'Signature=$signature';

    final uri = Uri.parse('$_endpoint/$_bucket/$key');

    final response = await http.put(
      uri,
      headers: {
        'Content-Type':          contentType,
        'x-amz-date':            amzDate,
        'x-amz-content-sha256':  payloadHash,
        'Authorization':         authorization,
        'Content-Length':        '${bytes.length}',
      },
      body: bytes,
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('R2 upload failed (${response.statusCode}): ${response.body}');
    }
  }

  // ====== مساعدات التوقيع ======

  List<int> _signingKey(String dateStamp) {
    final kDate    = _hmac(utf8.encode('AWS4$_secretAccessKey'), dateStamp);
    final kRegion  = _hmac(kDate, _region);
    final kService = _hmac(kRegion, _service);
    return _hmac(kService, 'aws4_request');
  }

  List<int> _hmac(List<int> key, String data) =>
      Hmac(sha256, key).convert(utf8.encode(data)).bytes;

  String _dateStamp(DateTime dt) =>
      '${dt.year.toString().padLeft(4, '0')}'
      '${dt.month.toString().padLeft(2, '0')}'
      '${dt.day.toString().padLeft(2, '0')}';

  String _amzDate(DateTime dt) =>
      '${_dateStamp(dt)}T'
      '${dt.hour.toString().padLeft(2, '0')}'
      '${dt.minute.toString().padLeft(2, '0')}'
      '${dt.second.toString().padLeft(2, '0')}Z';

  String _getExtension(String name, String? mime) {
    if (mime == 'image/png') return 'png';
    if (mime == 'image/webp') return 'webp';
    final parts = name.split('.');
    if (parts.length > 1) return parts.last.toLowerCase();
    return 'jpg';
  }
}
