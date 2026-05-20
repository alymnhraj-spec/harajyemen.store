import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../models/post_model.dart';
import '../theme/app_theme.dart';

class PostCard extends StatelessWidget {
  final PostModel post;
  final VoidCallback onTap;

  const PostCard({super.key, required this.post, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 3, child: _buildImage()),
            Expanded(flex: 2, child: _buildInfo(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildImage() {
    if (post.images.isEmpty) {
      return Container(
        color: AppColors.divider,
        child: const Center(
          child: Icon(Icons.image_not_supported_outlined, size: 40, color: AppColors.textSecondary),
        ),
      );
    }
    return CachedNetworkImage(
      imageUrl: post.thumbnailUrl,
      fit: BoxFit.cover,
      width: double.infinity,
      placeholder: (_, __) => Container(color: AppColors.divider),
      errorWidget: (_, __, ___) => Container(
        color: AppColors.divider,
        child: const Center(child: Icon(Icons.broken_image_outlined, color: AppColors.textSecondary)),
      ),
    );
  }

  Widget _buildInfo(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            post.title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const Spacer(),
          Text(
            post.priceDisplay,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 12, color: AppColors.textSecondary),
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
                style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
