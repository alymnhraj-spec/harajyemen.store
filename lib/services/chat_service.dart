import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'notification_service.dart';

class ChatMessage {
  final String id;
  final String senderId;
  final String text;
  final DateTime timestamp;

  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.text,
    required this.timestamp,
  });

  factory ChatMessage.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return ChatMessage(
      id: doc.id,
      senderId: d['sender_id'] ?? '',
      text: d['text'] ?? '',
      timestamp: (d['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

class Conversation {
  final String id;
  final List<String> participants;
  final Map<String, String> phones;
  final String lastMessage;
  final DateTime lastMessageTime;
  final Map<String, int> unread;
  final String lastPostTitle;
  final String lastPostImage;

  const Conversation({
    required this.id,
    required this.participants,
    required this.phones,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.unread,
    required this.lastPostTitle,
    required this.lastPostImage,
  });

  String otherUserId(String myUid) =>
      participants.firstWhere((p) => p != myUid, orElse: () => '');

  String otherPhone(String myUid) =>
      phones[otherUserId(myUid)] ?? '';

  int unreadCount(String myUid) => unread[myUid] ?? 0;

  factory Conversation.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    final participants = (d['participants'] as List?)?.cast<String>() ?? [];
    final phonesRaw = (d['phones'] as Map<String, dynamic>?) ?? {};
    final phones = phonesRaw.map((k, v) => MapEntry(k, v.toString()));
    final unreadRaw = (d['unread'] as Map<String, dynamic>?) ?? {};
    final unread = unreadRaw.map((k, v) => MapEntry(k, (v as num).toInt()));

    return Conversation(
      id: doc.id,
      participants: participants,
      phones: phones,
      lastMessage: d['last_message'] ?? '',
      lastMessageTime:
          (d['last_message_time'] as Timestamp?)?.toDate() ?? DateTime.now(),
      unread: unread,
      lastPostTitle: d['last_post_title'] ?? '',
      lastPostImage: d['last_post_image'] ?? '',
    );
  }
}

class ChatService {
  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;
  ChatService._internal();

  FirebaseFirestore get _db => FirebaseFirestore.instance;
  FirebaseAuth get _auth => FirebaseAuth.instance;

  // معرف المحادثة محدد بناءً على الـ uid لضمان محادثة واحدة بين كل شخصين
  String _convId(String uid1, String uid2) {
    final sorted = [uid1, uid2]..sort();
    return '${sorted[0]}__${sorted[1]}';
  }

  Future<String> _getUid() async {
    final uid = _auth.currentUser?.uid;
    if (uid != null) return uid;
    final prefs = await SharedPreferences.getInstance();
    final demoUid = prefs.getString('demo_uid');
    if (demoUid != null) return demoUid;
    throw Exception('يجب تسجيل الدخول أولاً');
  }

  Future<String> _getMyPhone() async {
    final phone = _auth.currentUser?.phoneNumber;
    if (phone != null && phone.isNotEmpty) return phone;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_phone') ?? '';
  }

  // إنشاء أو جلب محادثة بين مستخدمين (محادثة واحدة لكل حساب)
  Future<String> createOrGetConversation({
    required String otherUid,
    required String otherPhone,
    String postTitle = '',
    String postImage = '',
  }) async {
    final myUid = await _getUid();
    final myPhone = await _getMyPhone();
    final convId = _convId(myUid, otherUid);
    final docRef = _db.collection('conversations').doc(convId);

    final doc = await docRef.get();
    if (!doc.exists) {
      final sorted = [myUid, otherUid]..sort();
      await docRef.set({
        'participants': sorted,
        'phones': {myUid: myPhone, otherUid: otherPhone},
        'last_message': '',
        'last_message_time': FieldValue.serverTimestamp(),
        'unread': {myUid: 0, otherUid: 0},
        'last_post_title': postTitle,
        'last_post_image': postImage,
        'created_at': FieldValue.serverTimestamp(),
      });
    } else {
      // تحديث سياق آخر إعلان
      if (postTitle.isNotEmpty) {
        await docRef.update({
          'last_post_title': postTitle,
          'last_post_image': postImage,
          'phones.$myUid': myPhone,
        });
      }
    }

    return convId;
  }

  // إرسال رسالة
  Future<void> sendMessage(String conversationId, String text) async {
    if (text.trim().isEmpty) return;
    final myUid = await _getUid().catchError((_) => '');
    if (myUid.isEmpty) return;

    final convRef = _db.collection('conversations').doc(conversationId);
    final convDoc = await convRef.get();
    final convData = convDoc.data() as Map<String, dynamic>?;
    if (convData == null) return;

    final participants = (convData['participants'] as List?)?.cast<String>() ?? [];
    final recipientId = participants.firstWhere((p) => p != myUid, orElse: () => '');

    final batch = _db.batch();

    // إضافة الرسالة
    final msgRef = convRef.collection('messages').doc();
    batch.set(msgRef, {
      'sender_id': myUid,
      'text': text.trim(),
      'timestamp': FieldValue.serverTimestamp(),
    });

    // تحديث المحادثة
    batch.update(convRef, {
      'last_message': text.trim(),
      'last_message_time': FieldValue.serverTimestamp(),
      if (recipientId.isNotEmpty) 'unread.$recipientId': FieldValue.increment(1),
    });

    await batch.commit();

    // إشعار للطرف الآخر
    if (recipientId.isNotEmpty) {
      final myPhone = await _getMyPhone();
      final senderName = myPhone.isNotEmpty ? myPhone : 'مستخدم';
      final phones = (convData['phones'] as Map<String, dynamic>?) ?? {};
      final recipientPhone = phones[recipientId] as String? ?? '';
      await NotificationService().sendNotificationToUser(
        recipientUid: recipientId,
        title: 'رسالة جديدة من $senderName',
        body: text.trim(),
        recipientPhone: recipientPhone,
      );
    }
  }

  // الحصول على رسائل محادثة
  Stream<List<ChatMessage>> getMessages(String conversationId) {
    return _db
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .snapshots()
        .map((snap) {
          final list = snap.docs.map((d) => ChatMessage.fromFirestore(d)).toList();
          list.sort((a, b) => a.timestamp.compareTo(b.timestamp));
          return list;
        });
  }

  // كل محادثات المستخدم الحالي
  Stream<List<Conversation>> getAllConversations() async* {
    try {
      final uid = await _getUid();
      yield* _db
          .collection('conversations')
          .where('participants', arrayContains: uid)
          .snapshots()
          .map((snap) {
            final list = snap.docs
                .map((d) => Conversation.fromFirestore(d))
                .toList();
            list.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));
            return list;
          });
    } catch (_) {
      yield [];
    }
  }

  // تعليم المحادثة مقروءة
  Future<void> markAsRead(String conversationId) async {
    final myUid = await _getUid().catchError((_) => '');
    if (myUid.isEmpty) return;
    try {
      await _db.collection('conversations').doc(conversationId).update({
        'unread.$myUid': 0,
      });
    } catch (_) {}
  }

  // إجمالي الرسائل غير المقروءة
  Stream<int> getTotalUnread() async* {
    try {
      final uid = await _getUid();
      yield* getAllConversations().map((list) =>
          list.fold<int>(0, (sum, c) => sum + c.unreadCount(uid)));
    } catch (_) {
      yield 0;
    }
  }
}
