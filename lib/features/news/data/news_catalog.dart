import '../models/news_article.dart';

final List<NewsArticle> newsCatalog = [
  NewsArticle(
    id: 'entrepreneurs_fair',
    categoryKey: 'newsCommunity',
    titleKey: 'newsFairTitle',
    summaryKey: 'newsFairSummary',
    contentKey: 'newsFairContent',
    publishedAt: DateTime(2026, 8, 24),
  ),
  NewsArticle(
    id: 'job_opportunities',
    categoryKey: 'newsEmployment',
    titleKey: 'newsJobsTitle',
    summaryKey: 'newsJobsSummary',
    contentKey: 'newsJobsContent',
    publishedAt: DateTime(2026, 8, 23),
  ),
  NewsArticle(
    id: 'renting_advice',
    categoryKey: 'newsHousing',
    titleKey: 'newsRentTitle',
    summaryKey: 'newsRentSummary',
    contentKey: 'newsRentContent',
    publishedAt: DateTime(2026, 8, 22),
  ),
  NewsArticle(
    id: 'online_safety',
    categoryKey: 'newsSafety',
    titleKey: 'newsSafetyTitle',
    summaryKey: 'newsSafetySummary',
    contentKey: 'newsSafetyContent',
    publishedAt: DateTime(2026, 8, 21),
  ),
  NewsArticle(
    id: 'profile_location',
    categoryKey: 'newsGuides',
    titleKey: 'newsLocationTitle',
    summaryKey: 'newsLocationSummary',
    contentKey: 'newsLocationContent',
    publishedAt: DateTime(2026, 8, 20),
  ),
];
