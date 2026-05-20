import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/post_model.dart';

class FavoritesService {
  static final FavoritesService _instance = FavoritesService._internal();
  factory FavoritesService() => _instance;
  FavoritesService._internal();

  FirebaseFirestore get _db => FirebaseFirestore.instance;
  FirebaseAuth get _auth => FirebaseAuth.instance;

  CollectionReference? get _userFavorites {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    return _db.collection('users').doc(uid).collection('favorites');
  }

  // إضافة إعلان للمفضلة
  Future<void> addFavorite(PostModel post) async {
    final col = _userFavorites;
    if (col == null || post.id == null) return;
    await col.doc(post.id).set({
      'post_id': post.id,
      'added_at': FieldValue.serverTimestamp(),
    });
  }

  // حذف إعلان من المفضلة
  Future<void> removeFavorite(String postId) async {
    final col = _userFavorites;
    if (col == null) return;
    await col.doc(postId).delete();
  }

  // التحقق هل الإعلان في المفضلة
  Stream<bool> isFavorite(String postId) {
    final col = _userFavorites;
    if (col == null) return Stream.value(false);
    return col.doc(postId).snapshots().map((doc) => doc.exists);
  }

  // الحصول على قائمة معرفات المفضلة
  Stream<List<String>> getFavoriteIds() {
    final col = _userFavorites;
    if (col == null) return Stream.value([]);
    return col
        .orderBy('added_at', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.id).toList());
  }

  // الحصول على إعلانات المفضلة كاملة
  Future<List<PostModel>> getFavoritePosts() async {
    final col = _userFavorites;
    if (col == null) return [];

    final favSnap = await col.orderBy('added_at', descending: true).get();
    if (favSnap.docs.isEmpty) return [];

    final ids = favSnap.docs.map((d) => d.id).toList();

    // جلب الإعلانات دفعة واحدة
    final postsSnap = await _db
        .collection('posts')
        .where(FieldPath.documentId, whereIn: ids)
        .get();

    final posts = postsSnap.docs
        .map((d) => PostModel.fromFirestore(d))
        .where((p) => p.status == PostStatus.active)
        .toList();

    // ترتيب حسب ترتيب المفضلة
    posts.sort((a, b) => ids.indexOf(a.id!).compareTo(ids.indexOf(b.id!)));
    return posts;
  }
}
