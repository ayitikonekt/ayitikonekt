import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/localization/app_locale_provider.dart';
import '../../../shared/widgets/app_back_button.dart';
import '../models/review_model.dart';
import '../services/review_service.dart';

class ReviewsScreen extends StatelessWidget {
  final String userId;

  const ReviewsScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 2,
    child: Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        leadingWidth: 112,
        leading: const AppBackButton(
          showWhenCannotPop: false,
          foregroundColor: Colors.white,
        ),
        title: Text(context.tr('reviews')),
        centerTitle: true,
        backgroundColor: const Color(0xFF0646D8),
        foregroundColor: Colors.white,
        bottom: TabBar(
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(text: context.tr('received')),
            Tab(text: context.tr('written')),
          ],
        ),
      ),
      body: TabBarView(
        children: [
          _ReviewsList(
            stream: ReviewService().receivedBy(userId),
            showSummary: true,
          ),
          _ReviewsList(
            stream: ReviewService().writtenBy(userId),
            showReviewer: false,
          ),
        ],
      ),
    ),
  );
}

class _ReviewsList extends StatelessWidget {
  final Stream<List<ReviewModel>> stream;
  final bool showSummary;
  final bool showReviewer;

  const _ReviewsList({
    required this.stream,
    this.showSummary = false,
    this.showReviewer = true,
  });

  @override
  Widget build(BuildContext context) => StreamBuilder<List<ReviewModel>>(
    stream: stream,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return Center(child: Text(context.tr('reviewsLoadError')));
      }
      if (!snapshot.hasData) {
        return const Center(child: CircularProgressIndicator());
      }
      final reviews = snapshot.data!;
      if (reviews.isEmpty) {
        return _EmptyReviews(message: context.tr('noReviewsYet'));
      }
      final average =
          reviews.fold<int>(0, (sum, item) => sum + item.rating) /
          reviews.length;

      return LayoutBuilder(
        builder: (context, constraints) => Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: ListView.builder(
              padding: EdgeInsets.fromLTRB(
                constraints.maxWidth < 600 ? 14 : 24,
                18,
                constraints.maxWidth < 600 ? 14 : 24,
                32,
              ),
              itemCount: reviews.length + (showSummary ? 1 : 0),
              itemBuilder: (context, index) {
                if (showSummary && index == 0) {
                  return _ReviewSummary(
                    average: average,
                    count: reviews.length,
                  );
                }
                final review = reviews[index - (showSummary ? 1 : 0)];
                return _ReviewCard(review: review, showReviewer: showReviewer);
              },
            ),
          ),
        ),
      );
    },
  );
}

class _ReviewSummary extends StatelessWidget {
  final double average;
  final int count;

  const _ReviewSummary({required this.average, required this.count});

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 14),
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Text(
            average.toStringAsFixed(1),
            style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w800),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Stars(value: average.round(), size: 22),
                const SizedBox(height: 5),
                Text('$count ${context.tr('reviews').toLowerCase()}'),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _ReviewCard extends StatelessWidget {
  final ReviewModel review;
  final bool showReviewer;

  const _ReviewCard({required this.review, required this.showReviewer});

  Future<void> _report(BuildContext context) async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Denunciar reseña'),
        content: TextField(
          controller: controller,
          maxLength: 500,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'Motivo',
            hintText: 'Explica por qué esta reseña debe revisarse.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              final value = controller.text.trim();
              if (value.isNotEmpty) Navigator.pop(dialogContext, value);
            },
            child: const Text('Enviar denuncia'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (reason == null || !context.mounted) return;
    try {
      await ReviewService().reportReview(reviewId: review.id, reason: reason);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La reseña fue enviada a moderación.')),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo enviar la denuncia.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 12),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundImage: review.reviewerPhoto.isNotEmpty
                    ? NetworkImage(review.reviewerPhoto)
                    : null,
                child: review.reviewerPhoto.isEmpty
                    ? const Icon(Icons.person_outline)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (showReviewer ? review.reviewerName : review.sellerName)
                              .isEmpty
                          ? context.tr('user')
                          : showReviewer
                          ? review.reviewerName
                          : review.sellerName,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    _Stars(value: review.rating, size: 18),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${review.createdAt.day}/${review.createdAt.month}/${review.createdAt.year}',
                    style: const TextStyle(
                      color: Color(0xFF667085),
                      fontSize: 12,
                    ),
                  ),
                  if (FirebaseAuth.instance.currentUser?.uid != review.reviewerId)
                    IconButton(
                      tooltip: 'Denunciar reseña',
                      visualDensity: VisualDensity.compact,
                      onPressed: () => _report(context),
                      icon: const Icon(Icons.flag_outlined, size: 20),
                    ),
                ],
              ),
            ],
          ),
          if (review.productTitle.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              review.productTitle,
              style: const TextStyle(
                color: Color(0xFF0646D8),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          if (review.comment.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(review.comment),
          ],
          if (review.tags.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: review.tags
                  .map(
                    (tag) => Chip(
                      label: Text(context.tr(tag)),
                      visualDensity: VisualDensity.compact,
                      backgroundColor: const Color(0xFFEAF1FF),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    ),
  );
}

class _Stars extends StatelessWidget {
  final int value;
  final double size;

  const _Stars({required this.value, required this.size});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: List.generate(
      5,
      (index) => Icon(
        index < value ? Icons.star_rounded : Icons.star_border_rounded,
        color: const Color(0xFFFFB800),
        size: size,
      ),
    ),
  );
}

class _EmptyReviews extends StatelessWidget {
  final String message;

  const _EmptyReviews({required this.message});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.star_border_rounded,
            size: 74,
            color: Color(0xFF98A2B3),
          ),
          const SizedBox(height: 14),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 17),
          ),
        ],
      ),
    ),
  );
}
