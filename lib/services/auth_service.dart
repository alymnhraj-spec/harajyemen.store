import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'notification_secrets.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  static const String demoOtpCode = '198700';
  static const String _demoVerificationId = 'demo-verification-id';

  // أرقام اختبار تعمل بدون SMS (رمزها: 198700)
  static const List<String> _testPhones = [
    '+967771074445',
    '+967770978691',
    '+967777446640',
    '+967777704518',
    '+967770583068',
    '+966538394704',
  ];

  FirebaseAuth get _auth => FirebaseAuth.instance;
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  String? _verificationId;
  int? _resendToken;

  User? get currentUser => _auth.currentUser;
  bool get isLoggedIn => _auth.currentUser != null;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // إرسال رمز OTP
  Future<PhoneVerificationResult> sendOtp({
    required String phoneNumber,
    required Function(String error) onError,
    bool useDemoCode = false,
  }) async {
    if (useDemoCode) {
      _verificationId = _demoVerificationId;
      return PhoneVerificationResult.demoCodeSent(_demoVerificationId);
    }

    // أرقام الاختبار تعمل بدون Firebase
    String _norm(String s) => s.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    final normalizedPhone = _norm(phoneNumber);
    if (_testPhones.any((t) => _norm(t) == normalizedPhone)) {
      _verificationId = _demoVerificationId;
      // حفظ رقم الهاتف لاستخدامه في التعرف على المالك
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_phone', normalizedPhone);
      return PhoneVerificationResult.demoCodeSent(_demoVerificationId);
    }

    try {
      final completer = Completer<PhoneVerificationResult>();

      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) {
          if (!completer.isCompleted) {
            completer.complete(PhoneVerificationResult.autoVerified(credential));
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          final errorMsg = _getArabicError(e.code);
          onError(errorMsg);
          if (!completer.isCompleted) completer.completeError(errorMsg);
        },
        codeSent: (String verificationId, int? resendToken) {
          _verificationId = verificationId;
          _resendToken = resendToken;
          if (!completer.isCompleted) {
            completer.complete(PhoneVerificationResult.codeSent(verificationId));
          }
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
        forceResendingToken: _resendToken,
        timeout: const Duration(seconds: 60),
      );

      return await completer.future;
    } catch (e) {
      throw Exception('فشل إرسال رمز التحقق: ${e.toString()}');
    }
  }

  // التحقق من رمز OTP وتسجيل الدخول
  Future<UserCredential?> verifyOtp({
    required String otpCode,
    required String? verificationId,
  }) async {
    try {
      final id = verificationId ?? _verificationId;
      if (id == null) throw Exception('انتهت صلاحية الجلسة، أعد المحاولة');

      // وضع تجريبي: حفظ الجلسة محلياً بدون Firebase
      if (id == _demoVerificationId) {
        if (otpCode.trim() != demoOtpCode) {
          throw Exception(_getArabicError('invalid-verification-code'));
        }
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('is_demo_user', true);
        await prefs.setString('demo_uid', 'demo_user_local');
        return null; // لا يوجد UserCredential في وضع تجريبي
      }

      final credential = PhoneAuthProvider.credential(
        verificationId: id,
        smsCode: otpCode.trim(),
      );

      final result = await _auth.signInWithCredential(credential);
      // حفظ الملف الشخصي - لا يوقف الدخول إذا فشل
      try { await _saveUserProfile(result.user!); } catch (_) {}
      return result;
    } on FirebaseAuthException catch (e) {
      throw Exception(_getArabicError(e.code));
    }
  }

  // هل المستخدم في وضع تجريبي (الويب لا يدعم هذا الوضع)
  static Future<bool> isDemoUser() async {
    if (kIsWeb) return false;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('is_demo_user') ?? false;
  }

  // UID للمستخدم التجريبي
  static Future<String> getDemoUid() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('demo_uid') ?? 'demo_user_local';
  }

  // التحقق التلقائي (للـ Android)
  Future<UserCredential?> verifyWithCredential(PhoneAuthCredential credential) async {
    try {
      final result = await _auth.signInWithCredential(credential);
      try { await _saveUserProfile(result.user!); } catch (_) {}
      return result;
    } on FirebaseAuthException catch (e) {
      throw Exception(_getArabicError(e.code));
    }
  }

  static const _adminEmail = 'mohamm3dalfeel@gmail.com';

  // حفظ بيانات المستخدم في Firestore
  Future<void> _saveUserProfile(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_phone', user.phoneNumber ?? '');

    final docRef = _db.collection('users').doc(user.uid);

    // للمستخدم الجديد فقط: نعيّن is_admin للإيميل الرئيسي
    final doc = await docRef.get();
    final isNewUser = !doc.exists;
    final isMainAdmin = user.email == _adminEmail || user.phoneNumber == _adminEmail;

    final data = <String, dynamic>{
      'uid': user.uid,
      'phone': user.phoneNumber ?? '',
      'is_active': true,
      'last_login': FieldValue.serverTimestamp(),
    };
    // نضع is_admin فقط عند أول تسجيل (لا نعيد كتابتها لاحقاً)
    if (isNewUser) data['is_admin'] = isMainAdmin;

    await docRef.set(data, SetOptions(merge: true));

    // حفظ created_at فقط إذا لم يكن موجوداً
    if (doc.data()?['created_at'] == null) {
      await docRef.update({'created_at': FieldValue.serverTimestamp()});
    }
  }

  // تحديث اسم المستخدم
  Future<void> updateUserName(String name) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _db.collection('users').doc(user.uid).update({'name': name});
    await user.updateDisplayName(name);
  }

  // الحصول على بيانات المستخدم
  Future<Map<String, dynamic>?> getUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final doc = await _db.collection('users').doc(user.uid).get();
    return doc.data();
  }

  // تسجيل الدخول بالإيميل
  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      try { await _saveEmailUserProfile(result.user!); } catch (_) {}
      return result;
    } on FirebaseAuthException catch (e) {
      throw Exception(_getArabicEmailError(e.code));
    }
  }

  // إنشاء حساب بالإيميل — يُعاد حساب مؤقت ويُحذف إذا لم يتحقق المستخدم
  Future<UserCredential> registerWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final result = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      try { await _saveEmailUserProfile(result.user!); } catch (_) {}
      await _auth.signOut();
      return result;
    } on FirebaseAuthException catch (e) {
      throw Exception(_getArabicEmailError(e.code));
    }
  }

  // إرسال OTP للتسجيل — يحفظ في Firestore
  Future<String> createRegistrationOtp(String email) async {
    final otp = _generateOtp();
    await _db.collection('email_verifications').doc(email.trim()).set({
      'otp': otp,
      'email': email.trim(),
      'createdAt': FieldValue.serverTimestamp(),
      'expiresAt': DateTime.now().add(const Duration(minutes: 10)).toIso8601String(),
      'verified': false,
    });
    return otp;
  }

  // التحقق من OTP التسجيل
  Future<void> verifyRegistrationOtp(String email, String otp) async {
    final doc = await _db.collection('email_verifications').doc(email.trim()).get();
    if (!doc.exists) throw Exception('لم يتم إرسال الرمز، أعد المحاولة');
    final data = doc.data()!;
    if (data['used'] == true) throw Exception('تم استخدام هذا الرمز من قبل');
    final expiresAt = DateTime.parse(data['expiresAt']);
    if (DateTime.now().isAfter(expiresAt)) throw Exception('انتهت صلاحية الرمز، أعد الإرسال');
    if (data['otp'] != otp.trim()) throw Exception('رمز التحقق غير صحيح');
    await doc.reference.update({'used': true, 'verified': true});
  }

  Future<void> _saveEmailUserProfile(User user) async {
    // حذف أي سجلات مكررة بنفس الإيميل (UIDs مختلفة = حسابات قديمة محذوفة)
    final duplicates = await _db.collection('users')
        .where('email', isEqualTo: user.email)
        .get();
    for (final doc in duplicates.docs) {
      if (doc.id != user.uid) {
        await doc.reference.delete();
      }
    }

    final docRef = _db.collection('users').doc(user.uid);
    final doc = await docRef.get();
    final isNewUser = !doc.exists;

    final data = <String, dynamic>{
      'uid': user.uid,
      'email': user.email ?? '',
      'is_active': true,
      'last_login': FieldValue.serverTimestamp(),
    };
    final isAdminEmail = user.email == _adminEmail;
    if (isNewUser) data['is_admin'] = isAdminEmail;

    await docRef.set(data, SetOptions(merge: true));
    if (doc.data()?['created_at'] == null) {
      await docRef.update({'created_at': FieldValue.serverTimestamp()});
    }
  }

  // توليد رمز OTP عشوائي 6 أرقام
  String _generateOtp() {
    final random = Random.secure();
    return (100000 + random.nextInt(900000)).toString();
  }

  // حفظ OTP في Firestore
  Future<String> createPasswordResetOtp(String email) async {
    final otp = _generateOtp();
    await _db.collection('password_resets').doc(email.trim()).set({
      'otp': otp,
      'email': email.trim(),
      'createdAt': FieldValue.serverTimestamp(),
      'expiresAt': DateTime.now().add(const Duration(minutes: 10)).toIso8601String(),
      'used': false,
    });
    return otp;
  }

  // التحقق من OTP
  Future<void> verifyPasswordResetOtp(String email, String otp) async {
    final doc = await _db.collection('password_resets').doc(email.trim()).get();
    if (!doc.exists) throw Exception('لم يتم طلب إعادة التعيين، أعد المحاولة');

    final data = doc.data()!;
    if (data['used'] == true) throw Exception('تم استخدام هذا الرمز من قبل');

    final expiresAt = DateTime.parse(data['expiresAt']);
    if (DateTime.now().isAfter(expiresAt)) throw Exception('انتهت صلاحية الرمز، أعد الإرسال');

    if (data['otp'] != otp.trim()) throw Exception('رمز التحقق غير صحيح');

    await doc.reference.update({'used': true, 'verified': true});
  }

  // بيانات حساب الخدمة لـ Firebase Admin
  static const _serviceClientEmail =
      'firebase-adminsdk-fbsvc@haraj-yemen-app.iam.gserviceaccount.com';
  static const _serviceProjectId = 'haraj-yemen-app';
  static const _tokenUri = 'https://oauth2.googleapis.com/token';

  String? _adminToken;
  DateTime? _adminTokenExpiry;

  Future<String> _getAdminAccessToken() async {
    if (_adminToken != null &&
        _adminTokenExpiry != null &&
        DateTime.now().isBefore(_adminTokenExpiry!)) {
      return _adminToken!;
    }
    final now = DateTime.now();
    final jwt = JWT({
      'iss': _serviceClientEmail,
      'scope': 'https://www.googleapis.com/auth/identitytoolkit https://www.googleapis.com/auth/firebase',
      'aud': _tokenUri,
      'iat': now.millisecondsSinceEpoch ~/ 1000,
      'exp': (now.millisecondsSinceEpoch ~/ 1000) + 3600,
    });
    final signed = jwt.sign(RSAPrivateKey(NotificationSecrets.fcmPrivateKey), algorithm: JWTAlgorithm.RS256);
    final response = await http.post(
      Uri.parse(_tokenUri),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'grant_type': 'urn:ietf:params:oauth:grant-type:jwt-bearer',
        'assertion': signed,
      },
    );
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    _adminToken = data['access_token'] as String;
    _adminTokenExpiry = now.add(Duration(seconds: (data['expires_in'] as int) - 60));
    return _adminToken!;
  }

  // تغيير كلمة المرور مباشرة عبر Firebase Admin REST API
  Future<bool> changePasswordAfterOtp(String email, String newPassword) async {
    try {
      final token = await _getAdminAccessToken();

      // البحث عن UID بالإيميل
      final lookupRes = await http.post(
        Uri.parse('https://identitytoolkit.googleapis.com/v1/projects/$_serviceProjectId/accounts:lookup'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'email': email.trim()}),
      );
      final lookupData = jsonDecode(lookupRes.body) as Map<String, dynamic>;
      final users = lookupData['users'] as List?;
      if (users == null || users.isEmpty) return false;
      final uid = users[0]['localId'] as String;

      // تغيير كلمة المرور
      final updateRes = await http.post(
        Uri.parse('https://identitytoolkit.googleapis.com/v1/projects/$_serviceProjectId/accounts:update'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'localId': uid, 'password': newPassword}),
      );
      return updateRes.statusCode == 200;
    } catch (e) {
      // ignore: avoid_print
      print('=== changePasswordAfterOtp error: $e ===');
    }
    return false;
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw Exception(_getArabicEmailError(e.code));
    }
  }

  String _getArabicEmailError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'لا يوجد حساب بهذا البريد الإلكتروني';
      case 'wrong-password':
        return 'كلمة المرور غير صحيحة';
      case 'email-already-in-use':
        return 'البريد الإلكتروني مستخدم بالفعل';
      case 'invalid-email':
        return 'صيغة البريد الإلكتروني غير صحيحة';
      case 'weak-password':
        return 'كلمة المرور ضعيفة، يجب أن تكون 6 أحرف على الأقل';
      case 'network-request-failed':
        return 'فشل الاتصال بالإنترنت';
      case 'too-many-requests':
        return 'طلبات كثيرة جداً، حاول بعد قليل';
      case 'invalid-credential':
        return 'البريد الإلكتروني أو كلمة المرور غير صحيحة';
      default:
        return 'خطأ: $code';
    }
  }

  // تسجيل الخروج
  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    try { await _auth.signOut(); } catch (_) {}
  }

  // رسائل خطأ بالعربية
  String _getArabicError(String code) {
    switch (code) {
      case 'invalid-phone-number':
        return 'رقم الهاتف غير صحيح';
      case 'too-many-requests':
        return 'طلبات كثيرة جداً، حاول بعد قليل';
      case 'invalid-verification-code':
        return 'رمز التحقق غير صحيح';
      case 'session-expired':
        return 'انتهت صلاحية الرمز، أعد الإرسال';
      case 'quota-exceeded':
        return 'تجاوزت الحد المسموح، حاول لاحقاً';
      case 'network-request-failed':
        return 'فشل الاتصال بالإنترنت';
      case 'missing-phone-number':
        return 'يرجى إدخال رقم الهاتف';
      default:
        return 'خطأ: $code';
    }
  }
}

// نتيجة التحقق من الهاتف
class PhoneVerificationResult {
  final bool isAutoVerified;
  final bool isCodeSent;
  final bool isDemoMode;
  final String? verificationId;
  final PhoneAuthCredential? credential;

  PhoneVerificationResult._({
    required this.isAutoVerified,
    required this.isCodeSent,
    required this.isDemoMode,
    this.verificationId,
    this.credential,
  });

  factory PhoneVerificationResult.codeSent(String verificationId) {
    return PhoneVerificationResult._(
      isAutoVerified: false,
      isCodeSent: true,
      isDemoMode: false,
      verificationId: verificationId,
    );
  }

  factory PhoneVerificationResult.demoCodeSent(String verificationId) {
    return PhoneVerificationResult._(
      isAutoVerified: false,
      isCodeSent: true,
      isDemoMode: true,
      verificationId: verificationId,
    );
  }

  factory PhoneVerificationResult.autoVerified(PhoneAuthCredential credential) {
    return PhoneVerificationResult._(
      isAutoVerified: true,
      isCodeSent: false,
      isDemoMode: false,
      credential: credential,
    );
  }
}

