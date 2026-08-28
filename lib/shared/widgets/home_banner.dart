import 'package:flutter/material.dart';

import '../../core/localization/app_locale_provider.dart';
import 'app_search_bar.dart';

class HomeBanner extends StatelessWidget {
  final String country;
  final ValueChanged<String>? onSearchChanged;

  const HomeBanner({super.key, required this.country, this.onSearchChanged});

  String _localizedCountry(BuildContext context) {
    final language = Localizations.localeOf(context).languageCode;
    const names = {
      'en': {
        'Estados Unidos': 'the United States',
        'Canadá': 'Canada',
        'Haití': 'Haiti',
        'República Dominicana': 'the Dominican Republic',
        'México': 'Mexico',
        'Francia': 'France',
        'Brasil': 'Brazil',
        'Chile': 'Chile',
      },
      'fr': {
        'Estados Unidos': 'les États-Unis',
        'Canadá': 'Canada',
        'Haití': 'Haïti',
        'República Dominicana': 'République dominicaine',
        'México': 'Mexique',
        'Francia': 'France',
        'Brasil': 'Brésil',
        'Chile': 'Chili',
      },
      'ht': {
        'Estados Unidos': 'Etazini',
        'Canadá': 'Kanada',
        'Haití': 'Ayiti',
        'República Dominicana': 'Repiblik Dominikèn',
        'México': 'Meksik',
        'Francia': 'Lafrans',
        'Brasil': 'Brezil',
        'Chile': 'Chili',
      },
      'pt': {
        'Estados Unidos': 'Estados Unidos',
        'Canadá': 'Canadá',
        'Haití': 'Haiti',
        'República Dominicana': 'República Dominicana',
        'México': 'México',
        'Francia': 'França',
        'Brasil': 'Brasil',
        'Chile': 'Chile',
      },
    };
    return names[language]?[country] ?? country;
  }

  @override
  Widget build(BuildContext context) {
    final location = _localizedCountry(context);

    return Container(
      width: double.infinity,
      color: Colors.transparent,
      padding: EdgeInsets.symmetric(
        horizontal: MediaQuery.sizeOf(context).width < 600 ? 16 : 24,
        vertical: 7,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.trWith('communityIn', {'country': location}),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  height: 1.2,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 9),
              AppSearchBar(onChanged: onSearchChanged),
            ],
          ),
        ),
      ),
    );
  }
}
