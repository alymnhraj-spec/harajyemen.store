import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shimmer/shimmer.dart';
import '../theme/app_theme.dart';

/// لمسة تفاعلية: يتقلّص العنصر قليلاً عند الضغط مع ارتداد ناعم.
/// يجعل كل بطاقة/زر يبدو "حيّاً" وملموساً (GPU-accelerated).
class PressableScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scale;
  final Duration duration;
  final bool haptic;
  final BorderRadius? borderRadius;

  const PressableScale({
    super.key,
    required this.child,
    this.onTap,
    this.scale = 0.96,
    this.duration = const Duration(milliseconds: 120),
    this.haptic = true,
    this.borderRadius,
  });

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
    lowerBound: 0.0,
    upperBound: 1.0,
    value: 0.0,
  );

  late final Animation<double> _scale = Tween<double>(
    begin: 1.0,
    end: widget.scale,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _down(_) => _controller.forward();
  void _up(_) => _controller.reverse();
  void _cancel() => _controller.reverse();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.onTap == null ? null : _down,
      onTapUp: widget.onTap == null ? null : _up,
      onTapCancel: widget.onTap == null ? null : _cancel,
      onTap: widget.onTap == null
          ? null
          : () {
              if (widget.haptic) HapticFeedback.lightImpact();
              widget.onTap!();
            },
      child: ScaleTransition(scale: _scale, child: widget.child),
    );
  }
}

/// دخول متدرّج (تلاشٍ + انزلاق لأعلى) — يُستخدم لعناصر الشبكة/القائمة
/// لإعطاء إحساس "تتابع" راقٍ عند ظهور المحتوى.
class FadeSlideIn extends StatefulWidget {
  final Widget child;
  final int index;
  final Duration duration;
  final Duration stagger;
  final double offsetY;

  const FadeSlideIn({
    super.key,
    required this.child,
    this.index = 0,
    this.duration = const Duration(milliseconds: 420),
    this.stagger = const Duration(milliseconds: 55),
    this.offsetY = 24,
  });

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  );

  @override
  void initState() {
    super.initState();
    // تأخير متتابع بحدّ أقصى حتى لا تتأخر العناصر البعيدة كثيراً.
    final cappedIndex = widget.index.clamp(0, 12);
    final delay = widget.stagger * cappedIndex;
    Future.delayed(delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    return AnimatedBuilder(
      animation: curved,
      builder: (context, child) {
        return Opacity(
          opacity: curved.value,
          child: Transform.translate(
            offset: Offset(0, widget.offsetY * (1 - curved.value)),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}

/// مستطيل وميض (skeleton) حقيقي باستخدام حزمة shimmer.
class ShimmerBox extends StatelessWidget {
  final double? width;
  final double? height;
  final BorderRadius borderRadius;

  const ShimmerBox({
    super.key,
    this.width,
    this.height,
    BorderRadius? borderRadius,
  }) : borderRadius = borderRadius ?? const BorderRadius.all(Radius.circular(8));

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(color: Colors.white, borderRadius: borderRadius),
    );
  }
}

/// يلفّ محتوى skeleton بتأثير الوميض المتحرك.
class ShimmerArea extends StatelessWidget {
  final Widget child;
  const ShimmerArea({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFE8EAED),
      highlightColor: const Color(0xFFF7F8FA),
      period: const Duration(milliseconds: 1300),
      child: child,
    );
  }
}

/// هيكل بطاقة الإعلان أثناء التحميل (يطابق شكل PostCard الجديد).
class PostCardSkeleton extends StatelessWidget {
  const PostCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerArea(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: ShimmerBox(
                borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerBox(height: 12, width: double.infinity),
                    SizedBox(height: 8),
                    ShimmerBox(height: 12, width: 90),
                    Spacer(),
                    ShimmerBox(height: 16, width: 70),
                    SizedBox(height: 8),
                    ShimmerBox(height: 10, width: 120),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
