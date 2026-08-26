class NewsArticle {
  final String id;
  final String categoryKey;
  final String titleKey;
  final String summaryKey;
  final String contentKey;
  final DateTime publishedAt;
  final String sourceUrl;

  const NewsArticle({
    required this.id,
    required this.categoryKey,
    required this.titleKey,
    required this.summaryKey,
    required this.contentKey,
    required this.publishedAt,
    this.sourceUrl = '',
  });
}
