import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/firebase/backend_functions_service.dart';

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
  final BackendFunctionsService _functions = BackendFunctionsService();

  CollectionReference<Map<String, dynamic>> _favoritesCollection(String uid) {
    return _firestore.collection('users').doc(uid).collection('favorites');
  }

  @override
  Future<int> toggleFavorite({
    required String uid,
    required String productId,
    required bool add,
  }) {
    return _functions.call('toggleFavorite', {
      'productId': productId,
      'add': add,
    }).then((data) => (data['favoriteCount'] as num).toInt());
  }

  @override
  Future<Set<String>> getFavoriteIds(String uid) async {
    final snapshot = await _favoritesCollection(uid).get();

    return snapshot.docs.map((doc) => doc.id).toSet();
  }
}
