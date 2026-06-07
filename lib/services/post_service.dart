import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/post_model.dart';
import 'auth_service.dart';
import 'r2_service.dart';

class PostService {
  static final PostService _instance = PostService._internal();
  factory PostService() => _instance;
  PostService._internal();

  FirebaseFirestore get _db => FirebaseFirestore.instance;
  final _r2Storage = R2Service();
  FirebaseAuth get _auth => FirebaseAuth.instance;
  final Uuid _uuid = const Uuid();

  CollectionReference get _posts => _db.collection('posts');

  // ضغط صورة واحدة (موبايل + ويب)
  Future<XFile?> compressImage(XFile xfile) async {
    try {
      if (kIsWeb) {
        // ضغط على الويب عبر البايتات
        final bytes = await xfile.readAsBytes();
        final compressed = await FlutterImageCompress.compressWithList(
          bytes,
          quality: 60,
          minWidth: 700,
          minHeight: 500,
          format: CompressFormat.jpeg,
        );
        // إذا كان الضغط فعلاً قلل الحجم
        if (compressed.length < bytes.length) {
          return XFile.fromData(compressed, mimeType: 'image/jpeg');
        }
        return xfile;
      }
      // موبايل: ضغط مع حفظ ملف
      final dir = await getTemporaryDirectory();
      final targetPath = '${dir.path}/${_uuid.v4()}.jpg';
      final result = await FlutterImageCompress.compressAndGetFile(
        xfile.path,
        targetPath,
        quality: 60,
        minWidth: 700,
        minHeight: 500,
        format: CompressFormat.jpeg,
      );
      return result;
    } catch (_) {
      return xfile;
    }
  }

  // رفع صورة إلى R2
  Future<String> uploadImage(XFile xfile, String postId) async {
    final compressed = await compressImage(xfile);
    return await _r2Storage.uploadImage(compressed ?? xfile);
  }

  // رفع مجموعة صور (6 كحد أقصى)
  Future<List<String>> uploadImages(List<XFile> images, String postId) async {
    final urls = <String>[];
    for (final image in images.take(6)) {
      final url = await uploadImage(image, postId);
      urls.add(url);
    }
    return urls;
  }

