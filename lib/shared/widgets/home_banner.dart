import 'package:flutter/material.dart';

import '../../core/localization/app_locale_provider.dart';
import 'app_search_bar.dart';

class HomeBanner extends StatelessWidget {
  final String country;
  final ValueChanged<String>? onSearchChanged;

  const HomeBanner({
    super.key,
    required this.country,
    this.onSearchChanged,
  });

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
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0646D8),
            Color(0xFF0D47A1),
            Color(0xFFF20D1B),
          ],
          stops: [0, .68, 1],
        ),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 16, offset: Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSearchBar(onChanged: onSearchChanged),
          const SizedBox(height: 28),
          Text(
            context.trWith('communityIn', {'country': location}),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              height: 1.25,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
