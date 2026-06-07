import 'package:flutter/material.dart';

class AppColors {
  // ===== ألوان البراند — قابلة للتعديل من لوحة الإدارة =====
  // (mutable: تُحدَّث وقت التشغيل من إعدادات Firestore ثم يُعاد بناء التطبيق)
  static Color primary = defaultPrimary;
  static Color primaryDeep = _darken(defaultPrimary, 0.12); // أغمق — لتدرّج البراند
  static Color primaryLight = _lighten(defaultPrimary, 0.18);
  static Color secondary = defaultSecondary;
  static Color secondaryDeep = _darken(defaultSecondary, 0.10); // أعمق

  // القيم الافتراضية (لإعادة التعيين)
  static const Color defaultPrimary = Color(0xFF1B5E20);
  static const Color defaultSecondary = Color(0xFFFFB300);

  // ===== ألوان ثابتة =====
  static const Color accent = Color(0xFFE53935);
  static const Color background = Color(0xFFF2F4F7); // خلفية أنعم وأرقى
  static const Color surface = Color(0xFFFFFFFF);
  static const Color cardBg = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF1A2027);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color divider = Color(0xFFE6E8EB);
  static const Color success = Color(0xFF43A047);
  static const Color warning = Color(0xFFFB8C00);
  static const Color whatsapp = Color(0xFF25D366);

  /// يطبّق ألوان البراند المختارة من لوحة الإدارة، ويشتقّ التدرّجات تلقائياً.
  static void applyTheme({Color? primary, Color? secondary}) {
    if (primary != null) {
      AppColors.primary = primary;
      AppColors.primaryDeep = _darken(primary, 0.12);
      AppColors.primaryLight = _lighten(primary, 0.18);
    }
    if (secondary != null) {
      AppColors.secondary = secondary;
      AppColors.secondaryDeep = _darken(secondary, 0.10);
    }
  }

  /// يعيد ألوان البراند إلى الافتراضي (الأخضر اليمني/الذهبي).
  static void resetTheme() =>
      applyTheme(primary: defaultPrimary, secondary: defaultSecondary);

  static Color _darken(Color c, double amount) {
    final hsl = HSLColor.fromColor(c);
    return hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0)).toColor();
  }

  static Color _lighten(Color c, double amount) {
    final hsl = HSLColor.fromColor(c);
    return hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0)).toColor();
  }

  /// تحويل نص HEX (مثل "1B5E20" أو "#1B5E20") إلى Color، أو null إن كان غير صالح.
  static Color? fromHex(String? hex) {
    if (hex == null) return null;
    var h = hex.trim().replaceAll('#', '');
    if (h.length == 6) h = 'FF$h';
    if (h.length != 8) return null;
    final value = int.tryParse(h, radix: 16);
    return value == null ? null : Color(value);
  }

  /// تحويل Color إلى نص HEX بصيغة "RRGGBB".
  static String toHex(Color c) {
    int ch(double v) => (v * 255.0).round() & 0xff;
    return '${ch(c.r).toRadixString(16).padLeft(2, '0')}'
            '${ch(c.g).toRadixString(16).padLeft(2, '0')}'
            '${ch(c.b).toRadixString(16).padLeft(2, '0')}'
        .toUpperCase();
  }
}

/// أنصاف أقطار موحّدة لإحساس متناسق وراقٍ.
class AppRadius {
  static const double sm = 10;
  static const double md = 14;
  static const double lg = 18;
  static const double xl = 24;
  static const double pill = 999;
}

/// تدرّجات لونية للبراند (تُعطي عمقاً بصرياً بدل الألوان المسطّحة).
class AppGradients {
  static LinearGradient get brand => LinearGradient(
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
    colors: [AppColors.primary, AppColors.primaryDeep],
  );

  static LinearGradient get brandVibrant => LinearGradient(
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
    colors: [AppColors.primaryLight, AppColors.primary, AppColors.primaryDeep],
  );

  static LinearGradient get gold => LinearGradient(
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
    colors: [AppColors.secondary, AppColors.secondaryDeep],
  );

  /// تدرّج شفاف→أسود لتحسين قراءة النص فوق الصور.
  static const LinearGradient imageScrim = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Colors.transparent, Color(0x66000000)],
    stops: [0.45, 1.0],
  );
}

