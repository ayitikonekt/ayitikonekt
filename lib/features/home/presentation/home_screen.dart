import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../marketplace/presentation/product_detail_screen.dart';
import '../../marketplace/presentation/all_products_screen.dart';
import '../../marketplace/presentation/categories_screen.dart';
import '../../marketplace/providers/marketplace_provider.dart';
import '../../profile/presentation/profile_screen.dart';
import 'location_settings_panel.dart';
import '../../auth/data/user_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/services/user_service.dart';
import '../../notifications/presentation/notifications_screen.dart';
import '../../news/data/news_catalog.dart';
import '../../news/presentation/news_detail_screen.dart';
import '../../news/presentation/news_screen.dart';

import '../../../shared/widgets/category_item.dart';
import '../../../shared/widgets/home_banner.dart';
import '../../../shared/widgets/news_card.dart';
import '../../../shared/widgets/product_card.dart';
import '../../../shared/widgets/section_title.dart';
import '../../../shared/widgets/stat_card.dart';
import '../../../core/localization/app_locale_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _SummaryValue extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryValue({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}

class _HomeScreenState extends State<HomeScreen> {
  bool _loaded = false;
  String _homeSearchQuery = '';
  Future<UserModel?>? _userFuture;

  String _defaultCityFor(String country) => switch (country) {
    'Estados Unidos' => 'New York',
    'Canadá' => 'Montréal',
    'República Dominicana' => 'Santo Domingo',
    'Haití' => 'Puerto Príncipe',
    'Francia' => 'Paris',
    'México' => 'Ciudad de México',
    'Brasil' => 'São Paulo',
    _ => 'Santiago',
  };

  void _reloadUser() {
    final authUser = context.read<AuthProvider>().user;
    setState(() {
      _userFuture = authUser == null
          ? null
          : UserService().getUser(authUser.uid);
    });
  }

