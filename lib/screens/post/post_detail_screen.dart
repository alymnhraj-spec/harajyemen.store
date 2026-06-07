import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/post_model.dart';
import '../../services/post_service.dart';
import '../../services/favorites_service.dart';
import '../../services/chat_service.dart';
import '../../theme/app_theme.dart';
import '../chat/chat_screen.dart';
import 'edit_post_screen.dart';

class PostDetailScreen extends StatefulWidget {
  final PostModel post;

  const PostDetailScreen({super.key, required this.post});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  int _currentImageIndex = 0;
  late PostModel _post;
  final _favService = FavoritesService();
  String _myUid = '';
  String _myPhone = '';

  @override
  void initState() {
    super.initState();
    _post = widget.post;
    _incrementViewCount();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    final user = FirebaseAuth.instance.currentUser;
    final prefs = await SharedPreferences.getInstance();
    final uid = user?.uid ?? prefs.getString('demo_uid') ?? '';
    final phone = user?.phoneNumber ?? prefs.getString('user_phone') ?? '';
    if (mounted) setState(() { _myUid = uid; _myPhone = phone; });
    await _checkAdmin();
  }

  Future<void> _incrementViewCount() async {
    if (_post.id != null) {
      await PostService().incrementViewCount(_post.id!);
    }
  }

  // الاتصال المباشر
  Future<void> _callSeller() async {
    final phone = _post.userPhone.trim();
    if (phone.isEmpty) {
      _showSnack('رقم الهاتف غير متوفر');
      return;
    }
    try {
      final uri = Uri(scheme: 'tel', path: phone);
      await launchUrl(uri);
    } catch (_) {
      _showSnack('تعذر فتح الهاتف');
    }
  }

