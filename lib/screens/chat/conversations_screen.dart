import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/chat_service.dart';
import '../../theme/app_theme.dart';
import 'chat_screen.dart';

class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({super.key});

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  String _uid = FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    _loadUid();
  }

  Future<void> _loadUid() async {
    if (_uid.isNotEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final demoUid = prefs.getString('demo_uid') ?? '';
    if (mounted && demoUid.isNotEmpty) setState(() => _uid = demoUid);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الرسائل'),
        automaticallyImplyLeading: false,
      ),
      body: StreamBuilder<List<Conversation>>(
        stream: ChatService().getAllConversations(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final conversations = snapshot.data ?? [];

          if (conversations.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.chat_bubble_outline,
                    size: 80,
                    color: AppColors.divider,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'لا توجد رسائل',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'افتح أي إعلان وابدأ الدردشة مع البائع',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            itemCount: conversations.length,
            separatorBuilder: (_, __) =>
                const Divider(height: 1, indent: 72),
            itemBuilder: (context, i) {
              final conv = conversations[i];
              final unread = conv.unreadCount(_uid);
              final otherPhone = conv.otherPhone(_uid);

              return ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: conv.lastPostImage.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: conv.lastPostImage,
                              width: 52,
                              height: 52,
                              fit: BoxFit.cover,
                              errorWidget: (_, __, ___) => _placeholderImage(),
                            )
                          : _placeholderImage(),
                    ),
                    if (unread > 0)
                      Positioned(
                        left: 0,
                        top: 0,
                        child: Container(
                          width: 18,
                          height: 18,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              unread > 9 ? '9+' : '$unread',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (conv.lastPostTitle.isNotEmpty)
                      Text(
                        conv.lastPostTitle,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    Text(
                      otherPhone,
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 12),
                      textDirection: TextDirection.ltr,
                    ),
                  ],
                ),
                subtitle: Text(
                  conv.lastMessage.isEmpty
                      ? 'ابدأ المحادثة...'
                      : conv.lastMessage,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: unread > 0
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                    fontWeight:
                        unread > 0 ? FontWeight.w600 : FontWeight.w400,
                    fontSize: 13,
                  ),
                ),
                trailing: Text(
                  _formatTime(conv.lastMessageTime),
                  style: TextStyle(
                    color: unread > 0 ? AppColors.primary : AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight:
                        unread > 0 ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => ChatScreen(
                      conversationId: conv.id,
                      otherUserPhone: otherPhone,
                      postTitle: conv.lastPostTitle,
                      postImage: conv.lastPostImage,
                    ),
                  ));
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _placeholderImage() {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.image_outlined, color: AppColors.divider, size: 28),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inDays == 0) {
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays == 1) {
      return 'أمس';
    } else if (diff.inDays < 7) {
      const days = ['الأحد', 'الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت'];
      return days[time.weekday % 7];
    } else {
      return '${time.day}/${time.month}';
    }
  }
}