/// ظلال طبقية ناعمة تعطي إحساساً "غالياً" بدل الـ elevation المسطّح.
class AppShadows {
  static List<BoxShadow> card = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.05),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.03),
      blurRadius: 3,
      offset: const Offset(0, 1),
    ),
  ];

  static List<BoxShadow> raised = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.10),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> get brandGlow => [
    BoxShadow(
      color: AppColors.primary.withValues(alpha: 0.35),
      blurRadius: 16,
      offset: const Offset(0, 6),
    ),
  ];

  static List<BoxShadow> get goldGlow => [
    BoxShadow(
      color: AppColors.secondary.withValues(alpha: 0.40),
      blurRadius: 14,
      offset: const Offset(0, 4),
    ),
  ];
}

class AppTheme {
  static const String _fontFamily = 'Cairo';

  static TextTheme _buildTextTheme(TextTheme base) {
    return base.copyWith(
      displayLarge:  base.displayLarge?.copyWith(fontFamily: _fontFamily, fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
      displayMedium: base.displayMedium?.copyWith(fontFamily: _fontFamily, fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
      headlineLarge: base.headlineLarge?.copyWith(fontFamily: _fontFamily, fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
      headlineMedium:base.headlineMedium?.copyWith(fontFamily: _fontFamily, fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
      headlineSmall: base.headlineSmall?.copyWith(fontFamily: _fontFamily, fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
      titleLarge:    base.titleLarge?.copyWith(fontFamily: _fontFamily, fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
      titleMedium:   base.titleMedium?.copyWith(fontFamily: _fontFamily, fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
      titleSmall:    base.titleSmall?.copyWith(fontFamily: _fontFamily, fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
      bodyLarge:     base.bodyLarge?.copyWith(fontFamily: _fontFamily, fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
      bodyMedium:    base.bodyMedium?.copyWith(fontFamily: _fontFamily, fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
      bodySmall:     base.bodySmall?.copyWith(fontFamily: _fontFamily, fontSize: 13, fontWeight: FontWeight.w400, color: AppColors.textSecondary),
      labelLarge:    base.labelLarge?.copyWith(fontFamily: _fontFamily, fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.surface),
    );
  }

  static ThemeData get lightTheme {
    final base = ThemeData.light(useMaterial3: true);
    const cairoFamily = _fontFamily;
    return base.copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.surface,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: AppColors.background,
      textTheme: _buildTextTheme(base.textTheme),
      // انتقالات صفحات ناعمة (fade + scale خفيف) على كل المنصّات.
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: _FadeThroughPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: _FadeThroughPageTransitionsBuilder(),
          TargetPlatform.macOS: _FadeThroughPageTransitionsBuilder(),
          TargetPlatform.linux: _FadeThroughPageTransitionsBuilder(),
        },
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent, // يمنع طبقة تلوين M3 التي تبيّض الشريط
        scrolledUnderElevation: 0,            // يمنع تغيّر لون الشريط عند التمرير تحته
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: cairoFamily,
          fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      cardTheme: CardThemeData(
        color: AppColors.cardBg,
        elevation: 0,
        shadowColor: Colors.black.withValues(alpha: 0.10),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
        clipBehavior: Clip.antiAlias,
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: TextStyle(fontFamily: cairoFamily, fontSize: 16, fontWeight: FontWeight.w600),
          minimumSize: const Size(double.infinity, 52),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: BorderSide(color: AppColors.primary, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: TextStyle(fontFamily: cairoFamily, fontSize: 16, fontWeight: FontWeight.w600),
          minimumSize: const Size(double.infinity, 52),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.accent),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
        labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.white,
        selectedColor: AppColors.primary,
        labelStyle: const TextStyle(fontSize: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        side: const BorderSide(color: AppColors.divider),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.divider, thickness: 1),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.textPrimary,
        contentTextStyle: const TextStyle(color: Colors.white, fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

/// انتقال صفحات مخصّص: تلاشٍ + تكبير خفيف جداً — إحساس راقٍ ومتوافق مع كل إصدارات Flutter.
class _FadeThroughPageTransitionsBuilder extends PageTransitionsBuilder {
  const _FadeThroughPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final fade = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
    final scale = Tween<double>(begin: 0.985, end: 1.0).animate(fade);
    return FadeTransition(
      opacity: fade,
      child: ScaleTransition(scale: scale, child: child),
    );
  }
}