  // الحصول على اسم المستخدم
  Future<String> _getUserName() async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        final doc = await _db.collection('users').doc(user.uid).get();
        final name = doc.data()?['name'] ?? '';
        if (name.isNotEmpty) return name;
      } catch (_) {}
    }
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('username') ?? '';
  }

  // الحصول على رقم هاتف المستخدم (من Firebase أو SharedPreferences)
  Future<String> _getUserPhone() async {
    final user = _auth.currentUser;
    if (user?.phoneNumber != null && user!.phoneNumber!.isNotEmpty) {
      return user.phoneNumber!;
    }
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_phone') ?? '';
  }

  // التحقق من حد 3 إعلانات يومياً
  Future<void> _checkDailyPostLimit(String uid) async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final snap = await _posts
        .where('user_id', isEqualTo: uid)
        .where('created_at', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .get();
    final todayCount = snap.docs.where((d) => d['status'] != 'deleted').length;
    if (todayCount >= 3) {
      throw Exception('لقد تجاوزت الحد المسموح به (3 إعلانات يومياً). حاول غداً.');
    }
  }

  // إضافة إعلان جديد
  Future<String> addPost({
    required String title,
    required String description,
    required List<XFile> images,
    required String governorateId,
    required String governorateName,
    required PriceType priceType,
    required String contactPhone,
    double? price,
    String? category,
    double? latitude,
    double? longitude,
    void Function(String)? onProgress,
  }) async {
    final user = _auth.currentUser;
    final isDemo = await AuthService.isDemoUser();
    if (user == null && !isDemo) throw Exception('يجب تسجيل الدخول أولاً');
    final uid = user?.uid ?? await AuthService.getDemoUid();

    // التحقق من حد 3 إعلانات في اليوم
    await _checkDailyPostLimit(uid);

    final postId = _uuid.v4();
    final userPhone = contactPhone.isNotEmpty ? contactPhone : await _getUserPhone();
    final userName = await _getUserName();

    // رفع الصور إلى Cloudinary
    final imageUrls = <String>[];
    final totalImages = images.take(6).length;
    for (int i = 0; i < totalImages; i++) {
      onProgress?.call('جاري رفع الصورة ${i + 1} من $totalImages...');
      try {
        final url = await uploadImage(images[i], postId);
        imageUrls.add(url);
      } catch (_) {
        // تجاهل الصورة التي فشل رفعها والمتابعة
      }
    }
    onProgress?.call('جاري حفظ الإعلان...');

    final now = DateTime.now();
    final expiresAt = now.add(const Duration(days: 90)); // 3 أشهر

    // حفظ الإعلان في Firestore
    final post = PostModel(
      id: postId,
      title: title,
      description: description,
      images: imageUrls,
      governorateId: governorateId,
      governorateName: governorateName,
      userId: uid,
      userPhone: userPhone,
      userName: userName.isNotEmpty ? userName : null,
      priceType: priceType,
      price: price,
      category: category,
      latitude: latitude,
      longitude: longitude,
      createdAt: now,
      expiresAt: expiresAt,
    );

    // Firestore يحفظ محلياً أولاً ثم يزامن - نعطيه 10 ثواني وإلا نكمل
    await _posts.doc(postId).set(post.toFirestore())
        .timeout(const Duration(seconds: 10), onTimeout: () {});
    return postId;
  }

  // الحصول على الإعلانات مع فلتر المحافظة
  Stream<List<PostModel>> getPosts({
    String? governorateId,
    String? category,
    int limit = 20,
    DocumentSnapshot? lastDoc,
  }) {
    Query query = _posts
        .orderBy('created_at', descending: true)
        .limit(limit * 3); // نجلب أكثر لأننا سنفلتر محلياً

    if (lastDoc != null) {
      query = query.startAfterDocument(lastDoc);
    }

    final now = DateTime.now();
    return query.snapshots().map((snapshot) {
      var posts = snapshot.docs
          .map((doc) => PostModel.fromFirestore(doc))
          .where((p) =>
              p.status == PostStatus.active &&
              (p.expiresAt == null || p.expiresAt!.isAfter(now)))
          .toList();

      if (governorateId != null && governorateId.isNotEmpty) {
        posts = posts.where((p) => p.governorateId == governorateId).toList();
      }

      if (category != null && category.isNotEmpty) {
        posts = posts.where((p) => p.category == category).toList();
      }

      return posts.take(limit).toList();
    });
  }

  // الحصول على إعلانات المستخدم
  Stream<List<PostModel>> getUserPosts(String userId) {
    return _posts
        .where('user_id', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs
              .map((doc) => PostModel.fromFirestore(doc))
              .where((p) => p.status == PostStatus.active)
              .toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }

  // الحصول على إعلان واحد
  Future<PostModel?> getPost(String postId) async {
    final doc = await _posts.doc(postId).get();
    if (!doc.exists) return null;
    return PostModel.fromFirestore(doc);
  }

  // زيادة عداد المشاهدات
  Future<void> incrementViewCount(String postId) async {
    await _posts.doc(postId).update({
      'view_count': FieldValue.increment(1),
    });
  }

  // حذف إعلان (soft delete)
  Future<void> deletePost(String postId) async {
    await _posts.doc(postId).update({'status': 'deleted'});
  }

  // تحديد الإعلان كمباع
  Future<void> markAsSold(String postId) async {
    await _posts.doc(postId).update({'status': 'sold'});
  }

  // تعديل إعلان موجود
  Future<void> updatePost({
    required String postId,
    required String title,
    required String description,
    required String governorateId,
    required String governorateName,
    required PriceType priceType,
    required String contactPhone,
    double? price,
    String? category,
    List<XFile> newImages = const [],
    List<String> existingImageUrls = const [],
    void Function(String)? onProgress,
  }) async {
    onProgress?.call('جاري حفظ التعديلات...');
    final allImageUrls = List<String>.from(existingImageUrls);
    for (int i = 0; i < newImages.take(6 - allImageUrls.length).length; i++) {
      onProgress?.call('جاري رفع الصورة ${i + 1}...');
      try {
        final url = await uploadImage(newImages[i], postId);
        allImageUrls.add(url);
      } catch (_) {}
    }
    await _posts.doc(postId).update({
      'title': title,
      'description': description,
      'governorate_id': governorateId,
      'governorate_name': governorateName,
      'price_type': priceType.name,
      'price': price,
      'category': category,
      'user_phone': contactPhone,
      'images': allImageUrls,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  // تجديد إعلان (تمديد 90 يوماً)
  Future<void> renewPost(String postId) async {
    final newExpiry = DateTime.now().add(const Duration(days: 90));
    await _posts.doc(postId).update({
      'expires_at': Timestamp.fromDate(newExpiry),
      'renewed_at': FieldValue.serverTimestamp(),
    });
  }

  // البحث في الإعلانات
  Future<List<PostModel>> searchPosts(String query) async {
    final snapshot = await _posts
        .orderBy('created_at', descending: true)
        .limit(100)
        .get();

    final now = DateTime.now();
    final all = snapshot.docs
        .map((doc) => PostModel.fromFirestore(doc))
        .where((p) => p.status == PostStatus.active && (p.expiresAt == null || p.expiresAt!.isAfter(now)))
        .toList();
    final lowerQuery = query.toLowerCase();

    return all.where((post) =>
        post.title.toLowerCase().contains(lowerQuery) ||
        post.description.toLowerCase().contains(lowerQuery) ||
        post.governorateName.toLowerCase().contains(lowerQuery)).toList();
  }
}
