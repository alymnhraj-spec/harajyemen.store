import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'screens/auth/phone_login_screen.dart';
import 'screens/home/home_screen.dart';
import 'services/admin_service.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb) {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).timeout(const Duration(seconds: 10));
  } catch (_) {}

  if (!kIsWeb) {
    try {
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    } catch (_) {}
    try {
      await NotificationService().initialize();
    } catch (_) {}
  }

  runApp(const HarajYemenApp());
}

class HarajYemenApp extends StatelessWidget {
  const HarajYemenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'حراج اليمن',
      debugShowCheckedModeBanner: false,
      locale: const Locale('ar', 'YE'),
      supportedLocales: const [
        Locale('ar', 'YE'),
        Locale('ar', ''),
        Locale('en', ''),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: AppTheme.lightTheme,
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child!,
        );
      },
      home: const _AuthGate(),
      routes: {
        '/login': (context) => const PhoneLoginScreen(),
        '/home': (context) => const HomeScreen(),
      },
    );
  }
}

class _AuthGate extends StatefulWidget {
  const _AuthGate();

  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _navigate());
  }

  Future<void> _navigate() async {
    if (!mounted) return;
    try {
      // على الويب: اذهب مباشرة للصفحة الرئيسية كزائر
      if (kIsWeb) {
        if (mounted) Navigator.of(context).pushReplacementNamed('/home');
        return;
      }

      // تحقق من وضع تجريبي أولاً (بدون Firebase)
      final isDemo = await AuthService.isDemoUser();
      if (isDemo) {
        if (mounted) Navigator.of(context).pushReplacementNamed('/home');
        return;
      }

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (mounted) Navigator.of(context).pushReplacementNamed('/login');
        return;
      }
      try {
        final isBanned = await AdminService()
            .isCurrentUserBanned()
            .timeout(const Duration(seconds: 4));
        if (!mounted) return;
        if (isBanned) {
          Navigator.of(context).pushReplacementNamed('/login');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم حظر حسابك. تواصل مع الدعم.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 5),
            ),
          );
          return;
        }
      } catch (_) {}
      if (mounted) Navigator.of(context).pushReplacementNamed('/home');
    } catch (_) {
      if (mounted) Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
      ),
    );
  }
}
