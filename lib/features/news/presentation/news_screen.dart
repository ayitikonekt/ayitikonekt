import 'package:flutter/material.dart';

import '../../../core/localization/app_locale_provider.dart';
import '../../../shared/widgets/app_back_button.dart';
import '../../../shared/widgets/news_card.dart';
import '../data/news_catalog.dart';
import 'news_detail_screen.dart';

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  String _category = 'newsAll';

  static const _categories = [
    'newsAll',
    'newsCommunity',
    'newsEmployment',
    'newsHousing',
    'newsSafety',
    'newsGuides',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _query.trim().toLowerCase();
    final articles = newsCatalog.where((article) {
      final categoryMatches =
          _category == 'newsAll' || article.categoryKey == _category;
      final queryMatches =
          query.isEmpty ||
          '${context.tr(article.titleKey)} ${context.tr(article.summaryKey)}'
              .toLowerCase()
              .contains(query);
      return categoryMatches && queryMatches;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        leadingWidth: 112,
        leading: const AppBackButton(
          showWhenCannotPop: false,
          foregroundColor: Colors.white,
        ),
        title: Text(context.tr('news')),
        centerTitle: true,
        backgroundColor: const Color(0xFF0646D8),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  constraints.maxWidth < 600 ? 14 : 24,
                  18,
                  constraints.maxWidth < 600 ? 14 : 24,
                  36,
                ),
                children: [
                  TextField(
                    controller: _searchController,
                    onChanged: (value) => setState(() => _query = value),
                    decoration: InputDecoration(
                      hintText: context.tr('searchNews'),
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _query.isEmpty
                          ? null
                          : IconButton(
                              tooltip: context.tr('clear'),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _query = '');
                              },
                              icon: const Icon(Icons.close_rounded),
                            ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _categories
                          .map(
                            (category) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(context.tr(category)),
                                selected: _category == category,
                                onSelected: (_) =>
                                    setState(() => _category = category),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    '${articles.length} ${context.tr(articles.length == 1 ? 'newsResult' : 'newsResults')}',
                    style: const TextStyle(
                      color: Color(0xFF667085),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (articles.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 70),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.search_off_rounded,
                            size: 70,
                            color: Color(0xFF98A2B3),
                          ),
                          const SizedBox(height: 12),
                          Text(context.tr('noNewsResults')),
                        ],
                      ),
                    )
                  else
                    ...articles.map(
                      (article) => NewsCard(
                        title: context.tr(article.titleKey),
                        description: context.tr(article.summaryKey),
                        category: context.tr(article.categoryKey),
                        date: article.publishedAt,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => NewsDetailScreen(article: article),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