  Future<void> _openLocationSettings() async {
    final user = await _userFuture;
    if (!mounted || user == null) return;
    final width = MediaQuery.sizeOf(context).width;
    bool? changed;

    if (width < 700) {
      changed = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        barrierColor: Colors.black45,
        builder: (_) => FractionallySizedBox(
          heightFactor: .92,
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
            child: LocationSettingsPanel(user: user),
          ),
        ),
      );
    } else {
      changed = await showGeneralDialog<bool>(
        context: context,
        barrierDismissible: true,
        barrierLabel: 'Cerrar ubicación',
        barrierColor: Colors.black38,
        transitionDuration: const Duration(milliseconds: 260),
        pageBuilder: (_, _, _) => Align(
          alignment: Alignment.centerRight,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: SizedBox.expand(child: LocationSettingsPanel(user: user)),
          ),
        ),
        transitionBuilder: (_, animation, _, child) => SlideTransition(
          position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
              .animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              ),
          child: child,
        ),
      );
    }

    if (changed == true && mounted) _reloadUser();
  }

  void _showMarketplaceSummary({
    required String title,
    required IconData icon,
    required Color color,
    String? category,
  }) {
    final provider = context.read<MarketplaceProvider>();
    final publications = category == null
        ? provider.allProducts
        : provider.allProducts
              .where((product) => product.category == category)
              .toList();
    final available = publications.where((product) => !product.isSold).length;
    final sold = publications.length - available;
    final average = publications.isEmpty
        ? 0.0
        : publications.fold<double>(
                0,
                (total, product) => total + product.price,
              ) /
              publications.length;

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: color.withValues(alpha: .14),
                child: Icon(icon, color: color, size: 30),
              ),
              const SizedBox(height: 14),
              Text(
                'Sumario de $title',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  _SummaryValue(
                    label: 'Total',
                    value: '${publications.length}',
                  ),
                  _SummaryValue(label: 'Disponibles', value: '$available'),
                  _SummaryValue(label: 'Vendidos', value: '$sold'),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F7FA),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Precio promedio: \$${average.toStringAsFixed(0)}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: publications.isEmpty
                    ? null
                    : () {
                        Navigator.pop(sheetContext);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AllProductsScreen(
                              category: category,
                              screenTitle: title,
                            ),
                          ),
                        );
                      },
                icon: const Icon(Icons.grid_view_rounded),
                label: Text(context.tr('viewListings')),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();

    final marketplaceProvider = context.read<MarketplaceProvider>();
    Future.microtask(marketplaceProvider.loadProducts);

    final authUser = context.read<AuthProvider>().user;
    if (authUser != null) {
      _userFuture = UserService().getUser(authUser.uid);
    }

    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) {
        setState(() {
          _loaded = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final categories = [
      (title: 'Vivienda', icon: Icons.home, color: Colors.blue),
      (title: 'Vehículos', icon: Icons.directions_car, color: Colors.red),
      (title: 'Empleos', icon: Icons.work, color: Colors.green),
      (
        title: 'Electrónica',
        icon: Icons.phone_android,
        color: Colors.deepPurple,
      ),
      (title: 'Moda', icon: Icons.checkroom, color: Colors.pink),
      (title: 'Servicios', icon: Icons.handyman, color: Colors.orange),
      (title: 'Mascotas', icon: Icons.pets, color: Colors.orange),
      (title: 'Otros', icon: Icons.more_horiz, color: Colors.blueGrey),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),

      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(176),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(22),
          ),
          child: AppBar(
            toolbarHeight: 58,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        clipBehavior: Clip.antiAlias,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(22)),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Color(0xFF0646D8),
                Color(0xFF0D47A1),
                Color(0xFFF20D1B),
              ],
              stops: [0, .62, 1],
            ),
          ),
        ),
        centerTitle: false,
        title: FutureBuilder<UserModel?>(
          future: _userFuture,
          builder: (context, snapshot) {
            final user = snapshot.data;
            final country = user?.country.trim().isNotEmpty == true
                ? user!.country.trim()
                : 'Chile';
            final city = user?.city.trim().isNotEmpty == true
                ? user!.city.trim()
                : _defaultCityFor(country);

            return InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: _openLocationSettings,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      color: Colors.white,
                      size: 21,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        '$city, $country',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 3),
                    const Icon(
                      Icons.keyboard_arrow_down,
                      size: 18,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        actions: [
          IconButton(
            tooltip: 'Notificaciones',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationsScreen()),
              );
            },
            icon: const Icon(Icons.notifications_none, color: Colors.white),
          ),
          IconButton(
            tooltip: 'Perfil',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
            icon: const Icon(Icons.person_outline, color: Colors.white),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(118),
          child: FutureBuilder<UserModel?>(
            future: _userFuture,
            builder: (context, snapshot) => HomeBanner(
              country: snapshot.data?.country.isNotEmpty == true
                  ? snapshot.data!.country
                  : 'Chile',
              onSearchChanged: (value) {
                setState(() {
                  _homeSearchQuery = value.trim().toLowerCase();
                });
              },
            ),
          ),
            ),
          ),
        ),
      ),

      body: SafeArea(
        child: AnimatedOpacity(
          opacity: _loaded ? 1 : 0,
          duration: const Duration(milliseconds: 500),

          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: MediaQuery.sizeOf(context).width > 1140
                  ? (MediaQuery.sizeOf(context).width - 1100) / 2
                  : MediaQuery.sizeOf(context).width < 600
                  ? 16
                  : 24,
              vertical: 0,
            ),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                const SizedBox(height: 18),

                // Estadísticas
                Consumer<MarketplaceProvider>(
                  builder: (context, provider, _) {
                    final jobs = provider.allProducts
                        .where((product) => product.category == 'Empleos')
                        .length;
                    final services = provider.allProducts
                        .where((product) => product.category == 'Servicios')
                        .length;

                    return Row(
                      children: [
                        StatCard(
                          title: context.tr('products'),
                          value: '${provider.allProducts.length}',
                          icon: Icons.inventory_2,
                          color: Colors.blue,
                          onTap: () => _showMarketplaceSummary(
                            title: context.tr('products'),
                            icon: Icons.inventory_2,
                            color: Colors.blue,
                          ),
                        ),
                        StatCard(
                          title: context.tr('jobs'),
                          value: '$jobs',
                          icon: Icons.work,
                          color: Colors.green,
                          onTap: () => _showMarketplaceSummary(
                            title: context.tr('jobs'),
                            icon: Icons.work,
                            color: Colors.green,
                            category: 'Empleos',
                          ),
                        ),
                        StatCard(
                          title: context.tr('services'),
                          value: '$services',
                          icon: Icons.handyman,
                          color: Colors.orange,
                          onTap: () => _showMarketplaceSummary(
                            title: context.tr('services'),
                            icon: Icons.handyman,
                            color: Colors.orange,
                            category: 'Servicios',
                          ),
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 22),

                // Categorías
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

                const SizedBox(height: 8),

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
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
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
                          final category = item.title == 'Moda'
                              ? 'Ropa'
                              : item.title;

                          final translatedTitle = switch (item.title) {
                            'Vivienda' => context.tr('housing'),
                            'Vehículos' => context.tr('vehicles'),
                            'Empleos' => context.tr('jobs'),
                            'Electrónica' => context.tr('electronics'),
                            'Moda' => context.tr('fashion'),
                            'Servicios' => context.tr('services'),
                            'Muebles' => context.tr('furniture'),
                            'Mascotas' => context.tr('pets'),
                            _ => context.tr('other'),
                          };
                          return CategoryItem(
                            icon: item.icon,
                            title: translatedTitle,
                            color: item.color,
                            onTap: () {
                              if (item.title == 'Otros') {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const CategoriesScreen(),
                                  ),
                                );
                                return;
                              }

                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AllProductsScreen(
                                    category: category,
                                    screenTitle: item.title,
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                ),

                const SizedBox(height: 30),

                // Publicaciones recientes
                SectionTitle(
                  title: context.tr('recentListings'),
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

                const SizedBox(height: 10),

                SizedBox(
                  height: 370,
                  child: Consumer<MarketplaceProvider>(
                    builder: (context, marketplaceProvider, _) {
                      final products = marketplaceProvider.allProducts.where((
                        product,
                      ) {
                        if (_homeSearchQuery.isEmpty) return true;

                        return product.title.toLowerCase().contains(
                              _homeSearchQuery,
                            ) ||
                            product.description.toLowerCase().contains(
                              _homeSearchQuery,
                            ) ||
                            product.category.toLowerCase().contains(
                              _homeSearchQuery,
                            ) ||
                            product.city.toLowerCase().contains(
                              _homeSearchQuery,
                            ) ||
                            product.country.toLowerCase().contains(
                              _homeSearchQuery,
                            );
                      }).toList();

                      if (products.isEmpty) {
                        return const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.search_off_rounded,
                                size: 48,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 10),
                              Text(
                                'No encontramos publicaciones',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: products.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 18),
                        itemBuilder: (context, index) {
                          final product = products[index];

                          final screenWidth = MediaQuery.sizeOf(context).width;
                          final cardWidth = screenWidth < 600
                              ? ((screenWidth - 58) / 2)
                                    .clamp(136.0, 260.0)
                                    .toDouble()
                              : 280.0;

                          return SizedBox(
                            width: cardWidth,
                            child: ProductCard(
                              title: product.title,
                              price: product.price,
                              location: '${product.city}, ${product.country}',
                              imagePath: product.images.isNotEmpty
                                  ? product.images.first
                                  : '',
                              category: product.category,
                              isFavorite: marketplaceProvider.isFavorite(
                                product,
                              ),
                              isFeatured: product.isFeatured,
                              favoriteCount: product.favorites,

                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        ProductDetailScreen(product: product),
                                  ),
                                );
                              },

                              onFavoriteTap: () {
                                marketplaceProvider.toggleFavorite(product);
                              },
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),

                const SizedBox(height: 30),

                // Noticias
                SectionTitle(
                  title: context.tr('recentNews'),
                  actionText: context.tr('viewAllMasculine'),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const NewsScreen()),
                  ),
                ),

                const SizedBox(height: 10),

                ...newsCatalog
                    .take(3)
                    .map(
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

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
