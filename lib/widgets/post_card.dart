import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../models/post_model.dart';
import '../theme/app_theme.dart';
import 'animations.dart';

class PostCard extends StatelessWidget {
  final PostModel post;
  final VoidCallback onTap;

  const PostCard({super.key, required this.post, required this.onTap});

  bool get _isNew => DateTime.now().difference(post.createdAt).inHours < 24;

  String get _heroTag => 'post-image-${post.id ?? post.hashCode}';

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: post.isFeatured ? AppShadows.goldGlow : AppShadows.card,
          border: post.isFeatured
              ? Border.all(color: AppColors.secondary, width: 1.6)
              : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 3, child: _buildImage()),
              Expanded(flex: 2, child: _buildInfo(context)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImage() {
    return Stack(
      fit: StackFit.expand,
      children: [
        // الصورة (مع Hero لانتقال سلس إلى صفحة التفاصيل)
        Hero(
          tag: _heroTag,
          child: post.images.isEmpty
              ? Container(
                  color: const Color(0xFFEDEFF2),
                  child: const Center(
                    child: Icon(Icons.image_not_supported_outlined,
                        size: 38, color: AppColors.textSecondary),
                  ),
                )
              : CachedNetworkImage(
                  imageUrl: post.thumbnailUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  fadeInDuration: const Duration(milliseconds: 300),
                  placeholder: (_, __) => const ShimmerArea(
                    child: ColoredBox(color: Colors.white),
                  ),
                  errorWidget: (_, __, ___) => Container(
                    color: const Color(0xFFEDEFF2),
                    child: const Center(
                      child: Icon(Icons.broken_image_outlined,
                          color: AppColors.textSecondary),
                    ),
                  ),
                ),
        ),

        // تدرّج خفيف لإعطاء عمق وقراءة أفضل للشارات
        const DecoratedBox(
          decoration: BoxDecoration(gradient: AppGradients.imageScrim),
        ),

        // شارة الفئة (يمين أعلى)
        if (post.category != null)
          Positioned(
            top: 8,
            right: 8,
            child: _GlassPill(
              child: Text(
                PostCategories.getIcon(post.category!),
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ),

        // شارة "مميز" أو "جديد" (يسار أعلى)
        if (post.isFeatured)
          const Positioned(top: 8, left: 8, child: _FeaturedBadge())
        else if (_isNew)
          const Positioned(top: 8, left: 8, child: _NewBadge()),
      ],
    );
  }

  Widget _buildInfo(BuildContext context) {
    final isFree = post.priceType == PriceType.free;
    final isNegotiable = post.priceType == PriceType.negotiable;
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            child: Text(
              post.title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    height: 1.22,
                  ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const Spacer(),
          _PricePill(text: post.priceDisplay, free: isFree, negotiable: isNegotiable),
          const SizedBox(height: 5),
          Row(
            children: [
              const Icon(Icons.location_on_outlined,
                  size: 12, color: AppColors.textSecondary),
              const SizedBox(width: 2),
              Expanded(
                child: Text(
                  post.governorateName,
                  style: Theme.of(context).textTheme.bodySmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                timeago.format(post.createdAt, locale: 'ar'),
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(fontSize: 10, color: AppColors.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// حبّة سعر: مجاني/قابل للتفاوض → تدرّج لوني، السعر العادي → تظليل خفيف للون البراند.
class _PricePill extends StatelessWidget {
  final String text;
  final bool free;
  final bool negotiable;
  const _PricePill({required this.text, required this.free, required this.negotiable});

  @override
  Widget build(BuildContext context) {
    if (free) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF43A047), Color(0xFF1B5E20)],
          ),
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: const Text(
          'مجاناً',
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12.5),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: negotiable
            ? AppColors.secondary.withValues(alpha: 0.14)
            : AppColors.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: negotiable ? AppColors.secondaryDeep : AppColors.primary,
          fontWeight: FontWeight.w800,
          fontSize: 13,
        ),
      ),
    );
  }
}

/// حبّة زجاجية شبه شفّافة فوق الصورة (أداء عالٍ بدون BackdropFilter).
class _GlassPill extends StatelessWidget {
  final Widget child;
  const _GlassPill({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _FeaturedBadge extends StatelessWidget {
  const _FeaturedBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        gradient: AppGradients.gold,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        boxShadow: AppShadows.goldGlow,
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_rounded, size: 12, color: Colors.white),
          SizedBox(width: 2),
          Text('مميز',
              style: TextStyle(
                  color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _NewBadge extends StatelessWidget {
  const _NewBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.accent,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withValues(alpha: 0.35),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Text('جديد',
          style: TextStyle(
              color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)),
    );
  }
}