  // مراسلة واتساب
  Future<void> _whatsappSeller() async {
    final phone = _post.userPhone.replaceAll('+', '').replaceAll(' ', '').trim();
    if (phone.isEmpty) {
      _showSnack('رقم الهاتف غير متوفر');
      return;
    }
    try {
      final message = Uri.encodeComponent(
        'مرحباً، رأيت إعلانك "${_post.title}" في حراج اليمن وأريد الاستفسار',
      );
      final uri = Uri.parse('https://wa.me/$phone?text=$message');
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      _showSnack('تعذر فتح واتساب');
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _openImageFullscreen(int initialIndex) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black,
        pageBuilder: (_, __, ___) => _FullscreenImageViewer(
          images: _post.images,
          initialIndex: initialIndex,
        ),
      ),
    );
  }

  bool get _isOwner {
    final isRealUser = FirebaseAuth.instance.currentUser != null;
    // مستخدم Firebase حقيقي: تطابق UID أو رقم الهاتف
    if (isRealUser) {
      if (_myUid.isNotEmpty && _myUid == _post.userId) return true;
      if (_myPhone.isNotEmpty && _myPhone == _post.userPhone) return true;
      return false;
    }
    // مستخدم Demo (أرقام الاختبار): تطابق الهاتف فقط (ليس UID المشترك)
    if (_myPhone.isNotEmpty && _myPhone == _post.userPhone) return true;
    return false;
  }

  bool _isAdmin = false;

  Future<void> _checkAdmin() async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? _myUid;
    if (uid.isEmpty) return;
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (mounted) setState(() => _isAdmin = (doc.data()?['is_admin'] as bool?) ?? false);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          // صور الإعلان مع AppBar شفاف
          SliverAppBar(
            expandedHeight: 320,
            pinned: true,
            backgroundColor: AppColors.primary,
            leading: IconButton(
              icon: const CircleAvatar(
                backgroundColor: Colors.black45,
                child: Icon(Icons.arrow_back, color: Colors.white, size: 20),
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            actions: [
              if (_isOwner)
                PopupMenuButton<String>(
                  icon: const CircleAvatar(
                    backgroundColor: Colors.black45,
                    child: Icon(Icons.more_vert, color: Colors.white, size: 20),
                  ),
                  onSelected: _handlePostAction,
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'edit', child: Text('تعديل الإعلان')),
                    const PopupMenuItem(value: 'renew', child: Text('تجديد الإعلان')),
                    const PopupMenuItem(value: 'sold', child: Text('تم البيع')),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('حذف الإعلان', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              if (!_isOwner && _post.id != null)
                StreamBuilder<bool>(
                  stream: _favService.isFavorite(_post.id!),
                  builder: (context, snapshot) {
                    final isFav = snapshot.data ?? false;
                    return IconButton(
                      icon: CircleAvatar(
                        backgroundColor: Colors.black45,
                        child: Icon(
                          isFav ? Icons.favorite : Icons.favorite_border,
                          color: isFav ? Colors.red : Colors.white,
                          size: 20,
                        ),
                      ),
                      onPressed: () async {
                        if (isFav) {
                          await _favService.removeFavorite(_post.id!);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('تم الحذف من المفضلة')),
                            );
                          }
                        } else {
                          await _favService.addFavorite(_post);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('تم الإضافة إلى المفضلة ❤️')),
                            );
                          }
                        }
                      },
                    );
                  },
                ),
              IconButton(
                icon: const CircleAvatar(
                  backgroundColor: Colors.black45,
                  child: Icon(Icons.share_outlined, color: Colors.white, size: 20),
                ),
                onPressed: _sharePost,
              ),
              if (!_isOwner)
                IconButton(
                  tooltip: 'إبلاغ',
                  icon: const CircleAvatar(
                    backgroundColor: Colors.black45,
                    child: Icon(Icons.flag_outlined, color: Colors.orangeAccent, size: 20),
                  ),
                  onPressed: _showReportDialog,
                ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: _buildImageSlider(),
            ),
          ),

          // تفاصيل الإعلان
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // السعر والعنوان
                  _buildPriceSection(),
                  const SizedBox(height: 12),
                  Text(
                    _post.title,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),

                  // المعلومات السريعة
                  _buildQuickInfo(),
                  const Divider(height: 28),

                  // الوصف
                  Text(
                    'تفاصيل الإعلان',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _post.description,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      height: 1.6,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const Divider(height: 28),

                  // معلومات البائع
                  _buildSellerCard(),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),

      // أزرار التواصل السفلية
      bottomNavigationBar: _buildContactButtons(),
    );
  }

  Widget _buildImageSlider() {
    if (_post.images.isEmpty) {
      return Container(
        color: AppColors.background,
        child: const Center(
          child: Icon(Icons.image_outlined, size: 80, color: AppColors.divider),
        ),
      );
    }

    return Stack(
      children: [
        CarouselSlider.builder(
          itemCount: _post.images.length,
          options: CarouselOptions(
            height: double.infinity,
            viewportFraction: 1.0,
            enableInfiniteScroll: _post.images.length > 1,
            onPageChanged: (index, _) =>
                setState(() => _currentImageIndex = index),
          ),
          itemBuilder: (_, index, __) {
            Widget image = CachedNetworkImage(
              imageUrl: _post.images[index],
              fit: BoxFit.cover,
              width: double.infinity,
              placeholder: (_, __) => Container(color: AppColors.background),
              errorWidget: (_, __, ___) => Container(
                color: AppColors.background,
                child: const Icon(Icons.broken_image, size: 60, color: AppColors.divider),
              ),
            );
            // أول صورة ترث Hero لانتقال سلس من بطاقة الإعلان.
            if (index == 0 && _post.id != null) {
              image = Hero(tag: 'post-image-${_post.id}', child: image);
            }
            return GestureDetector(
              onTap: () => _openImageFullscreen(index),
              child: image,
            );
          },
        ),

        // مؤشر الصور
        if (_post.images.length > 1)
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _post.images.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: i == _currentImageIndex ? 20 : 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: i == _currentImageIndex
                        ? Colors.white
                        : Colors.white54,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPriceSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            _post.priceDisplay,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        if (_post.status == PostStatus.sold)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: const Text(
              'تم البيع',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
            ),
          ),
      ],
    );
  }

  Widget _buildQuickInfo() {
    int? daysLeft;
    if (_isOwner && _post.expiresAt != null) {
      daysLeft = _post.expiresAt!.difference(DateTime.now()).inDays;
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _infoChip(Icons.location_on_outlined, _post.governorateName),
        if (_post.category != null)
          _infoChip(Icons.category_outlined, PostCategories.getName(_post.category!)),
        _infoChip(Icons.remove_red_eye_outlined, '${_post.viewCount} مشاهدة'),
        if (daysLeft != null)
          _infoChip(
            Icons.timer_outlined,
            daysLeft > 0 ? 'ينتهي بعد $daysLeft يوم' : 'انتهت صلاحيته',
            color: daysLeft <= 7 ? Colors.orange : null,
          ),
        _infoChip(Icons.access_time_outlined, _formatDate(_post.createdAt)),
      ],
    );
  }

  Widget _infoChip(IconData icon, String label, {Color? color}) {
    final c = color ?? AppColors.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color != null ? color.withValues(alpha: 0.08) : AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: color != null ? Border.all(color: color.withValues(alpha: 0.4)) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: c),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: c),
          ),
        ],
      ),
    );
  }

  Widget _buildSellerCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.primary.withValues(alpha: 0.2),
            radius: 24,
            child: Icon(Icons.person, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _post.userName ?? 'بائع',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  _post.governorateName,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _adminIconBtn(IconData icon, Color iconColor, Color bgColor, VoidCallback onTap, {bool outlined = false}) {
    return Expanded(
      child: SizedBox(
        height: 48,
        child: outlined
            ? OutlinedButton(
                onPressed: onTap,
                style: OutlinedButton.styleFrom(
                  foregroundColor: iconColor,
                  side: BorderSide(color: bgColor),
                  padding: EdgeInsets.zero,
                ),
                child: Icon(icon, size: 22),
              )
            : ElevatedButton(
                onPressed: onTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: bgColor,
                  padding: EdgeInsets.zero,
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
      ),
    );
  }

  Widget _buildContactButtons() {
    // صاحب الإعلان: أزرار إدارة الإعلان فقط
    if (_isOwner) {
      if (_post.status == PostStatus.sold) {
        return Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          decoration: const BoxDecoration(
            color: Colors.white,
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, -2))],
          ),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_outline, color: Colors.grey),
                SizedBox(width: 8),
                Text('تم البيع', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600, fontSize: 16)),
              ],
            ),
          ),
        );
      }
      return Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, -2))],
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _handlePostAction('delete'),
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                label: const Text('حذف'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  minimumSize: const Size(0, 52),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: _confirmMarkSold,
                icon: const Icon(Icons.check_circle_outline, color: Colors.white),
                label: const Text('تم البيع'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                  minimumSize: const Size(0, 52),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // الإعلان مباع - لا توجد أزرار للزوار والأدمن
    if (_post.status == PostStatus.sold) {
      return const SizedBox.shrink();
    }

    // أزرار التواصل للجميع (مستخدم عادي + أدمن)
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, -2))],
      ),
      child: Row(
        children: [
          if (_isAdmin) ...[
            // أدمن: أيقونات فقط بدون نص
            _adminIconBtn(Icons.delete_outline, Colors.red, Colors.red, () => _handlePostAction('delete'), outlined: true),
            const SizedBox(width: 8),
            _adminIconBtn(Icons.call_outlined, AppColors.primary, AppColors.primary, _callSeller, outlined: true),
            const SizedBox(width: 8),
            _adminIconBtn(Icons.chat_bubble_outline, Colors.white, AppColors.secondary, _openChat),
            const SizedBox(width: 8),
            _adminIconBtn(Icons.chat, Colors.white, AppColors.whatsapp, _whatsappSeller),
          ] else ...[
            // مستخدم عادي: أزرار مع نص
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _callSeller,
                icon: const Icon(Icons.call_outlined, size: 18),
                label: const Text('اتصال'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: BorderSide(color: AppColors.primary),
                  minimumSize: const Size(0, 52),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _openChat,
                icon: const Icon(Icons.chat_bubble_outline, color: Colors.white, size: 18),
                label: const Text('دردشة'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  minimumSize: const Size(0, 52),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _whatsappSeller,
                icon: const Icon(Icons.chat, color: Colors.white, size: 18),
                label: const Text('واتساب'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.whatsapp,
                  minimumSize: const Size(0, 52),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _openChat() async {
    if (_post.id == null) return;

    final user = FirebaseAuth.instance.currentUser;
    final prefs = await SharedPreferences.getInstance();
    final isDemo = prefs.getBool('is_demo_user') ?? false;

    if (user == null && !isDemo) {
      Navigator.of(context).pushNamed('/login');
      return;
    }

    try {
      final convId = await ChatService().createOrGetConversation(
        otherUid: _post.userId,
        otherPhone: _post.userPhone,
        postTitle: _post.title,
        postImage: _post.images.isNotEmpty ? _post.images.first : '',
      );
      if (mounted) {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => ChatScreen(
            conversationId: convId,
            otherUserPhone: _post.userPhone,
            postTitle: _post.title,
            postImage: _post.images.isNotEmpty ? _post.images.first : '',
          ),
        ));
      }
    } catch (e) {
      if (mounted) _showSnack('تعذر فتح المحادثة');
    }
  }

  void _sharePost() {
    final title = _post.title;
    final price = '\nالسعر: ${_post.priceDisplay}';
    const link = 'https://haraj-yemen-app.web.app';
    Share.share('$title$price\n\nشاهد الإعلان على حراج اليمن:\n$link');
  }

  Future<void> _showReportDialog() async {
    String? selectedReason;
    final reasons = [
      'محتوى مسيء أو غير لائق',
      'احتيال أو نصب',
      'إعلان مكرر',
      'منتج مزور أو محظور',
      'معلومات مضللة',
      'أخرى',
    ];

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Row(
              children: [
                Icon(Icons.flag, color: Colors.orange, size: 22),
                SizedBox(width: 8),
                Text('إبلاغ عن الإعلان', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('اختر سبب الإبلاغ:', style: TextStyle(fontSize: 13, color: Colors.grey)),
                const SizedBox(height: 8),
                ...reasons.map((r) => RadioListTile<String>(
                  value: r,
                  groupValue: selectedReason,
                  onChanged: (v) => setS(() => selectedReason = v),
                  title: Text(r, style: const TextStyle(fontSize: 13)),
                  activeColor: Colors.orange,
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                )),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('إلغاء'),
              ),
              ElevatedButton(
                onPressed: selectedReason == null ? null : () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                child: const Text('إرسال البلاغ', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed == true && selectedReason != null && _post.id != null) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final uid = FirebaseAuth.instance.currentUser?.uid ?? prefs.getString('demo_uid') ?? '';
        final phone = FirebaseAuth.instance.currentUser?.phoneNumber ?? prefs.getString('user_phone') ?? '';

        // حفظ البلاغ في Firestore
        await FirebaseFirestore.instance.collection('reports').add({
          'post_id': _post.id,
          'post_title': _post.title,
          'post_owner_id': _post.userId,
          'post_owner_phone': _post.userPhone,
          'reporter_uid': uid,
          'reporter_phone': phone,
          'reason': selectedReason,
          'status': 'pending',
          'created_at': FieldValue.serverTimestamp(),
        });

        // إشعار للأدمن
        await FirebaseFirestore.instance.collection('admin_notifications').add({
          'type': 'report',
          'title': 'بلاغ جديد على إعلان',
          'body': 'إعلان: ${_post.title}\nالسبب: $selectedReason',
          'post_id': _post.id,
          'created_at': FieldValue.serverTimestamp(),
          'read': false,
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم إرسال البلاغ، سيتم مراجعته من قِبل الإدارة'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (_) {
        if (mounted) _showSnack('تعذر إرسال البلاغ، حاول لاحقاً');
      }
    }
  }

  void _confirmMarkSold() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('تم البيع؟'),
        content: const Text(
          'هل تأكد أن هذا الإعلان تم بيعه؟\nسيتوقف الناس عن الاتصال بك بشأنه.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade600),
            onPressed: () async {
              Navigator.pop(context);
              await PostService().markAsSold(_post.id!);
              if (mounted) {
                setState(() => _post = _post.copyWith(status: PostStatus.sold));
              }
            },
            child: const Text('نعم، تم البيع', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _handlePostAction(String action) async {
    if (action == 'edit') {
      if (_post.id == null) return;
      final result = await Navigator.of(context).push<bool>(
        MaterialPageRoute(builder: (_) => EditPostScreen(post: _post)),
      );
      if (result == true && mounted) {
        final updated = await PostService().getPost(_post.id!);
        if (updated != null && mounted) setState(() => _post = updated);
      }
    } else if (action == 'renew') {
      if (_post.id == null) return;
      final confirm = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('تجديد الإعلان'),
          content: const Text('سيتم تمديد صلاحية الإعلان 90 يوماً إضافية. هل تريد المتابعة؟'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('تجديد'),
            ),
          ],
        ),
      );
      if (confirm == true) {
        await PostService().renewPost(_post.id!);
        final updated = await PostService().getPost(_post.id!);
        if (updated != null && mounted) {
          setState(() => _post = updated);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم تجديد الإعلان بنجاح ✓'), backgroundColor: Colors.green),
          );
        }
      }
    } else if (action == 'sold') {
      await PostService().markAsSold(_post.id!);
      setState(() => _post = _post.copyWith(status: PostStatus.sold));
    } else if (action == 'delete') {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('تأكيد الحذف'),
          content: const Text('هل أنت متأكد من حذف هذا الإعلان؟'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('حذف', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );
      if (confirm == true && _post.id != null) {
        await PostService().deletePost(_post.id!);
        if (mounted) Navigator.of(context).pop();
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

// ===== عارض الصورة كاملة =====
class _FullscreenImageViewer extends StatefulWidget {
  final List<String> images;
  final int initialIndex;

  const _FullscreenImageViewer({
    required this.images,
    required this.initialIndex,
  });

  @override
  State<_FullscreenImageViewer> createState() => _FullscreenImageViewerState();
}

class _FullscreenImageViewerState extends State<_FullscreenImageViewer> {
  late int _currentIndex;
  late PageController _controller;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _controller = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: widget.images.length > 1
            ? Text(
                '${_currentIndex + 1} / ${widget.images.length}',
                style: const TextStyle(color: Colors.white, fontSize: 14),
              )
            : null,
      ),
      body: PageView.builder(
        controller: _controller,
        itemCount: widget.images.length,
        onPageChanged: (i) => setState(() => _currentIndex = i),
        itemBuilder: (_, i) => InteractiveViewer(
          minScale: 0.5,
          maxScale: 5.0,
          child: Center(
            child: CachedNetworkImage(
              imageUrl: widget.images[i],
              fit: BoxFit.contain,
              placeholder: (_, __) => const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
              errorWidget: (_, __, ___) => const Icon(
                Icons.broken_image,
                color: Colors.white54,
                size: 80,
              ),
            ),
          ),
        ),
      ),
      // نقاط الصفحات في الأسفل
      bottomNavigationBar: widget.images.length > 1
          ? Container(
              color: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  widget.images.length,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: i == _currentIndex ? 20 : 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: i == _currentIndex ? Colors.white : Colors.white38,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            )
          : null,
    );
  }
}
