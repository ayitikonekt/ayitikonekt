import 'package:cloud_firestore/cloud_firestore.dart';

import '../../auth/data/user_model.dart';
import '../../marketplace/models/product_model.dart';
import '../models/review_model.dart';

class ReviewService {
  final FirebaseFirestore _firestore;

  ReviewService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  String reviewId(String productId, String reviewerId) =>
      '${productId}_$reviewerId';

  Stream<List<ReviewModel>> receivedBy(String sellerId) => _firestore
      .collection('reviews')
      .where('sellerId', isEqualTo: sellerId)
      .snapshots()
      .map(_sortedReviews);

  Stream<List<ReviewModel>> writtenBy(String reviewerId) => _firestore
      .collection('reviews')
      .where('reviewerId', isEqualTo: reviewerId)
      .snapshots()
      .map(_sortedReviews);

  List<ReviewModel> _sortedReviews(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    final reviews = snapshot.docs.map(ReviewModel.fromDocument).toList();
    reviews.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return reviews;
  }

  Future<bool> alreadyReviewed(String productId, String reviewerId) async =>
      (await _firestore
              .collection('reviews')
              .doc(reviewId(productId, reviewerId))
              .get())
          .exists;

  Future<void> createReview({
    required ProductModel product,
    required UserModel reviewer,
    required int rating,
    required String comment,
    required List<String> tags,
  }) async {
    if (reviewer.uid == product.sellerId) {
      throw StateError('self_review');
    }
    if (rating < 1 || rating > 5) {
      throw ArgumentError.value(rating, 'rating');
    }

    final reviewRef = _firestore
        .collection('reviews')
        .doc(reviewId(product.id, reviewer.uid));
    final sellerRef = _firestore.collection('users').doc(product.sellerId);

    await _firestore.runTransaction((transaction) async {
      final existing = await transaction.get(reviewRef);
      if (existing.exists) throw StateError('duplicate_review');
      final seller = await transaction.get(sellerRef);
      final sellerData = seller.data() ?? const <String, dynamic>{};
      final previousCount = (sellerData['reviewCount'] as num?)?.toInt() ?? 0;
      final previousTotal =
          (sellerData['reviewRatingTotal'] as num?)?.toInt() ?? 0;
      final newCount = previousCount + 1;
      final newTotal = previousTotal + rating;
      final newAverage = newTotal / newCount;
      final now = FieldValue.serverTimestamp();

      transaction.set(reviewRef, {
        'productId': product.id,
        'productTitle': product.title,
        'sellerId': product.sellerId,
        'sellerName': product.sellerName,
        'reviewerId': reviewer.uid,
        'reviewerName': '${reviewer.name} ${reviewer.lastName}'.trim(),
        'reviewerPhoto': reviewer.photo,
        'rating': rating,
        'comment': comment.trim(),
        'tags': tags,
        'reported': false,
        'createdAt': now,
        'updatedAt': now,
      });
      transaction.update(sellerRef, {
        'reputation': newAverage,
        'reviewCount': newCount,
        'reviewRatingTotal': newTotal,
      });
    });
  }
}
