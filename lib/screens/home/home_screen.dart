import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../models/post_model.dart';
import '../../models/governorate_model.dart';
import '../../services/admin_service.dart';
import '../../services/post_service.dart';
import '../../services/location_service.dart';
import '../../services/auth_service.dart';
import '../../services/chat_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/post_card.dart';
import '../../widgets/animations.dart';
import '../post/post_detail_screen.dart';
import '../post/add_post_screen.dart';
import '../admin/admin_screen.dart';
import '../chat/conversations_screen.dart';
import '../profile/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _postService = PostService();
  final _locationService = LocationService();
  final _unreadStream = ChatService().getTotalUnread();

  String? _selectedGovernorateId;
  String _selectedCategoryId = '';
  List<GovernorateModel> _governorates = [];
  bool _isLoadingGovs = true;
  int _currentNavIndex = 0;

  final _searchController = TextEditingController();
  bool _isSearchActive = false;
  bool _isSearching = false;
  List<PostModel> _searchResults = [];

  @override
  void initState() {
    super.initState();
    _loadGovernorates();
    timeago.setLocaleMessages('ar', timeago.ArMessages());
  }

  Future<void> _loadGovernorates() async {
    final govs = await _locationService.loadGovernorates();
    if (mounted) setState(() {
      _governorates = govs;
      _isLoadingGovs = false;
    });
  }

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) {
      setState(() { _isSearching = false; _searchResults = []; });
      return;
    }
    setState(() => _isSearching = true);
    final results = await _postService.searchPosts(query);
    if (mounted) setState(() { _isSearching = false; _searchResults = results; });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool get _isWideWeb {
    if (!kIsWeb) return false;
    final width = MediaQuery.of(context).size.width;
    return width >= 700;
  }

  @override
  Widget build(BuildContext context) {
    if (_isWideWeb) return _buildWebScaffold();
    return _buildMobileScaffold();
  }

  // ==================== تخطيط الويب ====================

  Widget _buildWebScaffold() {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F7),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: _buildWebHeader(),
      ),
      body: Column(
        children: [
          _buildWebFilters(),
          Expanded(
            child: _searchController.text.trim().isNotEmpty
                ? _isSearching
                    ? const Center(child: CircularProgressIndicator())
                    : _buildWebContent(_buildWebList(_searchResults))
                : _buildWebPostsStream(),
          ),
          _buildWebFooter(),
        ],
      ),
    );
  }

  Widget _buildWebHeader() {
    return Material(
      color: AppColors.primary,
      elevation: 2,
      child: SafeArea(
        child: SizedBox(
          height: 64,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final w = constraints.maxWidth;
              return Stack(
                children: [
                  // ===== الشعار: يمين =====
                  Positioned(
                    right: 20, top: 0, bottom: 0,
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('حراج اليمن',
                              style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w800)),
                          const SizedBox(width: 8),
                          Container(
                            width: 32, height: 32,
                            decoration: BoxDecoration(
                              color: Colors.white24,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.storefront_outlined, color: Colors.white, size: 18),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // ===== الأزرار: يسار =====
                  Positioned(
                    left: 20, top: 12, bottom: 12,
                    child: StreamBuilder<bool>(
                      stream: _authStateStream(),
                      builder: (context, snap) {
                        final isLoggedIn = snap.data ?? false;
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isLoggedIn)
                              _buildWebProfileMenu(context)
                            else
                              TextButton(
                                onPressed: () => Navigator.of(context).pushNamed('/login'),
                                style: TextButton.styleFrom(
                                  backgroundColor: Colors.white24,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                child: const Text('تسجيل الدخول',
                                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                              ),
                            const SizedBox(width: 8),
                            if (isLoggedIn)
                              IconButton(
                                onPressed: () => Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => const ConversationsScreen()),
                                ),
                                icon: StreamBuilder<int>(
                                  stream: _unreadStream,
                                  builder: (context, snap) {
                                    final unread = snap.data ?? 0;
                                    return Stack(
                                      clipBehavior: Clip.none,
                                      children: [
                                        const Icon(Icons.chat_bubble_outline, color: Colors.white, size: 22),
                                        if (unread > 0)
                                          Positioned(
                                            right: -4, top: -4,
                                            child: Container(
                                              padding: const EdgeInsets.all(2),
                                              decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                                              child: Text(
                                                unread > 9 ? '9+' : '$unread',
                                                style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700),
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                          ),
                                      ],
                                    );
                                  },
                                ),
                                tooltip: 'الرسائل',
                              ),
                            const SizedBox(width: 4),
                            TextButton.icon(
                              onPressed: _openAddPost,
                              icon: Icon(Icons.add, size: 16, color: AppColors.primary),
                              label: Text('نشر إعلان',
                                  style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 13)),
                              style: TextButton.styleFrom(
                                backgroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  // ===== شريط البحث: وسط =====
                  Positioned(
                    left: w * 0.33,
                    right: w * 0.22,
                    top: 13, bottom: 13,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white38),
                      ),
                      child: TextField(
                        controller: _searchController,
                        textDirection: TextDirection.rtl,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: const InputDecoration(
                          hintText: 'ابحث عن أي شيء...',
                          hintStyle: TextStyle(color: Colors.white70, fontSize: 13),
                          prefixIcon: Icon(Icons.search, color: Colors.white70, size: 18),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                          isDense: true,
                        ),
                        onChanged: _search,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildWebProfileMenu(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final hasPasswordProvider = user?.providerData.any((p) => p.providerId == 'password') == true;
    return FutureBuilder<bool>(
      future: AdminService().isAdmin(),
      builder: (context, snap) {
        final isAdmin = snap.data ?? false;
        return PopupMenuButton<String>(
          tooltip: 'حسابي',
          offset: const Offset(0, 40),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          onSelected: (value) async {
            switch (value) {
              case 'my_ads':
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProfileScreen()));
                break;
              case 'admin':
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AdminScreen()));
                break;
              case 'change_password':
                _showWebChangePasswordDialog(context);
                break;
              case 'logout':
                await AuthService().signOut();
                if (mounted) setState(() {});
                break;
            }
          },
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'my_ads', child: Row(children: [Icon(Icons.list_alt_outlined, size: 18), SizedBox(width: 8), Text('حسابي')])),
            if (isAdmin)
              const PopupMenuItem(value: 'admin', child: Row(children: [Icon(Icons.admin_panel_settings_outlined, size: 18), SizedBox(width: 8), Text('لوحة الإدارة')])),
            if (hasPasswordProvider)
              const PopupMenuItem(value: 'change_password', child: Row(children: [Icon(Icons.lock_outline, size: 18), SizedBox(width: 8), Text('تغيير كلمة المرور')])),
            const PopupMenuDivider(),
            const PopupMenuItem(value: 'logout', child: Row(children: [Icon(Icons.logout, size: 18, color: Colors.red), SizedBox(width: 8), Text('تسجيل خروج', style: TextStyle(color: Colors.red))])),
          ],
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.person_outline, color: Colors.white, size: 18),
                const SizedBox(width: 6),
                Text(
                  user?.displayName ?? user?.email?.split('@').first ?? 'حسابي',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_drop_down, color: Colors.white, size: 18),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showWebChangePasswordDialog(BuildContext context) {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تغيير كلمة المرور'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: currentCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'كلمة المرور الحالية')),
            const SizedBox(height: 8),
            TextField(controller: newCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'كلمة المرور الجديدة')),
            const SizedBox(height: 8),
            TextField(controller: confirmCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'تأكيد كلمة المرور الجديدة')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              if (newCtrl.text != confirmCtrl.text) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('كلمتا المرور غير متطابقتين')));
                return;
              }
              try {
                final user = FirebaseAuth.instance.currentUser!;
                final cred = EmailAuthProvider.credential(email: user.email!, password: currentCtrl.text);
                await user.reauthenticateWithCredential(cred);
                await user.updatePassword(newCtrl.text);
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تغيير كلمة المرور بنجاح')));
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e')));
              }
            },
            child: const Text('تغيير'),
          ),
        ],
      ),
    );
  }

  Widget _buildWebFilters() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Column(
        children: [
          // فلتر المحافظات
          if (!_isLoadingGovs)
            SizedBox(
              height: 46,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                itemCount: _governorates.length + 1,
                itemBuilder: (_, index) {
                  if (index == 0) return _webGovChip(null, 'كل المحافظات');
                  final gov = _governorates[index - 1];
                  return _webGovChip(gov.id, gov.name);
                },
              ),
            ),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
          // فلتر الفئات
          SizedBox(
            height: 46,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
              itemCount: PostCategories.categories.length + 1,
              itemBuilder: (_, index) {
                if (index == 0) return _webCategoryChip('', 'كل الفئات', '🏷️');
                final cat = PostCategories.categories[index - 1];
                return _webCategoryChip(cat['id']!, cat['name']!, cat['icon']!);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _webGovChip(String? id, String name) {
    final isSelected = _selectedGovernorateId == id;
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: GestureDetector(
        onTap: () => setState(() => _selectedGovernorateId = id),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? AppColors.primary : const Color(0xFFDDDDDD),
            ),
          ),
          child: Text(
            name,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              color: isSelected ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _webCategoryChip(String id, String name, String icon) {
    final isSelected = _selectedCategoryId == id;
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: GestureDetector(
        onTap: () => setState(() => _selectedCategoryId = id),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.secondary.withValues(alpha: 0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? AppColors.secondary : const Color(0xFFDDDDDD),
            ),
          ),
          child: Text(
            '$icon $name',
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              color: isSelected ? AppColors.secondary : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWebPostsStream() {
    return StreamBuilder<List<PostModel>>(
      stream: _postService.getPosts(
        governorateId: _selectedGovernorateId,
        category: _selectedCategoryId.isEmpty ? null : _selectedCategoryId,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildWebContent(_buildWebShimmer());
        }
        if (snapshot.hasError) {
          return _buildWebContent(_buildError('حدث خطأ في تحميل الإعلانات'));
        }
        final posts = snapshot.data ?? [];
        if (posts.isEmpty) return _buildWebContent(_buildEmpty());
        return StreamBuilder<bool>(
          stream: AdminService().isFeaturedSectionEnabled(),
          builder: (context, enabledSnap) {
            final isEnabled = enabledSnap.data ?? false;
            if (!isEnabled) return _buildWebContent(_buildWebList(posts));
            return _buildWebContentWithFeatured(posts);
          },
        );
      },
    );
  }

  Widget _buildWebContent(Widget child) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 860),
        child: child,
      ),
    );
  }

  Widget _buildWebContentWithFeatured(List<PostModel> posts) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 860),
        child: StreamBuilder<List<Map<String, dynamic>>>(
          stream: AdminService().getFeaturedPosts(),
          builder: (context, featSnap) {
            final featured = featSnap.data ?? [];
            return CustomScrollView(
              slivers: [
                if (featured.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(0, 20, 0, 10),
                      child: Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 18),
                          const SizedBox(width: 6),
                          Text('إعلانات مميزة',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 180,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: featured.length,
                        itemBuilder: (_, i) => _buildWebFeaturedCard(featured[i]),
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 16)),
                ],
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text(
                      'جميع الإعلانات',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _buildWebListItem(posts[i]),
                    ),
                    childCount: posts.length,
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 20)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildWebList(List<PostModel> posts) {
    if (posts.isEmpty) return _buildEmpty();
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 16),
      itemCount: posts.length,
      itemBuilder: (_, i) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: _buildWebListItem(posts[i]),
      ),
    );
  }

  Widget _buildWebListItem(PostModel post) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => _openPost(post),
        child: Container(
          height: 140,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Row(
              children: [
                // الصورة (يمين بسبب RTL)
                SizedBox(
                  width: 150,
                  child: post.images.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: post.thumbnailUrl,
                          fit: BoxFit.cover,
                          placeholder: (_, __) =>
                              Container(color: const Color(0xFFF0F0F0)),
                          errorWidget: (_, __, ___) => Container(
                            color: const Color(0xFFF0F0F0),
                            child: const Icon(Icons.image_outlined,
                                color: AppColors.divider, size: 40),
                          ),
                        )
                      : Container(
                          color: const Color(0xFFF0F0F0),
                          child: const Center(
                            child: Icon(Icons.image_outlined,
                                color: AppColors.divider, size: 40),
                          ),
                        ),
                ),
                // المعلومات
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const Spacer(),
                        Text(
                          post.priceDisplay,
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w800,
                            fontSize: 17,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined,
                                size: 14, color: AppColors.textSecondary),
                            const SizedBox(width: 3),
                            Text(
                              post.governorateName,
                              style: const TextStyle(
                                  fontSize: 13, color: AppColors.textSecondary),
                            ),
                            const Spacer(),
                            Text(
                              timeago.format(post.createdAt, locale: 'ar'),
                              style: const TextStyle(
                                  fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWebFeaturedCard(Map<String, dynamic> post) {
    final images = (post['images'] as List?)?.cast<String>() ?? [];
    final title = post['title'] ?? '';
    final price = post['price'];
    final priceType = post['price_type'] ?? '';

    String priceText = '';
    if (priceType == 'free') {
      priceText = 'مجاناً';
    } else if (priceType == 'negotiable') {
      priceText = 'قابل للتفاوض';
    } else if (price != null) {
      final symbol = priceType == 'saudi' ? 'ر.س' : priceType == 'dollar' ? '\$' : 'ر.ي';
      priceText = '${price.toStringAsFixed(0)} $symbol';
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () async {
          final postModel = await _postService.getPost(post['id'] as String);
          if (postModel == null || !mounted) return;
          _openPost(postModel);
        },
        child: Container(
          width: 220,
          margin: const EdgeInsets.only(left: 12, bottom: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.amber, width: 2),
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.amber.withValues(alpha: 0.15),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      images.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: images.first,
                              fit: BoxFit.cover,
                              placeholder: (_, __) =>
                                  Container(color: const Color(0xFFF0F0F0)),
                              errorWidget: (_, __, ___) => Container(
                                color: const Color(0xFFF0F0F0),
                                child: const Icon(Icons.image_outlined,
                                    color: AppColors.divider),
                              ),
                            )
                          : Container(
                              color: const Color(0xFFF0F0F0),
                              child: const Icon(Icons.image_outlined,
                                  color: AppColors.divider),
                            ),
                      Positioned(
                        top: 8, right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.amber,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.star, size: 11, color: Colors.white),
                              SizedBox(width: 3),
                              Text('مميز',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 13)),
                        const Spacer(),
                        if (priceText.isNotEmpty)
                          Text(priceText,
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              )),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWebShimmer() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 16),
      itemCount: 5,
      itemBuilder: (_, __) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: ShimmerArea(
          child: Container(
            height: 140,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Row(
              children: [
                Container(
                  width: 150,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.horizontal(right: Radius.circular(AppRadius.lg)),
                  ),
                ),
                const Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ShimmerBox(height: 16, width: double.infinity),
                        SizedBox(height: 8),
                        ShimmerBox(height: 14, width: 200),
                        Spacer(),
                        ShimmerBox(height: 18, width: 120),
                        SizedBox(height: 8),
                        ShimmerBox(height: 12, width: 160),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWebFooter() {
    return Container(
      color: AppColors.primary,
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: const Center(
        child: Text(
          '© 2025 حراج اليمن — سوق الإعلانات المجانية',
          style: TextStyle(color: Colors.white70, fontSize: 13),
        ),
      ),
    );
  }

  // ==================== تخطيط الموبايل ====================

  Widget _buildMobileScaffold() {
    if (_currentNavIndex == 3) {
      return Scaffold(
        body: const ConversationsScreen(),
        bottomNavigationBar: _buildBottomNav(),
        floatingActionButton: _buildFab(),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      );
    }
    if (_currentNavIndex == 4) {
      return Scaffold(
        body: const ProfileScreen(),
        bottomNavigationBar: _buildBottomNav(),
        floatingActionButton: _buildFab(),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      );
    }

    return Scaffold(
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildGovernorateFilter(),
          _buildCategoryFilter(),
          Expanded(
            child: _searchController.text.trim().isNotEmpty
                ? _isSearching
                    ? const Center(child: CircularProgressIndicator())
                    : _buildSearchResults()
                : _buildPostsGrid(),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
      floatingActionButton: _buildFab(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: AppGradients.brand,
          boxShadow: const [
            BoxShadow(color: Color(0x1F000000), blurRadius: 8, offset: Offset(0, 2)),
          ],
        ),
      ),
      title: _isSearchActive
          ? TextField(
              controller: _searchController,
              autofocus: true,
              textDirection: TextDirection.rtl,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              decoration: const InputDecoration(
                hintText: 'ابحث عن أي شيء...',
                hintStyle: TextStyle(color: Colors.white70),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
              ),
              onChanged: _search,
            )
          : const Text('حراج اليمن 🇾🇪'),
      actions: [
        IconButton(
          icon: Icon(_isSearchActive ? Icons.close : Icons.search),
          onPressed: () {
            setState(() {
              if (_isSearchActive) {
                _searchController.clear();
                _isSearchActive = false;
                _isSearching = false;
                _searchResults = [];
              } else {
                _isSearchActive = true;
              }
            });
          },
        ),
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          onPressed: () => _showNotificationsSheet(),
        ),
      ],
    );
  }

  Widget _buildGovernorateFilter() {
    if (_isLoadingGovs) return const SizedBox(height: 50);
    return Container(
      color: Colors.white,
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: _governorates.length + 1,
        itemBuilder: (_, index) {
          if (index == 0) return _govChip(null, 'الكل');
          final gov = _governorates[index - 1];
          return _govChip(gov.id, gov.name);
        },
      ),
    );
  }

  Widget _govChip(String? id, String name) {
    final isSelected = _selectedGovernorateId == id;
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: PressableScale(
        scale: 0.92,
        onTap: () => setState(() => _selectedGovernorateId = id),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 7),
          decoration: BoxDecoration(
            gradient: isSelected ? AppGradients.brand : null,
            color: isSelected ? null : Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.divider,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.28),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Text(
            name,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return SizedBox(
      height: 48,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        itemCount: PostCategories.categories.length + 1,
        itemBuilder: (_, index) {
          if (index == 0) return _categoryChip('', 'الكل', '🏷️');
          final cat = PostCategories.categories[index - 1];
          return _categoryChip(cat['id']!, cat['name']!, cat['icon']!);
        },
      ),
    );
  }

  Widget _categoryChip(String id, String name, String icon) {
    final isSelected = _selectedCategoryId == id;
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: PressableScale(
        scale: 0.92,
        onTap: () => setState(() => _selectedCategoryId = id),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.secondary.withValues(alpha: 0.16)
                : Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(
              color: isSelected ? AppColors.secondaryDeep : AppColors.divider,
            ),
          ),
          child: Text(
            '$icon $name',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? AppColors.secondaryDeep : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPostsGrid() {
    return StreamBuilder<List<PostModel>>(
      stream: _postService.getPosts(
        governorateId: _selectedGovernorateId,
        category: _selectedCategoryId.isEmpty ? null : _selectedCategoryId,
        limit: 40,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildShimmerGrid();
        }
        if (snapshot.hasError) {
          return _buildError('حدث خطأ في تحميل الإعلانات');
        }
        final posts = snapshot.data ?? [];
        if (posts.isEmpty) return _buildEmpty();
        return RefreshIndicator(
          onRefresh: () async => setState(() {}),
          child: _buildGridWithFeatured(posts),
        );
      },
    );
  }

  Widget _buildGridWithFeatured(List<PostModel> posts) {
    return StreamBuilder<bool>(
      stream: AdminService().isFeaturedSectionEnabled(),
      builder: (context, enabledSnap) {
        final isEnabled = enabledSnap.data ?? false;
        if (!isEnabled) return _buildPlainGrid(posts);
        return _buildGridWithFeaturedPosts(posts);
      },
    );
  }

  Widget _buildPlainGrid(List<PostModel> posts) {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 0.68,
      ),
      itemCount: posts.length,
      itemBuilder: (_, i) => FadeSlideIn(
        index: i,
        child: PostCard(post: posts[i], onTap: () => _openPost(posts[i])),
      ),
    );
  }

  Widget _buildGridWithFeaturedPosts(List<PostModel> posts) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: AdminService().getFeaturedPosts(),
      builder: (context, featSnap) {
        final featured = featSnap.data ?? [];
        return CustomScrollView(
          slivers: [
            if (featured.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
                  child: Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 18),
                      const SizedBox(width: 6),
                      Text('إعلانات مميزة',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          )),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 160,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: featured.length,
                    itemBuilder: (_, i) => _buildFeaturedCard(featured[i]),
                  ),
                ),
              ),
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(12, 10, 12, 4),
                  child: Divider(),
                ),
              ),
            ],
            SliverPadding(
              padding: const EdgeInsets.all(12),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 0.68,
                ),
                delegate: SliverChildBuilderDelegate(
                  (_, i) => FadeSlideIn(
                    index: i,
                    child: PostCard(post: posts[i], onTap: () => _openPost(posts[i])),
                  ),
                  childCount: posts.length,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFeaturedCard(Map<String, dynamic> post) {
    final images = (post['images'] as List?)?.cast<String>() ?? [];
    final title = post['title'] ?? '';
    final price = post['price'];
    final priceType = post['price_type'] ?? '';

    String priceText = '';
    if (priceType == 'free') {
      priceText = 'مجاناً';
    } else if (priceType == 'negotiable') {
      priceText = 'قابل للتفاوض';
    } else if (price != null) {
      final symbol = priceType == 'saudi' ? 'ر.س' : priceType == 'dollar' ? '\$' : 'ر.ي';
      priceText = '${price.toStringAsFixed(0)} $symbol';
    }

    return GestureDetector(
      onTap: () async {
        final postModel = await _postService.getPost(post['id'] as String);
        if (postModel == null || !mounted) return;
        _openPost(postModel);
      },
      child: Container(
        width: 200,
        margin: const EdgeInsets.only(left: 10, bottom: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.amber, width: 2),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.amber.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    images.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: images.first,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(color: AppColors.background),
                            errorWidget: (_, __, ___) => Container(
                              color: AppColors.background,
                              child: const Icon(Icons.image_outlined, color: AppColors.divider),
                            ),
                          )
                        : Container(
                            color: AppColors.background,
                            child: const Icon(Icons.image_outlined, color: AppColors.divider),
                          ),
                    Positioned(
                      top: 6, right: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.amber,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.star, size: 10, color: Colors.white),
                            SizedBox(width: 2),
                            Text('مميز',
                                style: TextStyle(
                                    color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                      if (priceText.isNotEmpty)
                        Text(priceText,
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            )),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_searchResults.isEmpty) return _buildEmpty(message: 'لا توجد نتائج للبحث');
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 0.68,
      ),
      itemCount: _searchResults.length,
      itemBuilder: (_, i) => FadeSlideIn(
        index: i,
        child: PostCard(post: _searchResults[i], onTap: () => _openPost(_searchResults[i])),
      ),
    );
  }

  void _openPost(PostModel post) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => PostDetailScreen(post: post),
    ));
  }

  Widget _buildShimmerGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 0.68,
      ),
      itemCount: 6,
      itemBuilder: (_, __) => const PostCardSkeleton(),
    );
  }

  Widget _buildError(String message) {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.error_outline, size: 60, color: AppColors.textSecondary),
      const SizedBox(height: 16),
      Text(message, style: Theme.of(context).textTheme.bodyLarge),
    ]));
  }

  Widget _buildEmpty({String? message}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.6, end: 1.0),
            duration: const Duration(milliseconds: 600),
            curve: Curves.elasticOut,
            builder: (_, value, child) => Transform.scale(scale: value, child: child),
            child: Container(
              width: 128,
              height: 128,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.07),
              ),
              child: Icon(Icons.inbox_outlined,
                  size: 64, color: AppColors.primary.withValues(alpha: 0.55)),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            message ?? 'لا توجد إعلانات بعد',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            'كن أول من ينشر هنا 👋',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  BottomNavigationBar _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: _currentNavIndex,
      onTap: (i) {
        if (i == 2) return;
        if (i == 1) {
          setState(() { _currentNavIndex = 0; _isSearchActive = true; });
          return;
        }
        setState(() => _currentNavIndex = i);
      },
      items: [
        const BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'الرئيسية'),
        const BottomNavigationBarItem(icon: Icon(Icons.search_outlined), activeIcon: Icon(Icons.search), label: 'بحث'),
        const BottomNavigationBarItem(icon: SizedBox.shrink(), label: ''),
        BottomNavigationBarItem(
          icon: StreamBuilder<int>(
            stream: _unreadStream,
            builder: (context, snapshot) {
              final unread = snapshot.data ?? 0;
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.chat_bubble_outline),
                  if (unread > 0)
                    Positioned(
                      right: -6, top: -4,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                        constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                        child: Text(
                          unread > 9 ? '9+' : '$unread',
                          style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          activeIcon: StreamBuilder<int>(
            stream: _unreadStream,
            builder: (context, snapshot) {
              final unread = snapshot.data ?? 0;
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.chat_bubble),
                  if (unread > 0)
                    Positioned(
                      right: -6, top: -4,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                        constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                        child: Text(
                          unread > 9 ? '9+' : '$unread',
                          style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          label: 'الرسائل',
        ),
        const BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'حسابي'),
      ],
    );
  }

  Widget _buildFab() {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppGradients.brandVibrant,
        boxShadow: AppShadows.brandGlow,
      ),
      child: FloatingActionButton(
        onPressed: _openAddPost,
        backgroundColor: Colors.transparent,
        elevation: 0,
        highlightElevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        child: const Icon(Icons.add, color: Colors.white, size: 30),
      ),
    );
  }

  Stream<bool> _authStateStream() async* {
    final isDemo = await AuthService.isDemoUser();
    if (isDemo) { yield true; return; }
    yield* FirebaseAuth.instance.authStateChanges().map((u) => u != null);
  }

  void _showNotificationsSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Icon(Icons.notifications_outlined, color: AppColors.primary),
                  const SizedBox(width: 8),
                  const Text('الإشعارات', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
            const Divider(height: 1),
            StreamBuilder(
              stream: FirebaseAuth.instance.authStateChanges(),
              builder: (ctx, snap) {
                final user = FirebaseAuth.instance.currentUser;
                if (user == null) {
                  return const Padding(
                    padding: EdgeInsets.all(32),
                    child: Text('سجّل دخول لرؤية الإشعارات', style: TextStyle(color: AppColors.textSecondary)),
                  );
                }
                return StreamBuilder(
                  stream: FirebaseFirestore.instance
                      .collection('notifications')
                      .where('user_id', isEqualTo: user.uid)
                      .orderBy('created_at', descending: true)
                      .limit(20)
                      .snapshots(),
                  builder: (ctx2, snap2) {
                    if (snap2.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.all(32),
                        child: CircularProgressIndicator(),
                      );
                    }
                    final docs = snap2.data?.docs ?? [];
                    if (docs.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.all(32),
                        child: Text('لا توجد إشعارات', style: TextStyle(color: AppColors.textSecondary)),
                      );
                    }
                    return ListView.separated(
                      shrinkWrap: true,
                      itemCount: docs.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (_, i) {
                        final data = docs[i].data();
                        final ts = (data['created_at'] as Timestamp?)?.toDate();
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppColors.primary,
                            child: const Icon(Icons.notifications, color: Colors.white, size: 18),
                          ),
                          title: Text(data['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                          subtitle: Text(data['body'] ?? '', style: const TextStyle(fontSize: 12)),
                          trailing: ts != null
                              ? Text('${ts.day}/${ts.month}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary))
                              : null,
                        );
                      },
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _openAddPost() async {
    final user = FirebaseAuth.instance.currentUser;
    final isDemo = await AuthService.isDemoUser();
    if (user == null && !isDemo) {
      if (mounted) Navigator.of(context).pushNamed('/login');
      return;
    }
    if (mounted) Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AddPostScreen()));
  }
}
