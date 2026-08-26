import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/marketplace_provider.dart';
import 'product_detail_screen.dart';
import '../../../shared/widgets/animated_favorite_button.dart';
import '../../../shared/widgets/app_back_button.dart';
import '../../../core/localization/app_locale_provider.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final marketplaceProvider = context.watch<MarketplaceProvider>();

    final favorites = marketplaceProvider.favorites;

    return Scaffold(
      appBar: AppBar(
        leadingWidth: 112,
        leading: const AppBackButton(
          showWhenCannotPop: false,
          foregroundColor: Colors.white,
        ),
        backgroundColor: const Color(0xFF0646D8),
        foregroundColor: Colors.white,
        title: Text(context.tr('favorites')),
      ),
      body: favorites.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.favorite_border,
                    size: 90,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    context.tr('noFavorites'),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    context.tr('favoriteHelp'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: EdgeInsets.symmetric(
                horizontal: MediaQuery.sizeOf(context).width > 840
                    ? (MediaQuery.sizeOf(context).width - 800) / 2
                    : 12,
                vertical: 8,
              ),
              itemCount: favorites.length,
              itemBuilder: (context, index) {
                final product = favorites[index];

                return InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProductDetailScreen(product: product),
                      ),
                    );
                  },
                  child: Card(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: product.images.isNotEmpty
                            ? Container(
                                width: 60,
                                height: 60,
                                color: const Color(0xFFF3F4F6),
                                child: Image.network(
                                  product.images.first,
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, _, _) =>
                                      const Icon(Icons.image_outlined),
                                ),
                              )
                            : const Icon(Icons.image_outlined),
                      ),
                      title: Text(
                        product.title,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEAF2FF),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '\$${product.price.toStringAsFixed(0)}',
                              style: const TextStyle(
                                color: Color(0xFF0057B8),
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${product.city}, ${product.country}',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      trailing: AnimatedFavoriteButton(
                        isFavorite: true,
                        onPressed: () {
                          marketplaceProvider.toggleFavorite(product);
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
