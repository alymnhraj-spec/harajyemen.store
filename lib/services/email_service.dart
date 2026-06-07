import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server/gmail.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EmailService {
  static const _username = 'alymnhraj@gmail.com';
  static const _password = 'kqddesbzlmpfgcvo';
  static const _apiSecret = 'hY8j3K2mP9q';
  // ← ضع هنا رابط Google Apps Script بعد النشر
  static const _scriptUrl = 'https://script.google.com/macros/s/AKfycbxDtnKb9PtzostlKixbLo78Kk9kTMG1R93G-fzcRn5YcM-5GY_zMUr9icZb0GjhEVT1/exec';

  static Future<void> sendOtp({
    required String toEmail,
    required String otp,
    String type = 'register', // 'register' or 'reset'
  }) async {
    if (kIsWeb) {
      await _sendViaEmailJS(toEmail: toEmail, otp: otp, type: type);
    } else {
      await _sendViaSMTP(toEmail: toEmail, otp: otp, type: type);
    }
  }

  // إرسال عبر EmailJS (ويب) — يدعم CORS بشكل كامل
  static const _emailJsServiceId  = 'service_kfkovig';
  static const _emailJsTemplateId = 'template_85f38fb';
  static const _emailJsPublicKey  = 'BXp5RhyfSDHgNgCUQ';

  static Future<void> _sendViaEmailJS({
    required String toEmail,
    required String otp,
    required String type,
  }) async {
    final response = await http.post(
      Uri.parse('https://api.emailjs.com/api/v1.0/email/send'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'service_id': _emailJsServiceId,
        'template_id': _emailJsTemplateId,
        'user_id': _emailJsPublicKey,
        'template_params': {
          'email': toEmail,
          'passcode': otp,
          'time': '10 دقائق',
        },
      }),
    );
    if (response.statusCode != 200) {
      throw Exception('فشل إرسال رمز التحقق');
    }
  }

  // ===== مُرسِل قابل للتعديل من لوحة الإدارة (Firestore) مع قيم افتراضية =====
  static String? _cfgEmail;
  static String? _cfgPassword;
  static String _cfgName = 'حراج اليمن';
  static DateTime? _cfgLoadedAt;

  static String get _senderEmail => _cfgEmail ?? _username;
  static String get _senderPassword => _cfgPassword ?? _password;

  /// يُستدعى بعد حفظ إعدادات البريد من لوحة الإدارة لإعادة التحميل فوراً.
  static void clearConfigCache() => _cfgLoadedAt = null;

  static Future<void> _loadSmtpConfig() async {
    if (_cfgLoadedAt != null &&
        DateTime.now().difference(_cfgLoadedAt!).inMinutes < 5) {
      return; // كاش 5 دقائق
    }
    try {
      final doc = await FirebaseFirestore.instance
          .collection('settings')
          .doc('email')
          .get();
      final data = doc.data();
      final email = (data?['sender_email'] as String?)?.trim();
      final pass =
          (data?['app_password'] as String?)?.replaceAll(RegExp(r'\s'), '');
      if (email != null && email.isNotEmpty && pass != null && pass.isNotEmpty) {
        _cfgEmail = email;
        _cfgPassword = pass;
        final name = (data?['sender_name'] as String?)?.trim();
        _cfgName = (name != null && name.isNotEmpty) ? name : 'حراج اليمن';
      }
      _cfgLoadedAt = DateTime.now();
    } catch (_) {}
  }

  // إرسال عبر SMTP (موبايل)
  static Future<void> _sendViaSMTP({
    required String toEmail,
    required String otp,
    required String type,
  }) async {
    await _loadSmtpConfig();
    final smtpServer = gmail(_senderEmail, _senderPassword);
    final isRegister = type == 'register';
    final message = Message()
      ..from = Address(_senderEmail, _cfgName)
      ..recipients.add(toEmail)
      ..subject = isRegister
          ? 'رمز تفعيل الحساب - حراج اليمن'
          : 'رمز إعادة تعيين كلمة المرور - حراج اليمن'
      ..html = _buildOtpEmailHtml(otp, isRegister);
    await send(message, smtpServer);
  }

  // للتوافق مع الكود القديم
  static Future<void> sendPasswordResetOtp({
    required String toEmail,
    required String otp,
  }) => sendOtp(toEmail: toEmail, otp: otp, type: 'reset');

  static String _buildOtpEmailHtml(String otp, bool isRegister) {
    final title = isRegister ? 'تفعيل حسابك في حراج اليمن' : 'إعادة تعيين كلمة المرور';
    final desc  = isRegister
        ? 'أدخل رمز التحقق أدناه لتفعيل حسابك'
        : 'أدخل رمز التحقق أدناه لإعادة تعيين كلمة المرور';
    return '''<!DOCTYPE html>
<html dir="rtl" lang="ar"><head><meta charset="UTF-8">
<style>
  body{font-family:Arial,sans-serif;background:#f5f5f5;margin:0;padding:20px;direction:rtl}
  .box{max-width:480px;margin:auto;background:#fff;border-radius:12px;overflow:hidden;box-shadow:0 2px 8px rgba(0,0,0,.1)}
  .hdr{background:#1B5E20;padding:24px;text-align:center}
  .hdr h1{color:#fff;margin:0;font-size:22px}
  .body{padding:32px 24px;text-align:center}
  .otp-box{background:#f0f7f0;border:2px dashed #1B5E20;border-radius:10px;padding:20px;margin:20px 0}
  .otp{font-size:42px;font-weight:bold;color:#1B5E20;letter-spacing:12px}
  .note{color:#777;font-size:13px;margin-top:8px}
  .footer{background:#f5f5f5;padding:16px;text-align:center;color:#aaa;font-size:12px}
</style></head>
<body><div class="box">
  <div class="hdr"><h1>🏪 حراج اليمن</h1></div>
  <div class="body">
    <p style="font-size:16px;color:#333">$title</p>
    <p style="color:#666;font-size:14px">$desc</p>
    <div class="otp-box">
      <div class="otp">$otp</div>
      <div class="note">الرمز صالح لمدة 10 دقائق</div>
    </div>
    <p style="color:#999;font-size:12px">إذا لم تطلب ذلك، تجاهل هذا الإيميل.</p>
  </div>
  <div class="footer">حراج اليمن - سوق الإعلانات المجانية</div>
</div></body></html>''';
  }
}
