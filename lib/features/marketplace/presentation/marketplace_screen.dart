import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../shared/widgets/app_back_button.dart';
import '../../../shared/widgets/app_search_bar.dart';
import '../../../shared/widgets/category_item.dart';
import '../../../shared/widgets/product_card.dart';
import '../../../shared/widgets/section_title.dart';
import '../models/product_model.dart';
import '../providers/marketplace_provider.dart';
import 'all_products_screen.dart';
import 'categories_screen.dart';
import 'publication_type_screen.dart';
import 'product_detail_screen.dart';
import 'product_filter_screen.dart';
import '../../../core/localization/app_locale_provider.dart';

class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<MarketplaceProvider>().loadProducts();
    });
  }

  Future<void> _openFilters() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final width = MediaQuery.sizeOf(context).width;

    if (width < 700) {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        barrierColor: Colors.black45,
        builder: (_) => FractionallySizedBox(
          heightFactor: .94,
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
            child: const ProductFilterScreen(),
          ),
        ),
      );
      return;
    }

    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Cerrar filtros',
      barrierColor: Colors.black38,
      transitionDuration: const Duration(milliseconds: 260),
      pageBuilder: (context, animation, secondaryAnimation) => Align(
        alignment: Alignment.centerRight,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: width >= 1200 ? 460 : 420),
          child: const SizedBox.expand(child: ProductFilterScreen()),
        ),
      ),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final slide = Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
            .animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            );
        return SlideTransition(position: slide, child: child);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MarketplaceProvider>();
    final List<ProductModel> products = provider.products;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final horizontalPadding = screenWidth > 1140
        ? (screenWidth - 1100) / 2
        : screenWidth < 600
        ? 16.0
        : 24.0;

    final categories = <({String title, IconData icon, Color color})>[
      (title: 'Todas', icon: Icons.apps, color: Colors.indigo),
      (title: 'Vehículos', icon: Icons.directions_car, color: Colors.red),
      (
        title: 'Electrónica',
        icon: Icons.phone_android,
        color: Colors.deepPurple,
      ),
      (title: 'Vivienda', icon: Icons.home, color: Colors.blue),
      (title: 'Empleos', icon: Icons.work, color: Colors.green),
      (title: 'Servicios', icon: Icons.handyman, color: Colors.orange),
      (title: 'Ropa', icon: Icons.checkroom, color: Colors.red),
      (title: 'Otros', icon: Icons.more_horiz, color: Colors.blueGrey),
    ];

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
        title: const Text(
          'Marketplace',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10, top: 7, bottom: 7),
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              child: IconButton(
                color: const Color(0xFF0646D8),
                tooltip: 'Filtros',
                onPressed: _openFilters,
                icon: const Icon(Icons.tune_rounded),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: CustomScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          slivers: [
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                20,
                horizontalPadding,
                0,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate.fixed([
                  AppSearchBar(onChanged: provider.updateSearch),
                  const SizedBox(height: 18),
                  SectionTitle(
                    title: context.tr('categories'),
                    actionText: context.tr('viewAll'),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CategoriesScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final columns = constraints.maxWidth < 430
                            ? 4
                            : constraints.maxWidth < 760
                            ? 6
                            : 9;

                        return GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: categories.length,
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: columns,
                                mainAxisSpacing: 8,
                                crossAxisSpacing: 8,
                                childAspectRatio: columns == 4
                                    ? .62
                                    : columns == 6
                                    ? .82
                                    : 1.0,
                              ),
                          itemBuilder: (context, index) {
                            final item = categories[index];
                            return CategoryItem(
                              title: item.title,
                              icon: item.icon,
                              color: item.color,
                              onTap: item.title == 'Todas'
                                  ? provider.clearFilters
                                  : item.title == 'Otros'
                                  ? () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              const CategoriesScreen(),
                                        ),
                                      );
                                    }
                                  : () => provider.updateCategory(item.title),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  SectionTitle(
                    title: context.tr('recentProducts'),
                    actionText: context.tr('viewAllMasculine'),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AllProductsScreen(),
                        ),
                      );
                    },
                  ),
                  Text(
                    '${products.length} ${context.tr(products.length == 1 ? 'productFound' : 'productsFound')}',
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                ]),
              ),
            ),
            if (provider.loading)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              )
            else if (products.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _EmptyMarketplace(message: provider.errorMessage),
              )
            else
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  0,
                  horizontalPadding,
                  100,
                ),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 310,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: screenWidth < 600 ? .50 : .63,
                  ),
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final product = products[index];
                    return ProductCard(
                      title: product.title,
                      price: product.price,
                      priceNegotiable: product.priceNegotiable,
                      location: '${product.city}, ${product.country}',
                      category: product.category,
                      imagePath: product.images.isNotEmpty
                          ? product.images.first
                          : '',
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
                  }, childCount: products.length),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFFF20D1B),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: Text(context.tr('publish')),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PublicationTypeScreen()),
          );
        },
      ),
    );
  }
}

class _EmptyMarketplace extends StatelessWidget {
  final String? message;

  const _EmptyMarketplace({this.message});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.inventory_2_outlined, size: 70, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            message ?? 'Todavía no hay publicaciones',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            message == null
                ? 'Sé el primero en publicar un producto.'
                : 'Revisa tu conexión e inténtalo nuevamente.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
