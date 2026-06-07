import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';

class OtpScreen extends StatefulWidget {
  final String phoneNumber;
  final String? verificationId;
  final bool isDemoMode;

  const OtpScreen({
    super.key,
    required this.phoneNumber,
    this.verificationId,
    this.isDemoMode = false,
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _otpController = TextEditingController();
  final _authService = AuthService();
  final StreamController<ErrorAnimationType> _errorController =
      StreamController<ErrorAnimationType>();

  bool _isLoading = false;
  bool _canResend = false;
  int _countdown = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    setState(() {
      _canResend = false;
      _countdown = 60;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_countdown > 0) {
          _countdown--;
        } else {
          _canResend = true;
          timer.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    _errorController.close();
    super.dispose();
  }

  Future<void> _verifyOtp(String otp) async {
    if (otp.length != 6) return;

    setState(() => _isLoading = true);

    try {
      await _authService.verifyOtp(
        otpCode: otp,
        verificationId: widget.verificationId,
      );
      // حفظ رقم الهاتف دائماً
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_phone', widget.phoneNumber);

      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/home', (_) => false);
    } catch (e) {
      if (!mounted) return;
      _errorController.add(ErrorAnimationType.shake);
      _otpController.clear();
      _showError(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resendOtp() async {
    if (!_canResend) return;

    if (widget.isDemoMode) {
      _startCountdown();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إعادة الإرسال')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _authService.sendOtp(
        phoneNumber: widget.phoneNumber,
        onError: (error) => _showError(error),
      );
      _startCountdown();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إرسال الرمز مجدداً')),
      );
    } catch (e) {
      _showError(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.accent),
    );
  }

  String _formatPhone(String phone) {
    // إخفاء جزء من الرقم للخصوصية: +967 7XX XXX X37
    if (phone.length < 4) return phone;
    return '${phone.substring(0, 6)}****${phone.substring(phone.length - 2)}';
  }

  @override
  Widget build(BuildContext context) {
    final content = _buildContent(context);
    final isWideWeb = kIsWeb && MediaQuery.of(context).size.width >= 700;
    if (isWideWeb) {
      return Scaffold(
        backgroundColor: const Color(0xFFF4F5F7),
        appBar: AppBar(
          title: const Text('التحقق من الهاتف'),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: Center(
          child: SingleChildScrollView(
            child: Container(
              width: 440,
              margin: const EdgeInsets.symmetric(vertical: 40),
              padding: const EdgeInsets.all(36),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: content,
            ),
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('التحقق من الهاتف'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: content,
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 32),

        // أيقونة
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(
            Icons.sms_outlined,
            size: 40,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 24),

        Text(
          'أدخل رمز التحقق',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        Text(
          'تم إرسال رمز مكون من 6 أرقام إلى',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          _formatPhone(widget.phoneNumber),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
          ),
          textDirection: TextDirection.ltr,
        ),
        const SizedBox(height: 32),

        // حقول OTP
        Directionality(
          textDirection: TextDirection.ltr,
          child: PinCodeTextField(
            appContext: context,
            controller: _otpController,
            length: 6,
            keyboardType: TextInputType.number,
            animationType: AnimationType.fade,
            errorAnimationController: _errorController,
            pinTheme: PinTheme(
              shape: PinCodeFieldShape.box,
              borderRadius: BorderRadius.circular(12),
              fieldHeight: 56,
              fieldWidth: 48,
              activeFillColor: Colors.white,
              inactiveFillColor: Colors.white,
              selectedFillColor: Colors.white,
              activeColor: AppColors.primary,
              inactiveColor: AppColors.divider,
              selectedColor: AppColors.primary,
            ),
            enableActiveFill: true,
            autoFocus: true,
            autoDismissKeyboard: true,
            enablePinAutofill: true,
            onChanged: (value) {},
            onCompleted: (otp) => _verifyOtp(otp),
          ),
        ),
        const SizedBox(height: 28),

        // زر التحقق
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading
                ? null
                : () => _verifyOtp(_otpController.text),
            child: _isLoading
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : const Text('تحقق والدخول'),
          ),
        ),
        const SizedBox(height: 20),

        // إعادة الإرسال
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'لم تستلم الرمز؟ ',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            GestureDetector(
              onTap: _canResend ? _resendOtp : null,
              child: Text(
                _canResend
                    ? 'أعد الإرسال'
                    : 'أعد الإرسال ($_countdown)',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: _canResend
                      ? AppColors.primary
                      : AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}
