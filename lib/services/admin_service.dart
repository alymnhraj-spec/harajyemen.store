import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdminService {
  static final AdminService _instance = AdminService._internal();
  factory AdminService() => _instance;
  AdminService._internal();

  FirebaseFirestore get _db => FirebaseFirestore.instance;
  FirebaseAuth get _auth => FirebaseAuth.instance;

  // قائمة إيميلات الأدمن الثابتة
  static const List<String> _adminEmails = [
    'mohamm3dalfeel@gmail.com',
    'kog24kog@gmail.com',
  ];

  bool _isAdminUser(User user) {
    if (_adminEmails.contains(user.email)) return true;
    return false;
  }

  // التحقق هل المستخدم الحالي أدمن
  Future<bool> isAdmin() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    if (_isAdminUser(user)) return true;
    final doc = await _db.collection('users').doc(user.uid).get();
    return (doc.data()?['is_admin'] as bool?) ?? false;
  }

  // Stream لحالة الأدمن
  Stream<bool> isAdminStream() async* {
    final user = _auth.currentUser;
    if (user != null) {
      if (_isAdminUser(user)) { yield true; return; }
      yield* _db.collection('users').doc(user.uid)
          .snapshots()
          .map((d) => (d.data()?['is_admin'] as bool?) ?? false);
      return;
    }
    // مستخدم Demo: تحقق بالهاتف
    try {
      final prefs = await SharedPreferences.getInstance();
      final phone = prefs.getString('user_phone') ?? '';
      if (phone.isEmpty) { yield false; return; }
      final snap = await _db.collection('users').where('phone', isEqualTo: phone).limit(1).get();
      yield snap.docs.isNotEmpty && ((snap.docs.first.data()['is_admin'] as bool?) ?? false);
    } catch (_) { yield false; }
  }

  // جلب كل الإعلانات
  Future<List<Map<String, dynamic>>> getAllPostsOnce() async {
    final snap = await _db.collection('posts').limit(500).get();
    final list = snap.docs
        .map((d) {
          final data = d.data();
          data['id'] = d.id;
          return data;
        })
        .where((p) => p['status'] != 'deleted')
        .toList();
    list.sort((a, b) {
      final aTs = a['created_at'];
      final bTs = b['created_at'];
      if (aTs == null && bTs == null) return 0;
      if (aTs == null) return 1;
      if (bTs == null) return -1;
      return (bTs as Timestamp).compareTo(aTs as Timestamp);
    });
    return list;
  }

  // للتوافق مع الكود القديم
  Stream<List<Map<String, dynamic>>> getAllPosts() {
    return Stream.fromFuture(getAllPostsOnce());
  }

  // تفعيل/تعطيل قسم الإعلانات المميزة
  Future<void> setFeaturedSectionEnabled(bool enabled) async {
    await _db.collection('settings').doc('featured').set({'enabled': enabled});
  }

  // Stream لحالة تفعيل القسم
  Stream<bool> isFeaturedSectionEnabled() {
    return _db
        .collection('settings')
        .doc('featured')
        .snapshots()
        .map((doc) => (doc.data()?['enabled'] as bool?) ?? false);
  }

  // ===================== ثيم التطبيق (الألوان) =====================
  // يُقرأ من جميع المستخدمين ويُطبَّق عالمياً؛ يُكتب من الأدمن فقط.
  Stream<Map<String, dynamic>> themeStream() {
    return _db
        .collection('settings')
        .doc('theme')
        .snapshots()
        .map((doc) => doc.data() ?? <String, dynamic>{});
  }

  Future<void> saveTheme({
    required String primaryHex,
    required String secondaryHex,
  }) async {
    await _db.collection('settings').doc('theme').set({
      'primary': primaryHex,
      'secondary': secondaryHex,
      'updated_at': FieldValue.serverTimestamp(),
      'updated_by': _auth.currentUser?.uid,
    });
  }

  Future<void> resetTheme() async {
    await _db.collection('settings').doc('theme').delete();
  }

  // ===================== إعدادات البريد (Gmail SMTP) =====================
  // تُستخدم لإرسال رموز التحقق من بريد مُعدّ من لوحة الإدارة (التطبيق + الموقع).
  Stream<Map<String, dynamic>> emailConfigStream() {
    return _db
        .collection('settings')
        .doc('email')
        .snapshots()
        .map((doc) => doc.data() ?? <String, dynamic>{});
  }

  Future<Map<String, dynamic>?> getEmailConfig() async {
    final doc = await _db.collection('settings').doc('email').get();
    return doc.data();
  }

  Future<void> saveEmailConfig({
    required String senderEmail,
    required String appPassword,
    String senderName = 'حراج اليمن',
  }) async {
    await _db.collection('settings').doc('email').set({
      'sender_email': senderEmail.trim(),
      // كلمات مرور تطبيقات Google تُلصق غالباً بمسافات — نزيلها
      'app_password': appPassword.replaceAll(RegExp(r'\s'), ''),
      'sender_name': senderName.trim().isEmpty ? 'حراج اليمن' : senderName.trim(),
      'updated_at': FieldValue.serverTimestamp(),
      'updated_by': _auth.currentUser?.uid,
    });
  }

  // جلب الإعلانات المميزة
  Stream<List<Map<String, dynamic>>> getFeaturedPosts() {
    return _db
        .collection('posts')
        .orderBy('created_at', descending: true)
        .limit(100)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) {
              final data = d.data();
              data['id'] = d.id;
              return data;
            })
            .where((p) =>
                (p['is_featured'] as bool?) == true &&
                p['status'] == 'active')
            .take(4)
            .toList());
  }

  // تمييز إعلان
  Future<void> featurePost(String postId) async {
    await _db.collection('posts').doc(postId).update({
      'is_featured': true,
      'featured_at': FieldValue.serverTimestamp(),
      'featured_by': _auth.currentUser?.uid,
    });
  }

  // إلغاء تمييز إعلان
  Future<void> unfeaturePost(String postId) async {
    await _db.collection('posts').doc(postId).update({
      'is_featured': false,
      'featured_at': null,
      'featured_by': null,
    });
  }

  // حذف إعلان كأدمن
  Future<void> deletePost(String postId) async {
    await _db.collection('posts').doc(postId).update({
      'status': 'deleted',
      'deleted_by_admin': true,
      'deleted_at': FieldValue.serverTimestamp(),
    });
  }

  // جلب كل المستخدمين
  Stream<List<Map<String, dynamic>>> getAllUsers() {
    return _db
        .collection('users')
        .snapshots()
        .map((snap) {
          final list = snap.docs.map((d) {
            final data = d.data();
            data['uid'] = d.id;
            return data;
          }).toList();
          // ترتيب محلي حتى لا نحتاج index مركب
          list.sort((a, b) {
            final aTs = a['created_at'];
            final bTs = b['created_at'];
            if (aTs == null && bTs == null) return 0;
            if (aTs == null) return 1;
            if (bTs == null) return -1;
            final aTime = (aTs as Timestamp).toDate();
            final bTime = (bTs as Timestamp).toDate();
            return bTime.compareTo(aTime);
          });
          return list;
        });
  }

  // حظر مستخدم
  Future<void> banUser(String uid) async {
    await _db.collection('users').doc(uid).update({
      'is_banned': true,
      'ban_reason': 'مخالفة شروط الاستخدام',
      'banned_at': FieldValue.serverTimestamp(),
      'banned_by': _auth.currentUser?.uid,
    });
  }

  // رفع الحظر
  Future<void> unbanUser(String uid) async {
    await _db.collection('users').doc(uid).update({
      'is_banned': false,
      'ban_reason': null,
      'banned_at': null,
    });
  }

  // جلب قائمة الأدمن
  Stream<List<Map<String, dynamic>>> getAdmins() {
    return _db
        .collection('users')
        .where('is_admin', isEqualTo: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) {
              final data = d.data();
              data['uid'] = d.id;
              return data;
            }).toList());
  }

  // إضافة أدمن عن طريق البريد الإلكتروني
  Future<String> addAdmin(String email) async {
    final normalizedEmail = email.trim().toLowerCase();

    // بحث في users collection عن طريق الإيميل
    final usersSnap = await _db
        .collection('users')
        .where('email', isEqualTo: normalizedEmail)
        .limit(1)
        .get();

    if (usersSnap.docs.isNotEmpty) {
      await usersSnap.docs.first.reference.update({'is_admin': true});
      return 'تم تعيين الأدمن بنجاح';
    }

    // بحث بـ UID من Firebase Auth عبر الإيميل في المستندات
    final allUsersSnap = await _db.collection('users').get();
    for (final doc in allUsersSnap.docs) {
      final docEmail = (doc.data()['email'] as String? ?? '').toLowerCase();
      if (docEmail == normalizedEmail) {
        await doc.reference.update({'is_admin': true});
        return 'تم تعيين الأدمن بنجاح';
      }
    }

    return 'لم يتم العثور على مستخدم بهذا البريد الإلكتروني';
  }

  // إزالة أدمن
  Future<void> removeAdmin(String uid) async {
    await _db.collection('users').doc(uid).update({'is_admin': false});
  }

  // التحقق هل المستخدم محظور
  Future<bool> isCurrentUserBanned() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return false;
    final doc = await _db.collection('users').doc(uid).get();
    return (doc.data()?['is_banned'] as bool?) ?? false;
  }
}
