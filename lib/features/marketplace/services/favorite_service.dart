import 'package:cloud_firestore/cloud_firestore.dart';

abstract interface class FavoriteRepository {
  Future<int> toggleFavorite({
    required String uid,
    required String productId,
    required bool add,
  });

  Future<Set<String>> getFavoriteIds(String uid);
}

class FavoriteService implements FavoriteRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  CollectionReference<Map<String, dynamic>> _favoritesCollection(String uid) {
    return _firestore.collection('users').doc(uid).collection('favorites');
  }

  @override
  Future<int> toggleFavorite({
    required String uid,
    required String productId,
    required bool add,
  }) {
    final favorite = _favoritesCollection(uid).doc(productId);
    final product = _firestore.collection('products').doc(productId);
    final user = _firestore.collection('users').doc(uid);
    final notificationId = _firestore.collection('notifications').doc().id;

    return _firestore.runTransaction((transaction) async {
      final productSnapshot = await transaction.get(product);
      if (!productSnapshot.exists) {
        throw Exception('La publicación ya no está disponible.');
      }

      final data = productSnapshot.data()!;
      final favoriteSnapshot = await transaction.get(favorite);
      final isFavorite = favoriteSnapshot.exists;

      // Evita alterar el contador o avisar dos veces por la misma acción.
      if (isFavorite == add) {
        return (data['favorites'] as num?)?.toInt() ?? 0;
      }

      final sellerId = data['sellerId']?.toString() ?? '';
      String? actorName;
      if (add && sellerId.isNotEmpty && sellerId != uid) {
        final userSnapshot = await transaction.get(user);
        final userData = userSnapshot.data();
        final firstName = userData?['name']?.toString().trim() ?? '';
        final lastName = userData?['lastName']?.toString().trim() ?? '';
        final fullName = '$firstName $lastName'.trim();
        actorName = fullName.isEmpty ? 'Alguien' : fullName;
      }

      final currentCount = (data['favorites'] as num?)?.toInt() ?? 0;
      final nextCount = add
          ? currentCount + 1
          : (currentCount - 1).clamp(0, currentCount).toInt();

      if (add) {
        transaction.set(favorite, {
          'productId': productId,
          'createdAt': FieldValue.serverTimestamp(),
        });

        if (actorName != null) {
          final productTitle = data['title']?.toString().trim() ?? '';
          final displayedTitle = productTitle.isEmpty
              ? 'tu producto'
              : '"$productTitle"';
          final sellerNotification = _firestore
              .collection('users')
              .doc(sellerId)
              .collection('notifications')
              .doc(notificationId);

          transaction.set(sellerNotification, {
            'type': 'favorite',
            'title': 'Nuevo favorito',
            'message': '$actorName agregó $displayedTitle a sus favoritos.',
            'productId': productId,
            'actorId': uid,
            'actorName': actorName,
            'read': false,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      } else {
        transaction.delete(favorite);
      }
      transaction.update(product, {'favorites': nextCount});

      return nextCount;
    });
  }

  @override
  Future<Set<String>> getFavoriteIds(String uid) async {
    final snapshot = await _favoritesCollection(uid).get();

    return snapshot.docs.map((doc) => doc.id).toSet();
  }
}
