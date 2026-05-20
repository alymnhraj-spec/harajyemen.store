import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../firebase_options.dart';
import 'notification_secrets.dart';

// معالج الإشعارات في الخلفية
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // تهيئة الإشعارات المحلية في الخلفية
  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  final localNotif = FlutterLocalNotificationsPlugin();
  await localNotif.initialize(const InitializationSettings(android: androidSettings));

  const androidDetails = AndroidNotificationDetails(
    'haraj_channel',
    'إشعارات حراج اليمن',
    importance: Importance.high,
    priority: Priority.high,
    playSound: true,
    enableVibration: true,
    icon: '@mipmap/ic_launcher',
  );

  final title = message.notification?.title ?? message.data['title'] ?? 'إشعار جديد';
  final body  = message.notification?.body  ?? message.data['body']  ?? '';

  await localNotif.show(
    DateTime.now().millisecondsSinceEpoch ~/ 1000 % 100000,
    title,
    body,
    const NotificationDetails(android: androidDetails),
  );
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final _fcm = FirebaseMessaging.instance;
  final _localNotifications = FlutterLocalNotificationsPlugin();

  // بيانات حساب الخدمة — المفتاح في notification_secrets.dart (مستثنى من Git)
  static const _clientEmail =
      'firebase-adminsdk-fbsvc@haraj-yemen-app.iam.gserviceaccount.com';
  static const _projectId = 'haraj-yemen-app';
  static const _tokenUri = 'https://oauth2.googleapis.com/token';
  static const _fcmScope =
      'https://www.googleapis.com/auth/firebase.messaging';
  static const _privateKey = NotificationSecrets.fcmPrivateKey;

  static const _channelId = 'haraj_channel';
  static const _channelName = 'إشعارات حراج اليمن';

  String? _cachedToken;
  DateTime? _tokenExpiry;

  Future<void> initialize() async {
    await _fcm.requestPermission(alert: true, sound: true, badge: true);

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await _localNotifications.initialize(initSettings);

    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: 'إشعارات الرسائل والإعلانات',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    FirebaseMessaging.onMessage.listen((message) {
      showLocalNotification(
        title: message.notification?.title ?? 'رسالة جديدة',
        body: message.notification?.body ?? '',
      );
    });

    final token = await _fcm.getToken();
    if (token != null) await _saveToken(token);
    _fcm.onTokenRefresh.listen(_saveToken);

    // اشتراك في topic عام لاستقبال الإشعارات المخصصة من الأدمن
    await _fcm.subscribeToTopic('all_users');
  }

  Future<void> _saveToken(String token) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        // مستخدم حقيقي: حفظ بالـ UID
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .set({'fcm_token': token}, SetOptions(merge: true));
        return;
      }
      // مستخدم تجريبي: حفظ بالـ UID التجريبي وبرقم الهاتف معاً
      final prefs = await SharedPreferences.getInstance();
      final demoUid = prefs.getString('demo_uid');
      final phone = prefs.getString('user_phone') ?? '';
      if (demoUid != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(demoUid)
            .set({'fcm_token': token, 'phone': phone}, SetOptions(merge: true));
      }
      // حفظ إضافي برقم الهاتف كمفتاح لتجنب تضارب المستخدمين التجريبيين
      if (phone.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('fcm_tokens')
            .doc(phone)
            .set({'token': token, 'updated_at': FieldValue.serverTimestamp()});
      }
    } catch (_) {}
  }

  Future<String> _getAccessToken() async {
    if (_cachedToken != null &&
        _tokenExpiry != null &&
        DateTime.now().isBefore(_tokenExpiry!)) {
      return _cachedToken!;
    }

    final now = DateTime.now();
    final jwt = JWT({
      'iss': _clientEmail,
      'scope': _fcmScope,
      'aud': _tokenUri,
      'iat': now.millisecondsSinceEpoch ~/ 1000,
      'exp': (now.millisecondsSinceEpoch ~/ 1000) + 3600,
    });

    final signed =
        jwt.sign(RSAPrivateKey(_privateKey), algorithm: JWTAlgorithm.RS256);

    final response = await http.post(
      Uri.parse(_tokenUri),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'grant_type': 'urn:ietf:params:oauth:grant-type:jwt-bearer',
        'assertion': signed,
      },
    );

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    _cachedToken = data['access_token'] as String;
    _tokenExpiry =
        now.add(Duration(seconds: (data['expires_in'] as int) - 60));
    return _cachedToken!;
  }

  Future<void> showLocalNotification({
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
    );
    const details = NotificationDetails(android: androidDetails);
    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000 % 100000,
      title,
      body,
      details,
    );
  }

  // إرسال إشعار لجميع المستخدمين عبر topic
  Future<void> sendBroadcastNotification({
    required String title,
    required String body,
  }) async {
    try {
      final accessToken = await _getAccessToken();

      final response = await http.post(
        Uri.parse('https://fcm.googleapis.com/v1/projects/$_projectId/messages:send'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({
          'message': {
            'topic': 'all_users',
            'notification': {'title': title, 'body': body},
            'android': {
              'priority': 'high',
              'notification': {'sound': 'default', 'channel_id': _channelId},
            },
          },
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('فشل الإرسال: ${response.body}');
      }

      // حفظ سجل الإشعار في Firestore
      await FirebaseFirestore.instance.collection('broadcast_notifications').add({
        'title': title,
        'body': body,
        'sent_at': FieldValue.serverTimestamp(),
        'sent_by': FirebaseAuth.instance.currentUser?.uid ?? '',
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<void> sendNotificationToUser({
    required String recipientUid,
    required String title,
    required String body,
    String? recipientPhone,
  }) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(recipientUid)
          .get();
      String? token = doc.data()?['fcm_token'] as String?;

      // إذا لم نجد التوكن بالـ UID، جرب البحث برقم الهاتف (للمستخدمين التجريبيين)
      if ((token == null || token.isEmpty) && recipientPhone != null && recipientPhone.isNotEmpty) {
        final phoneDoc = await FirebaseFirestore.instance
            .collection('fcm_tokens')
            .doc(recipientPhone)
            .get();
        token = phoneDoc.data()?['token'] as String?;
      }

      if (token == null || token.isEmpty) return;

      final accessToken = await _getAccessToken();

      final response = await http.post(
        Uri.parse(
            'https://fcm.googleapis.com/v1/projects/$_projectId/messages:send'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({
          'message': {
            'token': token,
            'notification': {'title': title, 'body': body},
            'data': {'title': title, 'body': body, 'type': 'chat'},
            'android': {
              'priority': 'high',
              'notification': {
                'sound': 'default',
                'channel_id': _channelId,
                'notification_priority': 'PRIORITY_HIGH',
              },
            },
          },
        }),
      );

      if (response.statusCode != 200) {
        // تسجيل الخطأ في Firestore للتتبع
        FirebaseFirestore.instance.collection('fcm_errors').add({
          'recipient': recipientUid,
          'status': response.statusCode,
          'error': response.body,
          'at': FieldValue.serverTimestamp(),
        }).catchError((_) => FirebaseFirestore.instance.collection('fcm_errors').doc());
      }
    } catch (_) {}
  }
}
