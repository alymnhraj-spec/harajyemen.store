import 'package:flutter/material.dart';
import '../../models/post_model.dart';
import '../../services/favorites_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/post_card.dart';
import '../post/post_detail_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final _favService = FavoritesService();
  List<PostModel> _posts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final posts = await _favService.getFavoritePosts();
    if (mounted) setState(() { _posts = posts; _isLoading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('المفضلة')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _posts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.favorite_border, size: 80, color: AppColors.divider),
                      const SizedBox(height: 16),
                      Text('لا توجد إعلانات محفوظة',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppColors.textSecondary,
                          )),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: GridView.builder(
                    padding: const EdgeInsets.all(12),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 0.68,
                    ),
                    itemCount: _posts.length,
                    itemBuilder: (_, i) => PostCard(
                      post: _posts[i],
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => PostDetailScreen(post: _posts[i])),
                      ),
                    ),
                  ),
                ),
    );
  }
}
