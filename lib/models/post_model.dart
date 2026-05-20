import 'package:cloud_firestore/cloud_firestore.dart';

enum PriceType { yemeni, saudi, dollar, free, negotiable }

enum PostStatus { active, sold, deleted }

extension PriceTypeLabel on PriceType {
  String get label {
    switch (this) {
      case PriceType.yemeni:   return 'ريال يمني';
      case PriceType.saudi:    return 'ريال سعودي';
      case PriceType.dollar:   return 'دولار أمريكي';
      case PriceType.free:     return 'مجاناً';
      case PriceType.negotiable: return 'السعر قابل للتفاوض';
    }
  }

  String get symbol {
    switch (this) {
      case PriceType.yemeni:   return 'ر.ي';
      case PriceType.saudi:    return 'ر.س';
      case PriceType.dollar:   return r'$';
      case PriceType.free:     return '';
      case PriceType.negotiable: return '';
    }
  }
}

class PostModel {
  final String? id;
  final String title;
  final String description;
  final List<String> images;       // روابط الصور على Firebase Storage
  final String governorateId;
  final String governorateName;
  final String userId;             // رقم الهاتف
  final String userPhone;
  final String? userName;
  final double? price;
  final PriceType priceType;
  final PostStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? category;
  final double? latitude;
  final double? longitude;
  final int viewCount;
  final bool isFeatured;
  final DateTime? expiresAt;

  const PostModel({
    this.id,
    required this.title,
    required this.description,
    required this.images,
    required this.governorateId,
    required this.governorateName,
    required this.userId,
    required this.userPhone,
    this.userName,
    this.price,
    required this.priceType,
    this.status = PostStatus.active,
    required this.createdAt,
    this.updatedAt,
    this.category,
    this.latitude,
    this.longitude,
    this.viewCount = 0,
    this.isFeatured = false,
    this.expiresAt,
  });

  factory PostModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PostModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      images: List<String>.from(data['images'] ?? []),
      governorateId: data['governorate_id'] ?? '',
      governorateName: data['governorate_name'] ?? '',
      userId: data['user_id'] ?? '',
      userPhone: data['user_phone'] ?? '',
      userName: data['user_name'],
      price: data['price'] != null ? (data['price'] as num).toDouble() : null,
      priceType: PriceType.values.firstWhere(
        (e) => e.name == (data['price_type'] ?? 'yemeni'),
        orElse: () => PriceType.yemeni,
      ),
      status: PostStatus.values.firstWhere(
        (e) => e.name == (data['status'] ?? 'active'),
        orElse: () => PostStatus.active,
      ),
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updated_at'] as Timestamp?)?.toDate(),
      category: data['category'],
      latitude: data['latitude'] != null ? (data['latitude'] as num).toDouble() : null,
      longitude: data['longitude'] != null ? (data['longitude'] as num).toDouble() : null,
      viewCount: (data['view_count'] as int?) ?? 0,
      isFeatured: (data['is_featured'] as bool?) ?? false,
      expiresAt: (data['expires_at'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'title': title,
    'description': description,
    'images': images,
    'governorate_id': governorateId,
    'governorate_name': governorateName,
    'user_id': userId,
    'user_phone': userPhone,
    'user_name': userName,
    'price': price,
    'price_type': priceType.name,
    'status': status.name,
    'created_at': Timestamp.fromDate(createdAt),
    'updated_at': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    'category': category,
    'latitude': latitude,
    'longitude': longitude,
    'view_count': viewCount,
    'is_featured': isFeatured,
    'expires_at': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
  };

  String get priceDisplay {
    if (priceType == PriceType.free) return 'مجاناً';
    if (priceType == PriceType.negotiable) return 'قابل للتفاوض';
    if (price == null || price == 0) return 'اتصل للسعر';
    final formattedPrice = price! >= 1000
        ? '${(price! / 1000).toStringAsFixed(price! % 1000 == 0 ? 0 : 1)} ألف'
        : price!.toStringAsFixed(0);
    return '$formattedPrice ${priceType.symbol}';
  }

  String get thumbnailUrl => images.isNotEmpty ? images.first : '';

  PostModel copyWith({
    String? id,
    String? title,
    String? description,
    List<String>? images,
    String? governorateId,
    String? governorateName,
    String? userId,
    String? userPhone,
    String? userName,
    double? price,
    PriceType? priceType,
    PostStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? category,
    double? latitude,
    double? longitude,
    int? viewCount,
    bool? isFeatured,
    DateTime? expiresAt,
  }) {
    return PostModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      images: images ?? this.images,
      governorateId: governorateId ?? this.governorateId,
      governorateName: governorateName ?? this.governorateName,
      userId: userId ?? this.userId,
      userPhone: userPhone ?? this.userPhone,
      userName: userName ?? this.userName,
      price: price ?? this.price,
      priceType: priceType ?? this.priceType,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      category: category ?? this.category,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      viewCount: viewCount ?? this.viewCount,
      isFeatured: isFeatured ?? this.isFeatured,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }
}

// فئات الإعلانات
class PostCategories {
  static const List<Map<String, String>> categories = [
    {'id': 'cars', 'name': 'سيارات ومركبات', 'icon': '🚗'},
    {'id': 'real_estate', 'name': 'عقارات', 'icon': '🏠'},
    {'id': 'electronics', 'name': 'إلكترونيات', 'icon': '📱'},
    {'id': 'furniture', 'name': 'أثاث ومفروشات', 'icon': '🛋️'},
    {'id': 'clothes', 'name': 'ملابس وأزياء', 'icon': '👕'},
    {'id': 'jobs', 'name': 'وظائف', 'icon': '💼'},
    {'id': 'animals', 'name': 'حيوانات', 'icon': '🐄'},
    {'id': 'services', 'name': 'خدمات', 'icon': '🔧'},
    {'id': 'food', 'name': 'مواد غذائية', 'icon': '🥘'},
    {'id': 'other', 'name': 'أخرى', 'icon': '📦'},
  ];

  static String getIcon(String categoryId) {
    return categories
        .firstWhere((c) => c['id'] == categoryId, orElse: () => {'icon': '📦'})['icon']!;
  }

  static String getName(String categoryId) {
    return categories
        .firstWhere((c) => c['id'] == categoryId, orElse: () => {'name': 'أخرى'})['name']!;
  }
}
