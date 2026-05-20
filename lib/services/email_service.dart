import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server/gmail.dart';

class EmailService {
  static const _username = 'alymnhraj@gmail.com';
  static const _password = 'kqddesbzlmpfgcvo';

  static Future<void> sendPasswordResetOtp({
    required String toEmail,
    required String otp,
  }) async {
    if (kIsWeb) {
      throw Exception('إرسال الإيميل غير مدعوم على الويب حالياً');
    }

    final smtpServer = gmail(_username, _password);

    final message = Message()
      ..from = const Address(_username, 'حراج اليمن')
      ..recipients.add(toEmail)
      ..subject = 'رمز إعادة تعيين كلمة المرور - حراج اليمن'
      ..html = _buildOtpEmailHtml(otp);

    await send(message, smtpServer);
  }

  static String _buildOtpEmailHtml(String otp) {
    return '''
<!DOCTYPE html>
<html dir="rtl" lang="ar">
<head>
  <meta charset="UTF-8">
  <style>
    body { font-family: Arial, sans-serif; background:#f5f5f5; margin:0; padding:20px; direction:rtl; }
    .container { max-width:480px; margin:auto; background:#fff; border-radius:12px; overflow:hidden; box-shadow:0 2px 8px rgba(0,0,0,0.1); }
    .header { background:#1B5E20; padding:24px; text-align:center; }
    .header h1 { color:#fff; margin:0; font-size:22px; }
    .body { padding:32px 24px; text-align:center; }
    .otp-box { background:#f0f7f0; border:2px dashed #1B5E20; border-radius:10px; padding:20px; margin:20px 0; }
    .otp { font-size:40px; font-weight:bold; color:#1B5E20; letter-spacing:10px; }
    .note { color:#777; font-size:13px; margin-top:8px; }
    .footer { background:#f5f5f5; padding:16px; text-align:center; color:#aaa; font-size:12px; }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1>🏪 حراج اليمن</h1>
    </div>
    <div class="body">
      <p style="font-size:16px; color:#333;">تم طلب إعادة تعيين كلمة المرور لحسابك</p>
      <div class="otp-box">
        <div class="otp">$otp</div>
        <div class="note">رمز التحقق صالح لمدة 10 دقائق</div>
      </div>
      <p style="color:#666; font-size:14px;">أدخل هذا الرمز في التطبيق لإعادة تعيين كلمة المرور.</p>
      <p style="color:#999; font-size:12px;">إذا لم تطلب إعادة التعيين، تجاهل هذا الإيميل.</p>
    </div>
    <div class="footer">حراج اليمن - سوق الإعلانات المجانية</div>
  </div>
</body>
</html>
''';
  }
}
