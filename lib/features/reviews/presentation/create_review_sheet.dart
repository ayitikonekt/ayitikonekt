import 'package:flutter/material.dart';

import '../../../core/localization/app_locale_provider.dart';
import '../../auth/data/user_model.dart';
import '../../marketplace/models/product_model.dart';
import '../services/review_service.dart';

Future<bool?> showCreateReviewSheet(
  BuildContext context, {
  required ProductModel product,
  required UserModel reviewer,
}) => showModalBottomSheet<bool>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  backgroundColor: Colors.transparent,
  builder: (_) => _CreateReviewSheet(product: product, reviewer: reviewer),
);

class _CreateReviewSheet extends StatefulWidget {
  final ProductModel product;
  final UserModel reviewer;

  const _CreateReviewSheet({required this.product, required this.reviewer});

  @override
  State<_CreateReviewSheet> createState() => _CreateReviewSheetState();
}

class _CreateReviewSheetState extends State<_CreateReviewSheet> {
  final _commentController = TextEditingController();
  int _rating = 0;
  bool _saving = false;
  final Set<String> _tags = {};

  static const _tagKeys = <String>[
    'goodCommunication',
    'punctual',
    'asDescribed',
    'recommendedSeller',
  ];

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_rating == 0 || _saving) return;
    setState(() => _saving = true);
    try {
      await ReviewService().createReview(
        product: widget.product,
        reviewer: widget.reviewer,
        rating: _rating,
        comment: _commentController.text,
        tags: _tags.toList(),
      );
      if (mounted) Navigator.pop(context, true);
    } on StateError catch (error) {
      if (!mounted) return;
      final duplicate = error.message == 'duplicate_review';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.tr(duplicate ? 'alreadyReviewed' : 'cannotReviewYourself'),
          ),
        ),
      );
      setState(() => _saving = false);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.tr('reviewSaveError'))));
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final horizontalPadding = width < 360 ? 14.0 : 20.0;

    return Align(
      alignment: Alignment.bottomCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
              top: const Radius.circular(24),
              bottom: Radius.circular(width >= 700 ? 24 : 0),
            ),
          ),
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            12,
            horizontalPadding,
            20 + MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD0D5DD),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  context.tr('rateSeller'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  widget.product.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFF667085)),
                ),
                const SizedBox(height: 18),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: width < 360 ? 0 : 2,
                  children: List.generate(
                    5,
                    (index) => IconButton(
                      tooltip: '${index + 1}',
                      onPressed: () => setState(() => _rating = index + 1),
                      iconSize: width < 360 ? 34 : 40,
                      icon: Icon(
                        index < _rating
                            ? Icons.star_rounded
                            : Icons.star_border_rounded,
                        color: const Color(0xFFFFB800),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _tagKeys.map((key) {
                    final selected = _tags.contains(key);
                    return FilterChip(
                      selected: selected,
                      label: Text(context.tr(key)),
                      onSelected: (value) => setState(() {
                        value ? _tags.add(key) : _tags.remove(key);
                      }),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: _commentController,
                  minLines: 3,
                  maxLines: 5,
                  maxLength: 500,
                  decoration: InputDecoration(
                    labelText: context.tr('commentOptional'),
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 14),
                ElevatedButton.icon(
                  onPressed: _rating == 0 || _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.star_rounded),
                  label: Text(context.tr(_saving ? 'saving' : 'publishReview')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
