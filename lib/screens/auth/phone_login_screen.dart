import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/auth_service.dart';
import '../../services/email_service.dart';
import '../../theme/app_theme.dart';

class PhoneLoginScreen extends StatefulWidget {
  const PhoneLoginScreen({super.key});

  @override
  State<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends State<PhoneLoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();
  bool _isLoading = false;
  bool _isRegisterMode = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _forgotPassword() async {
    final emailController = TextEditingController(text: _emailController.text.trim());

    // الخطوة 1: أدخل الإيميل
    final email = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('نسيت كلمة المرور؟', textAlign: TextAlign.right),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'أدخل بريدك الإلكتروني وسنرسل لك رمز التحقق',
              textAlign: TextAlign.right,
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              textDirection: TextDirection.ltr,
              decoration: const InputDecoration(
                labelText: 'البريد الإلكتروني',
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, emailController.text.trim()),
            child: const Text('إرسال الرمز'),
          ),
        ],
      ),
    );

    if (email == null || email.isEmpty) return;
    setState(() => _isLoading = true);

    try {
      // إنشاء OTP وإرساله عبر Gmail
      final otp = await _authService.createPasswordResetOtp(email);

      if (kIsWeb) {
        // على الويب نستخدم Firebase مباشرة
        await _authService.sendPasswordResetEmail(email);
        if (!mounted) return;
        _showSnack('تم إرسال رابط إعادة التعيين، تحقق من بريدك', Colors.green);
        return;
      }

      await EmailService.sendPasswordResetOtp(toEmail: email, otp: otp);
      if (!mounted) return;

      // الخطوة 2: أدخل OTP
      await _showOtpDialog(email);
    } catch (e) {
      if (mounted) _showSnack(e.toString().replaceAll('Exception: ', ''), AppColors.accent);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showOtpDialog(String email) async {
    final otpController = TextEditingController();

    final verified = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('أدخل رمز التحقق', textAlign: TextAlign.right),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'تم إرسال رمز من 6 أرقام إلى\n$email',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: otpController,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: 8),
              decoration: const InputDecoration(hintText: '______'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('تحقق'),
          ),
        ],
      ),
    );

    if (verified != true) return;

    setState(() => _isLoading = true);
    try {
      await _authService.verifyPasswordResetOtp(email, otpController.text);
      if (!mounted) return;

      // OTP صحيح → اعرض نموذج كلمة المرور الجديدة
      if (!mounted) return;
      await _showNewPasswordDialog(email);
    } catch (e) {
      if (mounted) _showSnack(e.toString().replaceAll('Exception: ', ''), AppColors.accent);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showNewPasswordDialog(String email) async {
    final newPassCtrl = TextEditingController();
    final confirmPassCtrl = TextEditingController();
    bool obs1 = true, obs2 = true;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('كلمة المرور الجديدة', textAlign: TextAlign.right),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: newPassCtrl,
                obscureText: obs1,
                textDirection: TextDirection.ltr,
                decoration: InputDecoration(
                  labelText: 'كلمة المرور الجديدة',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(obs1 ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                    onPressed: () => setS(() => obs1 = !obs1),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmPassCtrl,
                obscureText: obs2,
                textDirection: TextDirection.ltr,
                decoration: InputDecoration(
                  labelText: 'تأكيد كلمة المرور',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(obs2 ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                    onPressed: () => setS(() => obs2 = !obs2),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: () async {
                final newPass = newPassCtrl.text;
                if (newPass.length < 6) {
                  _showSnack('كلمة المرور يجب أن تكون 6 أحرف على الأقل', AppColors.accent);
                  return;
                }
                if (newPass != confirmPassCtrl.text) {
                  _showSnack('كلمتا المرور غير متطابقتين', AppColors.accent);
                  return;
                }
                Navigator.pop(ctx);
                setState(() => _isLoading = true);
                try {
                  final success = await _authService.changePasswordAfterOtp(email, newPass);
                  if (!mounted) return;
                  if (success) {
                    _showSnack('تم تغيير كلمة المرور بنجاح! سجّل دخولك الآن', Colors.green);
                  } else {
                    // Firebase لا يسمح بالتغيير المباشر → أرسل رابط للإيميل
                    await _authService.sendPasswordResetEmail(email);
                    if (!mounted) return;
                    showDialog(
                      context: context,
                      builder: (c) => AlertDialog(
                        title: const Text('تحقق من بريدك', textAlign: TextAlign.right),
                        content: Text(
                          'أرسلنا رابط تغيير كلمة المرور إلى:\n$email\n\nتحقق من مجلد Spam إذا لم تجده في الوارد.',
                          textAlign: TextAlign.right,
                          style: const TextStyle(fontSize: 13, height: 1.6),
                        ),
                        actions: [
                          ElevatedButton(onPressed: () => Navigator.pop(c), child: const Text('حسناً'))
                        ],
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) _showSnack(e.toString().replaceAll('Exception: ', ''), AppColors.accent);
                } finally {
                  if (mounted) setState(() => _isLoading = false);
                }
              },
              child: const Text('تغيير كلمة المرور'),
            ),
          ],
        ),
      ),
    );
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      if (_isRegisterMode) {
        await _authService.registerWithEmail(
          email: _emailController.text,
          password: _passwordController.text,
        );
      } else {
        await _authService.signInWithEmail(
          email: _emailController.text,
          password: _passwordController.text,
        );
      }
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppColors.accent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 60),
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(Icons.storefront_outlined, color: Colors.white, size: 48),
                ),
              ),
              const SizedBox(height: 24),
              Text('حراج اليمن',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  color: AppColors.primary)),
              const SizedBox(height: 6),
              Text('سوق الإعلانات المجانية',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary)),
              const SizedBox(height: 40),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textDirection: TextDirection.ltr,
                      textAlign: TextAlign.left,
                      decoration: const InputDecoration(
                        labelText: 'البريد الإلكتروني',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) return 'أدخل البريد الإلكتروني';
                        if (!RegExp(r'^[\w\.\+\-]+@[\w\-]+\.\w+$').hasMatch(value.trim())) {
                          return 'صيغة البريد الإلكتروني غير صحيحة';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      textDirection: TextDirection.ltr,
                      decoration: InputDecoration(
                        labelText: 'كلمة المرور',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'أدخل كلمة المرور';
                        if (value.length < 6) return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
                        return null;
                      },
                    ),
                    if (!_isRegisterMode) ...[
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                          onPressed: _isLoading ? null : _forgotPassword,
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text(
                            'نسيت كلمة المرور؟',
                            style: TextStyle(fontSize: 13, color: AppColors.primary),
                          ),
                        ),
                      ),
                    ],
                    if (_isRegisterMode) ...[
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: _obscureConfirmPassword,
                        textDirection: TextDirection.ltr,
                        decoration: InputDecoration(
                          labelText: 'تأكيد كلمة المرور',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(_obscureConfirmPassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined),
                            onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'أدخل تأكيد كلمة المرور';
                          if (value != _passwordController.text) return 'كلمتا المرور غير متطابقتين';
                          return null;
                        },
                      ),
                    ],
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _submit,
                      child: _isLoading
                          ? const SizedBox(height: 24, width: 24,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                          : Text(_isRegisterMode ? 'إنشاء حساب' : 'تسجيل الدخول'),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => setState(() {
                        _isRegisterMode = !_isRegisterMode;
                        _passwordController.clear();
                        _confirmPasswordController.clear();
                      }),
                      child: Text(
                        _isRegisterMode
                            ? 'لديك حساب بالفعل؟ تسجيل الدخول'
                            : 'ليس لديك حساب؟ إنشاء حساب جديد',
                        style: const TextStyle(color: AppColors.primary),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'بتسجيل دخولك توافق على شروط الاستخدام وسياسة الخصوصية',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
