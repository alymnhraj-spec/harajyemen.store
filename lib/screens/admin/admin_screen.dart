import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../services/admin_service.dart';
import '../../services/notification_service.dart';
import '../../theme/app_theme.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _adminService = AdminService();
  final _userSearchController = TextEditingController();
  String _userSearchQuery = '';
  final _postSearchController = TextEditingController();
  String _postSearchQuery = '';
  final _notifTitleController = TextEditingController();
  final _notifBodyController = TextEditingController();
  bool _isSendingNotif = false;
  int _postsRefreshKey = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _userSearchController.dispose();
    _postSearchController.dispose();
    _notifTitleController.dispose();
    _notifBodyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة الإدارة'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'تحديث',
            onPressed: () => setState(() => _postsRefreshKey++),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: [
            const Tab(text: 'الإعلانات', icon: Icon(Icons.list_alt, size: 16)),
            const Tab(text: 'المستخدمون', icon: Icon(Icons.people, size: 16)),
            const Tab(text: 'الأدمن', icon: Icon(Icons.admin_panel_settings, size: 16)),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('reports')
                  .where('status', isEqualTo: 'pending')
                  .snapshots(),
              builder: (_, snap) {
                final count = snap.data?.docs.length ?? 0;
                return Tab(
                  icon: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Icon(Icons.flag_outlined, size: 16),
                      if (count > 0)
                        Positioned(
                          right: -6, top: -4,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                            constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                            child: Text('$count', style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w700), textAlign: TextAlign.center),
                          ),
                        ),
                    ],
                  ),
                  text: 'البلاغات',
                );
              },
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildPostsTab(), _buildUsersTab(), _buildAdminsTab(), _buildReportsTab()],
      ),
    );
  }

  // ===================== تبويب الإعلانات =====================
  Widget _buildPostsTab() {
    return Column(
      children: [
        // شريط تفعيل المميزة
        StreamBuilder<bool>(
          stream: _adminService.isFeaturedSectionEnabled(),
          builder: (context, snap) {
            final enabled = snap.data ?? false;
            return Container(
              color: enabled ? Colors.amber.shade50 : Colors.grey.shade50,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.star,
                      color: enabled ? Colors.amber : Colors.grey, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      enabled
                          ? 'قسم المميزة مفعّل في الصفحة الرئيسية'
                          : 'قسم المميزة معطّل',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: enabled ? Colors.amber.shade800 : Colors.grey,
                      ),
                    ),
                  ),
                  Switch(
                    value: enabled,
                    activeColor: Colors.amber,
                    onChanged: (val) =>
                        _adminService.setFeaturedSectionEnabled(val),
                  ),
                ],
              ),
            );
          },
        ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _postSearchController,
                  textDirection: TextDirection.rtl,
                  decoration: InputDecoration(
                    hintText: 'بحث باسم الإعلان أو رقم الهاتف...',
                    hintStyle: const TextStyle(fontSize: 13),
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _postSearchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            onPressed: () {
                              _postSearchController.clear();
                              setState(() => _postSearchQuery = '');
                            },
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    isDense: true,
                  ),
                  onChanged: (v) => setState(() => _postSearchQuery = v.trim()),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'حذف الكل',
                icon: const Icon(Icons.delete_sweep, color: Colors.red),
                onPressed: _confirmDeleteAll,
              ),
            ],
          ),
        ),
        Expanded(
          child: FutureBuilder<List<Map<String, dynamic>>>(
            key: ValueKey(_postsRefreshKey),
            future: _adminService.getAllPostsOnce(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('خطأ: ${snapshot.error}', textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => setState(() => _postsRefreshKey++),
                        child: const Text('إعادة المحاولة'),
                      ),
                    ],
                  ),
                );
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              var posts = snapshot.data ?? [];
              if (_postSearchQuery.isNotEmpty) {
                final q = _postSearchQuery.toLowerCase();
                posts = posts.where((p) {
                  final title = (p['title'] ?? '').toString().toLowerCase();
                  final phone = (p['user_phone'] ?? '').toString();
                  return title.contains(q) || phone.contains(q);
                }).toList();
              }
              if (posts.isEmpty) {
                return Center(child: Text(_postSearchQuery.isNotEmpty ? 'لا توجد نتائج' : 'لا توجد إعلانات'));
              }
              return ListView.separated(
                itemCount: posts.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) => _buildPostTile(posts[i]),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPostTile(Map<String, dynamic> post) {
    final isFeatured = (post['is_featured'] as bool?) ?? false;
    final status = post['status'] ?? 'active';
    final images = (post['images'] as List?)?.cast<String>() ?? [];

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      leading: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: images.isNotEmpty
                ? Image.network(images.first,
                    width: 52, height: 52, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _placeholder())
                : _placeholder(),
          ),
          if (isFeatured)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                width: 16,
                height: 16,
                decoration: const BoxDecoration(
                  color: Colors.amber,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.star, size: 10, color: Colors.white),
              ),
            ),
        ],
      ),
      title: Text(
        post['title'] ?? '',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: status == 'active' ? null : Colors.grey,
        ),
      ),
      subtitle: Text(
        '${post['governorate_name'] ?? ''} • ${post['user_phone'] ?? ''}',
        style: const TextStyle(fontSize: 11),
        textDirection: TextDirection.rtl,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // زر التمييز
          IconButton(
            icon: Icon(
              isFeatured ? Icons.star : Icons.star_border,
              color: isFeatured ? Colors.amber : Colors.grey,
            ),
            tooltip: isFeatured ? 'إلغاء التمييز' : 'تمييز الإعلان',
            onPressed: () => _toggleFeature(post),
          ),
          // زر الحذف
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            tooltip: 'حذف',
            onPressed: () => _confirmDeletePost(
                post['id'] as String, post['title'] ?? ''),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleFeature(Map<String, dynamic> post) async {
    final isFeatured = (post['is_featured'] as bool?) ?? false;
    final postId = post['id'] as String;

    if (!isFeatured) {
      // تحقق من عدد الإعلانات المميزة
      final featured = await _adminService.getFeaturedPosts().first;
      if (featured.length >= 4) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('الحد الأقصى 4 إعلانات مميزة. أزل واحداً أولاً.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }
      await _adminService.featurePost(postId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تمييز الإعلان ⭐')),
        );
      }
    } else {
      await _adminService.unfeaturePost(postId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم إلغاء التمييز')),
        );
      }
    }
  }

  void _confirmDeleteAll() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('حذف جميع الإعلانات'),
        content: const Text('هل تريد حذف جميع الإعلانات؟ لا يمكن التراجع عن هذا الإجراء.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              try {
                final posts = await _adminService.getAllPostsOnce();
                for (final post in posts) {
                  await _adminService.deletePost(post['id'] as String);
                }
                if (mounted) {
                  setState(() => _postsRefreshKey++);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('تم حذف ${posts.length} إعلان'), backgroundColor: Colors.green),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text('حذف الكل', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmDeletePost(String postId, String title) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('حذف الإعلان'),
        content: Text('هل تريد حذف: $title؟'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              await _adminService.deletePost(postId);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم حذف الإعلان')),
                );
              }
            },
            child:
                const Text('حذف', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      width: 52,
      height: 52,
      color: AppColors.background,
      child: const Icon(Icons.image_outlined,
          color: AppColors.divider, size: 24),
    );
  }

  // ===================== تبويب المستخدمون =====================
  Widget _buildUsersTab() {
    return Column(
      children: [
        // شريط البحث
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
          child: TextField(
            controller: _userSearchController,
            textDirection: TextDirection.rtl,
            decoration: InputDecoration(
              hintText: 'بحث باسم أو رقم هاتف...',
              hintStyle: const TextStyle(fontSize: 13),
              prefixIcon: _userSearchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () {
                        _userSearchController.clear();
                        setState(() => _userSearchQuery = '');
                      },
                    )
                  : const Icon(Icons.search, size: 20),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              isDense: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              filled: true,
              fillColor: const Color(0xFFF5F5F5),
            ),
            onChanged: (val) => setState(() => _userSearchQuery = val.trim().toLowerCase()),
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: _adminService.getAllUsers(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              var users = snapshot.data ?? [];
              if (_userSearchQuery.isNotEmpty) {
                users = users.where((u) {
                  final phone = (u['phone'] ?? '').toString().toLowerCase();
                  final name = (u['name'] ?? '').toString().toLowerCase();
                  final uid = (u['uid'] ?? '').toString().toLowerCase();
                  return phone.contains(_userSearchQuery) ||
                      name.contains(_userSearchQuery) ||
                      uid.contains(_userSearchQuery);
                }).toList();
              }
              if (users.isEmpty) {
                return Center(
                  child: Text(
                    _userSearchQuery.isNotEmpty ? 'لا توجد نتائج' : 'لا يوجد مستخدمون',
                  ),
                );
              }
              return ListView.separated(
                itemCount: users.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) => _buildUserTile(users[i]),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildUserTile(Map<String, dynamic> user) {
    final isBanned = (user['is_banned'] as bool?) ?? false;
    final isAdmin = (user['is_admin'] as bool?) ?? false;
    final phone = user['phone'] ?? '';
    final name = user['name'] ?? '';
    final uid = user['uid'] ?? '';

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: isBanned
            ? Colors.red
            : isAdmin
                ? Colors.amber
                : AppColors.primary,
        child: Icon(
          isBanned
              ? Icons.block
              : isAdmin
                  ? Icons.admin_panel_settings
                  : Icons.person,
          color: Colors.white,
          size: 18,
        ),
      ),
      title: Text(
        name.isNotEmpty ? name : (phone.isNotEmpty ? phone : uid),
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        [
          if (phone.isNotEmpty) phone,
          if (isBanned) 'محظور 🚫',
          if (isAdmin) 'أدمن ⭐',
        ].join(' • '),
        style: TextStyle(
          fontSize: 11,
          color: isBanned ? Colors.red : null,
        ),
        textDirection: TextDirection.ltr,
      ),
      trailing: isAdmin
          ? null
          : isBanned
              ? TextButton(
                  onPressed: () async {
                    await _adminService.unbanUser(uid);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('تم رفع الحظر')),
                      );
                    }
                  },
                  child: const Text('رفع الحظر',
                      style: TextStyle(color: AppColors.primary)),
                )
              : TextButton(
                  onPressed: () => _confirmBanUser(uid, phone.isNotEmpty ? phone : uid),
                  child: const Text('حظر',
                      style: TextStyle(color: Colors.red)),
                ),
    );
  }

  void _confirmBanUser(String uid, String phone) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('حظر المستخدم'),
        content: Text('هل تريد حظر: $phone؟'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              await _adminService.banUser(uid);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم حظر المستخدم')),
                );
              }
            },
            child:
                const Text('حظر', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ===================== تبويب الأدمن =====================
  Widget _buildAdminsTab() {
    return Column(
      children: [
        // ===== إشعار مخصص =====
        _buildBroadcastSection(),
        const Divider(height: 1),
        // زر إضافة أدمن جديد
        Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: _showAddAdminDialog,
            icon: const Icon(Icons.person_add, color: Colors.white),
            label: const Text('إضافة أدمن جديد'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),
            ),
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: _adminService.getAdmins(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final admins = snapshot.data ?? [];
              if (admins.isEmpty) {
                return const Center(child: Text('لا يوجد أدمن'));
              }
              return ListView.separated(
                itemCount: admins.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) => _buildAdminTile(admins[i]),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAdminTile(Map<String, dynamic> admin) {
    final phone = admin['phone'] ?? '';
    final name = admin['name'] ?? '';
    final uid = admin['uid'] ?? '';

    return ListTile(
      leading: const CircleAvatar(
        backgroundColor: Colors.amber,
        child: Icon(Icons.admin_panel_settings, color: Colors.white, size: 18),
      ),
      title: Text(
        name.isNotEmpty ? name : (phone.isNotEmpty ? phone : uid),
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: phone.isNotEmpty
          ? Text(phone, textDirection: TextDirection.ltr, style: const TextStyle(fontSize: 12))
          : null,
      trailing: TextButton(
        onPressed: () => _confirmRemoveAdmin(uid, phone.isNotEmpty ? phone : uid),
        child: const Text('إزالة', style: TextStyle(color: Colors.red)),
      ),
    );
  }

  void _showAddAdminDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('إضافة أدمن جديد'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('أدخل البريد الإلكتروني للمستخدم (يجب أن يكون مسجلاً):'),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                keyboardType: TextInputType.emailAddress,
                textDirection: TextDirection.ltr,
                decoration: const InputDecoration(
                  labelText: 'البريد الإلكتروني',
                  hintText: 'example@email.com',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: () async {
                final email = controller.text.trim();
                if (email.isEmpty) return;
                Navigator.pop(context);
                final result = await _adminService.addAdmin(email);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(result)),
                  );
                }
              },
              child: const Text('إضافة'),
            ),
          ],
        ),
      ),
    );
  }

  // ===================== قسم الإشعار المخصص =====================
  Widget _buildBroadcastSection() {
    return Container(
      margin: const EdgeInsets.all(14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F8E9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.campaign, color: AppColors.primary, size: 20),
              SizedBox(width: 8),
              Text('إرسال إشعار لجميع المستخدمين',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notifTitleController,
            textDirection: TextDirection.rtl,
            decoration: InputDecoration(
              labelText: 'عنوان الإشعار',
              isDense: true,
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _notifBodyController,
            textDirection: TextDirection.rtl,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'نص الإشعار',
              isDense: true,
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 10),
          // سجل آخر الإشعارات
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('broadcast_notifications')
                .orderBy('sent_at', descending: true)
                .limit(3)
                .snapshots(),
            builder: (_, snap) {
              final docs = snap.data?.docs ?? [];
              if (docs.isEmpty) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(),
                  const Text('آخر الإشعارات المُرسَلة:',
                      style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  const SizedBox(height: 4),
                  ...docs.map((d) {
                    final data = d.data() as Map<String, dynamic>;
                    final ts = (data['sent_at'] as Timestamp?)?.toDate();
                    final date = ts != null ? '${ts.day}/${ts.month} ${ts.hour}:${ts.minute.toString().padLeft(2,'0')}' : '';
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle, size: 12, color: Colors.green),
                          const SizedBox(width: 4),
                          Expanded(child: Text('${data['title']} — $date',
                              style: const TextStyle(fontSize: 11), overflow: TextOverflow.ellipsis)),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 4),
                ],
              );
            },
          ),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isSendingNotif ? null : _sendBroadcast,
              icon: _isSendingNotif
                  ? const SizedBox(width: 16, height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.send, size: 16, color: Colors.white),
              label: Text(_isSendingNotif ? 'جاري الإرسال...' : 'إرسال للجميع'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(0, 44),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendBroadcast() async {
    final title = _notifTitleController.text.trim();
    final body = _notifBodyController.text.trim();
    if (title.isEmpty || body.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('أدخل العنوان والنص')),
      );
      return;
    }

    setState(() => _isSendingNotif = true);
    try {
      await NotificationService().sendBroadcastNotification(
        title: title,
        body: body,
      );
      _notifTitleController.clear();
      _notifBodyController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم الإرسال بنجاح ✓'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل الإرسال: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSendingNotif = false);
    }
  }

  // ===================== تبويب البلاغات =====================
  Widget _buildReportsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('reports')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snapshot.data?.docs ?? [];
        // ترتيب: معلقة أولاً ثم الأحدث
        final reports = docs.map((d) {
          final data = d.data() as Map<String, dynamic>;
          data['id'] = d.id;
          return data;
        }).toList();
        reports.sort((a, b) {
          final aP = a['status'] == 'pending' ? 0 : 1;
          final bP = b['status'] == 'pending' ? 0 : 1;
          if (aP != bP) return aP.compareTo(bP);
          final aT = (a['created_at'] as Timestamp?)?.toDate() ?? DateTime.now();
          final bT = (b['created_at'] as Timestamp?)?.toDate() ?? DateTime.now();
          return bT.compareTo(aT);
        });

        if (reports.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.flag_outlined, size: 64, color: AppColors.divider),
                SizedBox(height: 12),
                Text('لا توجد بلاغات', style: TextStyle(color: AppColors.textSecondary)),
              ],
            ),
          );
        }

        return ListView.separated(
          itemCount: reports.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (_, i) => _buildReportTile(reports[i]),
        );
      },
    );
  }

  Widget _buildReportTile(Map<String, dynamic> report) {
    final isPending = report['status'] == 'pending';
    final reason = report['reason'] ?? '';
    final postTitle = report['post_title'] ?? '';
    final reporterPhone = report['reporter_phone'] ?? '';
    final postOwnerPhone = report['post_owner_phone'] ?? '';
    final id = report['id'] as String;
    final ts = (report['created_at'] as Timestamp?)?.toDate();
    final timeStr = ts != null ? '${ts.day}/${ts.month}/${ts.year}' : '';

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      leading: CircleAvatar(
        backgroundColor: isPending ? Colors.orange.shade50 : Colors.grey.shade100,
        child: Icon(Icons.flag, color: isPending ? Colors.orange : Colors.grey, size: 20),
      ),
      title: Text(
        postTitle,
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 2),
          Text('السبب: $reason', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          Text('المُبلِّغ: $reporterPhone  •  صاحب الإعلان: $postOwnerPhone',
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
              textDirection: TextDirection.rtl),
        ],
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: isPending ? Colors.orange.shade100 : Colors.green.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              isPending ? 'معلق' : 'تمت المراجعة',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isPending ? Colors.orange.shade800 : Colors.green.shade800,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(timeStr, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
        ],
      ),
      onTap: isPending ? () => _showReportActions(report, id) : null,
    );
  }

  void _showReportActions(Map<String, dynamic> report, String reportId) {
    final postId = report['post_id'] as String?;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('إجراء على البلاغ', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('حذف الإعلان المُبلَّغ عنه'),
                onTap: () async {
                  Navigator.pop(context);
                  if (postId != null) await _adminService.deletePost(postId);
                  await FirebaseFirestore.instance.collection('reports').doc(reportId).update({'status': 'reviewed'});
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حذف الإعلان وإغلاق البلاغ')));
                },
              ),
              ListTile(
                leading: const Icon(Icons.check_circle_outline, color: Colors.green),
                title: const Text('تجاهل البلاغ (الإعلان سليم)'),
                onTap: () async {
                  Navigator.pop(context);
                  await FirebaseFirestore.instance.collection('reports').doc(reportId).update({'status': 'reviewed'});
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تجاهل البلاغ')));
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmRemoveAdmin(String uid, String display) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('إزالة الأدمن'),
        content: Text('هل تريد إزالة صلاحيات الأدمن من: $display؟'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              await _adminService.removeAdmin(uid);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم إزالة الأدمن')),
                );
              }
            },
            child: const Text('إزالة', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
