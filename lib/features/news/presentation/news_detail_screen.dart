import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/localization/app_locale_provider.dart';
import '../../../shared/widgets/app_back_button.dart';
import '../models/news_article.dart';

class NewsDetailScreen extends StatelessWidget {
  final NewsArticle article;

  const NewsDetailScreen({super.key, required this.article});

  String _date(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(
      ClipboardData(
        text:
            '${context.tr(article.titleKey)}\n\n${context.tr(article.contentKey)}',
      ),
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(context.tr('newsCopied'))));
  }

  Future<void> _openSource(BuildContext context) async {
    final uri = Uri.tryParse(article.sourceUrl);
    if (uri == null ||
        !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.tr('sourceOpenError'))));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
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
      actions: [
        IconButton(
          tooltip: context.tr('copyNews'),
          onPressed: () => _copy(context),
          icon: const Icon(Icons.ios_share_rounded),
        ),
      ],
    ),
    body: SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: constraints.maxWidth < 600 ? 16 : 28,
            vertical: 22,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: EdgeInsets.all(constraints.maxWidth < 400 ? 18 : 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAF1FF),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Icon(
                          Icons.article_rounded,
                          size: 38,
                          color: Color(0xFF0646D8),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Wrap(
                        spacing: 10,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Chip(label: Text(context.tr(article.categoryKey))),
                          Text(
                            _date(article.publishedAt),
                            style: const TextStyle(color: Color(0xFF667085)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        context.tr(article.titleKey),
                        style: const TextStyle(
                          fontSize: 28,
                          height: 1.15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        context.tr(article.summaryKey),
                        style: const TextStyle(
                          fontSize: 17,
                          height: 1.45,
                          color: Color(0xFF475467),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Divider(height: 36),
                      Text(
                        context.tr(article.contentKey),
                        style: const TextStyle(fontSize: 16, height: 1.65),
                      ),
                      const SizedBox(height: 28),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () => _copy(context),
                            icon: const Icon(Icons.copy_rounded),
                            label: Text(context.tr('copyNews')),
                          ),
                          if (article.sourceUrl.isNotEmpty)
                            OutlinedButton.icon(
                              onPressed: () => _openSource(context),
                              icon: const Icon(Icons.open_in_new_rounded),
                              label: Text(context.tr('openSource')),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
