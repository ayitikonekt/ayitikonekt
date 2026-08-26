import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/localization/app_locale_provider.dart';
import '../../../shared/widgets/app_back_button.dart';

import '../../../shared/widgets/product_card.dart';

import '../models/product_model.dart';
import '../providers/marketplace_provider.dart';
import 'product_detail_screen.dart';

class AllProductsScreen extends StatelessWidget {
  final String? category;
  final String? screenTitle;

  const AllProductsScreen({super.key, this.category, this.screenTitle});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MarketplaceProvider>();
    final List<ProductModel> products = category == null
        ? provider.allProducts
        : provider.allProducts
              .where((product) => product.category == category)
              .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),

      appBar: AppBar(
        leadingWidth: 112,
        leading: const AppBackButton(
          showWhenCannotPop: false,
          foregroundColor: Colors.white,
        ),
        elevation: 0,
        backgroundColor: const Color(0xFF0646D8),
        foregroundColor: Colors.white,
        centerTitle: true,
        title: Text(
          screenTitle ?? context.tr('allProducts'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),

      body: products.isEmpty
          ? Center(
              child: Text(
                context.tr('noPublishedProducts'),
                style: const TextStyle(fontSize: 18),
              ),
            )
          : LayoutBuilder(
              builder: (context, constraints) => Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: constraints.maxWidth > 1140
                      ? (constraints.maxWidth - 1100) / 2
                      : constraints.maxWidth < 600
                      ? 12
                      : 24,
                  vertical: 16,
                ),
                child: GridView.builder(
                  itemCount: products.length,

                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 310,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.63,
                  ),

                  itemBuilder: (context, index) {
                    final product = products[index];

                    return ProductCard(
                      title: product.title,
                      price: product.price,
                      location: "${product.city}, ${product.country}",
                      category: product.category,
                      imagePath: product.images.isNotEmpty
                          ? product.images.first
                          : "",
                      isFavorite: provider.isFavorite(product),
                      isFeatured: false,
                      favoriteCount: product.favorites,

                      onFavoriteTap: () {
                        provider.toggleFavorite(product);
                      },

                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                ProductDetailScreen(product: product),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
    );
  }
}
