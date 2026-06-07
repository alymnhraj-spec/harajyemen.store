import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/admin_service.dart';
import '../../services/auth_service.dart';
import '../../services/post_service.dart';
import '../../theme/app_theme.dart';
import '../admin/admin_screen.dart';
import '../favorites/favorites_screen.dart';
import '../post/post_detail_screen.dart';
import '../../models/post_model.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _username = '';
  String _phone = '';

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final user = FirebaseAuth.instance.currentUser;
    final prefs = await SharedPreferences.getInstance();
    final phone = user?.phoneNumber ?? prefs.getString('user_phone') ?? '';
    final savedName = prefs.getString('username') ?? '';

    // حاول تحميل الاسم من Firestore
    String firestoreName = '';
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        firestoreName = doc.data()?['name'] ?? '';
      } catch (_) {}
    }

    if (mounted) {
      setState(() {
        _phone = phone;
        _username = firestoreName.isNotEmpty ? firestoreName : savedName;
      });
    }
  }

  Future<void> _editUsername() async {
    final controller = TextEditingController(text: _username);
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('تعديل الاسم'),
          content: TextField(
            controller: controller,
            autofocus: true,
            maxLength: 30,
            decoration: const InputDecoration(
              labelText: 'الاسم',
              hintText: 'أدخل اسمك',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, controller.text.trim()),
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );

    if (newName == null || newName.isEmpty) return;

    // حفظ محلياً
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', newName);

    // حفظ في Firestore
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({'name': newName});
      } catch (_) {}
    }

    if (mounted) setState(() => _username = newName);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('حسابي'),
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildUserCard(context, _phone),
          const SizedBox(height: 20),

          // إعلاناتي
          _buildMenuTile(
            context,
            icon: Icons.campaign_outlined,
            iconColor: AppColors.primary,
            title: 'إعلاناتي',
            subtitle: 'إعلاناتك المنشورة',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const MyAdsScreen()),
            ),
          ),
          const SizedBox(height: 10),

          // المفضلة
          _buildMenuTile(
            context,
            icon: Icons.favorite_outline,
            iconColor: Colors.red,
            title: 'المفضلة',
            subtitle: 'الإعلانات المحفوظة',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const FavoritesScreen()),
            ),
          ),
          const SizedBox(height: 10),

          // تحويل العمولة
          _buildMenuTile(
            context,
            icon: Icons.account_balance_wallet_outlined,
            iconColor: AppColors.secondary,
            title: 'تحويل العمولة',
            subtitle: 'طلب تحويل أرباحك',
            onTap: () => _showCommissionDialog(context),
          ),
          const SizedBox(height: 10),

          // تغيير كلمة المرور (للمستخدمين بالإيميل فقط)
          if (FirebaseAuth.instance.currentUser?.providerData
                  .any((p) => p.providerId == 'password') ==
              true) ...[
            _buildMenuTile(
              context,
              icon: Icons.lock_outline,
              iconColor: Colors.blue,
              title: 'تغيير كلمة المرور',
              subtitle: 'تعديل كلمة مرور حسابك',
              onTap: () => _showChangePasswordDialog(context),
            ),
            const SizedBox(height: 10),
          ],

          // الدعم
          _buildMenuTile(
            context,
            icon: Icons.support_agent_outlined,
            iconColor: AppColors.whatsapp,
            title: 'الدعم',
            subtitle: 'تواصل مع فريق الدعم',
            onTap: () => _showSupportDialog(context),
          ),
          const SizedBox(height: 10),

          // عن التطبيق
          _buildMenuTile(
            context,
            icon: Icons.info_outline,
            iconColor: AppColors.textSecondary,
            title: 'عن التطبيق',
            subtitle: 'الإصدار 1.0.1',
            onTap: () => _showAboutDialog(context),
          ),
          const SizedBox(height: 10),

          // لوحة الإدارة (للأدمن فقط)
          StreamBuilder<bool>(
            stream: AdminService().isAdminStream(),
            builder: (context, snapshot) {
              if (!(snapshot.data ?? false)) return const SizedBox.shrink();
              return Column(
                children: [
                  _buildMenuTile(
                    context,
                    icon: Icons.admin_panel_settings,
                    iconColor: AppColors.primary,
                    title: 'لوحة الإدارة',
                    subtitle: 'إدارة الإعلانات والمستخدمين',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const AdminScreen()),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              );
            },
          ),

          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => _confirmSignOut(context),
            icon: const Icon(Icons.logout, color: Colors.red),
            label: const Text('تسجيل الخروج', style: TextStyle(color: Colors.red)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.red),
              minimumSize: const Size(double.infinity, 52),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(BuildContext context, String phone) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: AppColors.primary.withValues(alpha: 0.2),
            child: Text(
              _username.isNotEmpty ? _username[0].toUpperCase() : '؟',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primary),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      _username.isNotEmpty ? _username : 'اضغط لتعيين اسمك',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: _username.isNotEmpty ? AppColors.textPrimary : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: _editUsername,
                      child: Icon(Icons.edit_outlined, size: 16, color: AppColors.primary),
                    ),
                  ],
                ),
                if (phone.isNotEmpty)
                  Text(
                    phone,
                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    textDirection: TextDirection.ltr,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuTile(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: iconColor.withValues(alpha: 0.12),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final currentPwController = TextEditingController();
    final newPwController = TextEditingController();
    final confirmPwController = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('تغيير كلمة المرور'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: currentPwController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'كلمة المرور الحالية',
                    prefixIcon: Icon(Icons.lock_outline),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: newPwController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'كلمة المرور الجديدة',
                    prefixIcon: Icon(Icons.lock_reset),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: confirmPwController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'تأكيد كلمة المرور',
                    prefixIcon: Icon(Icons.lock_reset),
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('إلغاء'),
              ),
              ElevatedButton(
                onPressed: isLoading
                    ? null
                    : () async {
                        final current = currentPwController.text.trim();
                        final newPw = newPwController.text.trim();
                        final confirm = confirmPwController.text.trim();

                        if (current.isEmpty || newPw.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('يرجى ملء جميع الحقول')),
                          );
                          return;
                        }
                        if (newPw.length < 6) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('كلمة المرور يجب أن تكون 6 أحرف على الأقل')),
                          );
                          return;
                        }
                        if (newPw != confirm) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('كلمتا المرور غير متطابقتين')),
                          );
                          return;
                        }

                        setS(() => isLoading = true);
                        try {
                          final user = FirebaseAuth.instance.currentUser!;
                          final cred = EmailAuthProvider.credential(
                            email: user.email!,
                            password: current,
                          );
                          await user.reauthenticateWithCredential(cred);
                          await user.updatePassword(newPw);
                          if (ctx.mounted) Navigator.pop(ctx);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('تم تغيير كلمة المرور بنجاح ✓'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        } on FirebaseAuthException catch (e) {
                          setS(() => isLoading = false);
                          String msg = 'حدث خطأ';
                          if (e.code == 'wrong-password') msg = 'كلمة المرور الحالية غير صحيحة';
                          if (e.code == 'weak-password') msg = 'كلمة المرور الجديدة ضعيفة جداً';
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(msg), backgroundColor: Colors.red),
                          );
                        } catch (_) {
                          setS(() => isLoading = false);
                        }
                      },
                child: isLoading
                    ? const SizedBox(width: 18, height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('حفظ'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCommissionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('تحويل العمولة'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('لطلب تحويل عمولتك، تواصل معنا عبر:'),
            SizedBox(height: 12),
            Text('واتساب: +967771074445', textDirection: TextDirection.ltr),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إغلاق')),
        ],
      ),
    );
  }

  void _showSupportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('الدعم الفني'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('للتواصل مع الدعم الفني:'),
            SizedBox(height: 12),
            Text('واتساب: +967771074445', textDirection: TextDirection.ltr),
            SizedBox(height: 6),
            Text('متاح: 8 صباحاً - 10 مساءً'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إغلاق')),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'حراج اليمن',
      applicationVersion: '1.0.1',
      applicationLegalese: '© 2025 حراج اليمن. جميع الحقوق محفوظة.',
      children: const [
        SizedBox(height: 12),
        Text('سوق الإعلانات المجانية في اليمن.\nانشر وابحث واشترِ بسهولة وأمان.'),
      ],
    );
  }

  void _confirmSignOut(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('تسجيل الخروج'),
        content: const Text('هل تريد تسجيل الخروج من حسابك؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              await AuthService().signOut();
              if (context.mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
              }
            },
            child: const Text('خروج', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// شاشة إعلاناتي
class MyAdsScreen extends StatefulWidget {
  const MyAdsScreen({super.key});

  @override
  State<MyAdsScreen> createState() => _MyAdsScreenState();
}

class _MyAdsScreenState extends State<MyAdsScreen> {
  String? _uid;

  @override
  void initState() {
    super.initState();
    _loadUid();
  }

  Future<void> _loadUid() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() => _uid = user.uid);
    } else {
      final demoUid = await AuthService.getDemoUid();
      if (mounted) setState(() => _uid = demoUid);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_uid == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('إعلاناتي')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('إعلاناتي')),
      body: StreamBuilder<List<PostModel>>(
        stream: PostService().getUserPosts(_uid!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final posts = snapshot.data ?? [];
          if (posts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.campaign_outlined, size: 80, color: AppColors.divider),
                  const SizedBox(height: 16),
                  Text('لا توجد إعلانات بعد',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.textSecondary)),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: posts.length,
            itemBuilder: (_, i) => _buildAdTile(context, posts[i]),
          );
        },
      ),
    );
  }

  Widget _buildAdTile(BuildContext context, PostModel post) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: post.images.isNotEmpty
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: post.thumbnailUrl,
                  width: 56, height: 56, fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => const Icon(Icons.image_not_supported_outlined),
                ),
              )
            : Container(
                width: 56, height: 56,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.image_not_supported_outlined, color: AppColors.textSecondary),
              ),
        title: Text(post.title,
          maxLines: 1, overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(post.priceDisplay,
          style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleAction(context, value, post),
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'view', child: Text('عرض')),
            const PopupMenuItem(value: 'sold', child: Text('تم البيع')),
            const PopupMenuItem(value: 'delete',
              child: Text('حذف', style: TextStyle(color: Colors.red))),
          ],
        ),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => PostDetailScreen(post: post)),
        ),
      ),
    );
  }

  void _handleAction(BuildContext context, String action, PostModel post) async {
    if (action == 'view') {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => PostDetailScreen(post: post)),
      );
    } else if (action == 'sold') {
      await PostService().markAsSold(post.id!);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تحديد الإعلان كمباع')));
      }
    } else if (action == 'delete') {
      await PostService().deletePost(post.id!);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حذف الإعلان')));
      }
    }
  }
}
