import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/firebase/backend_functions_service.dart';
import '../../auth/data/user_model.dart';
import '../../marketplace/models/product_model.dart';
import '../models/review_model.dart';

class ReviewService {
  final FirebaseFirestore _firestore;
  final BackendFunctionsService _functions;

  ReviewService({
    FirebaseFirestore? firestore,
    BackendFunctionsService? functions,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _functions = functions ?? BackendFunctionsService();

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

    await _functions.call('createReview', {
      'productId': product.id,
      'rating': rating,
      'comment': comment.trim(),
      'tags': tags,
    });
  }
}
