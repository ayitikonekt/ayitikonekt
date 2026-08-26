import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewModel {
  final String id;
  final String productId;
  final String productTitle;
  final String sellerId;
  final String sellerName;
  final String reviewerId;
  final String reviewerName;
  final String reviewerPhoto;
  final int rating;
  final String comment;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ReviewModel({
    required this.id,
    required this.productId,
    required this.productTitle,
    required this.sellerId,
    required this.sellerName,
    required this.reviewerId,
    required this.reviewerName,
    required this.reviewerPhoto,
    required this.rating,
    required this.comment,
    required this.tags,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ReviewModel.fromDocument(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    DateTime readDate(Object? value) {
      if (value is Timestamp) return value.toDate();
      return DateTime.tryParse(value?.toString() ?? '') ?? DateTime.now();
    }

    return ReviewModel(
      id: doc.id,
      productId: data['productId']?.toString() ?? '',
      productTitle: data['productTitle']?.toString() ?? '',
      sellerId: data['sellerId']?.toString() ?? '',
      sellerName: data['sellerName']?.toString() ?? '',
      reviewerId: data['reviewerId']?.toString() ?? '',
      reviewerName: data['reviewerName']?.toString() ?? '',
      reviewerPhoto: data['reviewerPhoto']?.toString() ?? '',
      rating: (data['rating'] as num?)?.toInt() ?? 0,
      comment: data['comment']?.toString() ?? '',
      tags: List<String>.from(data['tags'] ?? const <String>[]),
      createdAt: readDate(data['createdAt']),
      updatedAt: readDate(data['updatedAt']),
    );
  }
}
