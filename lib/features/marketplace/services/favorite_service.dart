import 'package:cloud_firestore/cloud_firestore.dart';

class FavoriteService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  CollectionReference<Map<String, dynamic>> _favoritesCollection(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('favorites');
  }

  Future<int> toggleFavorite({
    required String uid,
    required String productId,
    required bool add,
  }) {
    final favorite = _favoritesCollection(uid).doc(productId);
    final product = _firestore.collection('products').doc(productId);

    return _firestore.runTransaction((transaction) async {
      final productSnapshot = await transaction.get(product);
      if (!productSnapshot.exists) {
        throw Exception('La publicación ya no está disponible.');
      }

      final data = productSnapshot.data()!;
      final currentCount = (data['favorites'] as num?)?.toInt() ?? 0;
      final nextCount = add
          ? currentCount + 1
          : (currentCount - 1).clamp(0, currentCount).toInt();

      if (add) {
        transaction.set(favorite, {
          'productId': productId,
          'createdAt': FieldValue.serverTimestamp(),
        });

      } else {
        transaction.delete(favorite);
      }
      transaction.update(product, {'favorites': nextCount});

      return nextCount;
    });
  }

  Future<Set<String>> getFavoriteIds(String uid) async {
    final snapshot = await _favoritesCollection(uid).get();

    return snapshot.docs
        .map((doc) => doc.id)
        .toSet();
  }
}
