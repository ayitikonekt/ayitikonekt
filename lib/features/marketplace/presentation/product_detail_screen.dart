import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/widgets/app_back_button.dart';

import 'package:url_launcher/url_launcher.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/data/user_model.dart';
import '../../auth/services/user_service.dart';
import '../models/product_model.dart';
import '../providers/marketplace_provider.dart';
import 'edit_product_screen.dart';
import '../services/storage_service.dart';
import '../../reviews/presentation/create_review_sheet.dart';
import '../../reviews/presentation/reviews_screen.dart';
import '../../reviews/services/review_service.dart';
import '../../../core/localization/app_locale_provider.dart';

class ProductDetailScreen extends StatefulWidget {
  final ProductModel product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final PageController _pageController = PageController();
  late Future<UserModel?> _sellerFuture;
  final StorageService _storageService = StorageService();

  int _currentImage = 0;
  bool _deleting = false;

  Future<void> _rateSeller() async {
    final authUser = context.read<AuthProvider>().user;
    if (authUser == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.tr('signInToReview'))));
      return;
    }
    if (authUser.uid == widget.product.sellerId) return;

    final alreadyReviewed = await ReviewService().alreadyReviewed(
      widget.product.id,
      authUser.uid,
    );
    if (!mounted) return;
    if (alreadyReviewed) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.tr('alreadyReviewed'))));
      return;
    }

    final reviewer = await UserService().getUser(authUser.uid);
    if (!mounted) return;
    if (reviewer == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.tr('profileNotFound'))));
      return;
    }

    final created = await showCreateReviewSheet(
      context,
      product: widget.product,
      reviewer: reviewer,
    );
    if (!mounted || created != true) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(context.tr('reviewPublished'))));
    setState(
      () => _sellerFuture = UserService().getUser(widget.product.sellerId),
    );
  }

  @override
  void initState() {
    super.initState();
    _sellerFuture = UserService().getUser(widget.product.sellerId);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final currentUserId = context.read<AuthProvider>().user?.uid;
      if (currentUserId == widget.product.sellerId) return;
      context.read<MarketplaceProvider>().recordView(widget.product);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _openUrl(Uri uri) async {
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _openImageViewer(int initialIndex) {
    final viewerController = PageController(initialPage: initialIndex);

    showDialog(
      context: context,
      barrierColor: Colors.black,
      builder: (_) {
        return Dialog(
          backgroundColor: Colors.black,
          insetPadding: EdgeInsets.zero,
          child: Stack(
            children: [
              PageView.builder(
                controller: viewerController,
                itemCount: widget.product.images.length,
                itemBuilder: (context, index) {
                  return Image.network(
                    widget.product.images[index],
                    fit: BoxFit.contain,
                    width: double.infinity,
                    height: double.infinity,
                  );
                },
              ),

              // Flecha izquierda
              Positioned(
                left: 16,
                top: 0,
                bottom: 0,
                child: Center(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.chevron_left,
                        color: Colors.white,
                        size: 40,
                      ),
                      onPressed: () {
                        final currentPage =
                            viewerController.page?.round() ?? initialIndex;

                        if (currentPage > 0) {
                          viewerController.previousPage(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeInOut,
                          );
                        }
                      },
                    ),
                  ),
                ),
              ),

              // Flecha derecha
              Positioned(
                right: 16,
                top: 0,
                bottom: 0,
                child: Center(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.chevron_right,
                        color: Colors.white,
                        size: 40,
                      ),
                      onPressed: () {
                        final currentPage =
                            viewerController.page?.round() ?? initialIndex;

                        if (currentPage < widget.product.images.length - 1) {
                          viewerController.nextPage(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeInOut,
                          );
                        }
                      },
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 20,
                right: 20,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _openSellerPhotoViewer(String photoUrl, String sellerName) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (dialogContext) => Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                minScale: 0.8,
                maxScale: 4,
                child: Image.network(
                  photoUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => const Icon(
                    Icons.broken_image_outlined,
                    color: Colors.white,
                    size: 64,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 16,
              left: 16,
              child: IconButton(
                tooltip: 'Cerrar',
                onPressed: () => Navigator.of(dialogContext).pop(),
                icon: const Icon(Icons.close, color: Colors.white),
              ),
            ),
            if (sellerName.isNotEmpty)
              Positioned(
                left: 24,
                right: 24,
                bottom: 28,
                child: Text(
                  sellerName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteProduct(ProductModel product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar publicación'),
        content: const Text(
          '¿Seguro que deseas eliminar este producto? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _deleting = true);

    try {
      await context.read<MarketplaceProvider>().deleteProduct(product.id);

      // La publicación ya fue eliminada. Luego limpiamos sus imágenes.
      await Future.wait(product.images.map(_storageService.deleteImage));

      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      messenger.showSnackBar(
        const SnackBar(content: Text('Publicación eliminada correctamente.')),
      );
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo eliminar la publicación: $error')),
      );
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final marketplaceProvider = context.watch<MarketplaceProvider>();
    final product = marketplaceProvider.allProducts.firstWhere(
      (item) => item.id == widget.product.id,
      orElse: () => widget.product,
    );

    final user = context.watch<AuthProvider>().user;

    final bool favorite = marketplaceProvider.isFavorite(product);

    final bool isOwner = user?.uid == product.sellerId;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,

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
          "Detalle del producto",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          if (isOwner)
            IconButton(
              tooltip: 'Editar publicación',
              icon: const Icon(Icons.edit, color: Colors.white),
              onPressed: () async {
                final updated = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EditProductScreen(product: product),
                  ),
                );

                if (updated == true && context.mounted) {
                  Navigator.pop(context, true);
                }
              },
            ),

          if (isOwner)
            IconButton(
              tooltip: 'Eliminar publicación',
              onPressed: _deleting ? null : () => _deleteProduct(product),
              icon: _deleting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.delete_outline, color: Colors.red),
            ),

          IconButton(
            onPressed: () {
              marketplaceProvider.toggleFavorite(product);
            },
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              transitionBuilder: (child, animation) {
                return ScaleTransition(scale: animation, child: child);
              },
              child: Icon(
                favorite ? Icons.favorite : Icons.favorite_border,
                key: ValueKey<bool>(favorite),
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
        ],
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: MediaQuery.sizeOf(context).width > 1140
                ? (MediaQuery.sizeOf(context).width - 1100) / 2
                : 0,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Imagen principal
                  SizedBox(
                    height: (MediaQuery.sizeOf(context).height * .48)
                        .clamp(
                          240.0,
                          MediaQuery.sizeOf(context).width < 700
                              ? 320.0
                              : 500.0,
                        )
                        .toDouble(),
                    width: double.infinity,
                    child: Stack(
                      children: [
                        // Imagen principal
                        Positioned.fill(
                          child: product.images.isNotEmpty
                              ? PageView.builder(
                                  controller: _pageController,
                                  onPageChanged: (index) {
                                    setState(() {
                                      _currentImage = index;
                                    });
                                  },
                                  itemCount: product.images.length,
                                  itemBuilder: (context, index) {
                                    return GestureDetector(
                                      onTap: () => _openImageViewer(index),
                                      child: ColoredBox(
                                        color: const Color(0xFFF3F4F6),
                                        child: InteractiveViewer(
                                          child: Image.network(
                                            product.images[index],
                                            fit: BoxFit.contain,
                                            width: double.infinity,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                )
                              : Container(
                                  color: Colors.grey.shade300,
                                  child: const Center(
                                    child: Icon(
                                      Icons.image_not_supported_outlined,
                                    ),
                                  ),
                                ),
                        ),

                        if (product.images.length > 1)
                          Positioned(
                            bottom: 12,
                            left: 0,
                            right: 0,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(product.images.length, (
                                index,
                              ) {
                                return Container(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                  ),
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _currentImage == index
                                        ? const Color(0xFF0057B8)
                                        : Colors.white54,
                                  ),
                                );
                              }),
                            ),
                          ),
                        if (product.images.isNotEmpty)
                          Positioned(
                            right: 14,
                            bottom: 14,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: .72),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Text(
                                '${_currentImage + 1} / ${product.images.length}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        // Flecha izquierda
                        if (product.images.length > 1)
                          Positioned(
                            left: 10,
                            top: 0,
                            bottom: 0,
                            child: Center(
                              child: IconButton(
                                onPressed: _currentImage > 0
                                    ? () {
                                        _pageController.previousPage(
                                          duration: const Duration(
                                            milliseconds: 250,
                                          ),
                                          curve: Curves.easeInOut,
                                        );
                                      }
                                    : null,
                                icon: const Icon(
                                  Icons.chevron_left,
                                  size: 40,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),

                        // Flecha derecha
                        if (product.images.length > 1)
                          Positioned(
                            right: 10,
                            top: 0,
                            bottom: 0,
                            child: Center(
                              child: IconButton(
                                onPressed:
                                    _currentImage < product.images.length - 1
                                    ? () {
                                        _pageController.nextPage(
                                          duration: const Duration(
                                            milliseconds: 250,
                                          ),
                                          curve: Curves.easeInOut,
                                        );
                                      }
                                    : null,
                                icon: const Icon(
                                  Icons.chevron_right,
                                  size: 40,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  Padding(
                    padding: EdgeInsets.all(
                      MediaQuery.sizeOf(context).width < 700 ? 18 : 28,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEAF2FF),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                product.category,
                                style: const TextStyle(
                                  color: Color(0xFF0057B8),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),

                            const Spacer(),

                            if (product.isFeatured)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.amber.shade700,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text(
                                  "DESTACADO",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        Text(
                          product.title,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 16),

                        Text(
                          "\$${product.price.toStringAsFixed(0)}",
                          style: const TextStyle(
                            fontSize: 28,
                            color: Color(0xFFF20D1B),
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 18),

                        Row(
                          children: [
                            const Icon(Icons.location_on, color: Colors.red),

                            const SizedBox(width: 8),

                            Expanded(
                              child: Text(
                                "${product.city}, ${product.country}",
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 18),

                        Row(
                          children: [
                            const Icon(
                              Icons.inventory_2_outlined,
                              color: Colors.grey,
                            ),

                            const SizedBox(width: 8),

                            Text(
                              product.condition,
                              style: const TextStyle(fontSize: 16),
                            ),
                          ],
                        ),

                        const SizedBox(height: 18),

                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Publicado: ${product.createdAt.day}/${product.createdAt.month}/${product.createdAt.year}',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            Flexible(
                              child: Text(
                                'ID: ${product.id}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.right,
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        const Text(
                          "Descripción",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 12),

                        Text(
                          product.description,
                          style: const TextStyle(fontSize: 16, height: 1.5),
                        ),

                        const SizedBox(height: 30),
                        const Text(
                          "Información del vendedor",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 16),

                        FutureBuilder<UserModel?>(
                          future: _sellerFuture,
                          builder: (context, snapshot) {
                            final seller = snapshot.data;
                            final sellerName = seller == null
                                ? product.sellerName
                                : '${seller.name} ${seller.lastName}'.trim();
                            final sellerEmail =
                                seller?.email ?? product.sellerEmail;
                            final sellerPhone =
                                seller?.phone ?? product.sellerPhone;
                            final sellerPhoto =
                                seller?.photo ?? product.sellerPhoto;

                            return Card(
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    Semantics(
                                      button: sellerPhoto.isNotEmpty,
                                      label: sellerPhoto.isNotEmpty
                                          ? 'Ver foto de $sellerName'
                                          : 'Vendedor sin foto de perfil',
                                      child: GestureDetector(
                                        onTap: sellerPhoto.isEmpty
                                            ? null
                                            : () => _openSellerPhotoViewer(
                                                sellerPhoto,
                                                sellerName,
                                              ),
                                        child: CircleAvatar(
                                          radius: 30,
                                          backgroundImage:
                                              sellerPhoto.isNotEmpty
                                              ? NetworkImage(sellerPhoto)
                                              : null,
                                          child: sellerPhoto.isEmpty
                                              ? const Icon(
                                                  Icons.person,
                                                  size: 32,
                                                )
                                              : null,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            sellerName.isEmpty
                                                ? sellerEmail
                                                : sellerName,
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          if (seller != null) ...[
                                            const SizedBox(height: 5),
                                            Wrap(
                                              spacing: 10,
                                              runSpacing: 4,
                                              children: [
                                                Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    const Icon(
                                                      Icons.star,
                                                      color: Colors.amber,
                                                      size: 17,
                                                    ),
                                                    const SizedBox(width: 3),
                                                    Text(
                                                      seller.reputation
                                                          .toStringAsFixed(1),
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                if (seller.verified)
                                                  const Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Icon(
                                                        Icons.verified,
                                                        color: Colors.green,
                                                        size: 17,
                                                      ),
                                                      SizedBox(width: 4),
                                                      Text(
                                                        'Miembro verificado',
                                                        style: TextStyle(
                                                          color: Colors.green,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                              ],
                                            ),
                                          ],
                                          if (sellerEmail.isNotEmpty) ...[
                                            const SizedBox(height: 6),
                                            Text(
                                              sellerEmail,
                                              style: const TextStyle(
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ],
                                          if (sellerPhone.isNotEmpty) ...[
                                            const SizedBox(height: 6),
                                            Text(
                                              sellerPhone,
                                              style: const TextStyle(
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            OutlinedButton.icon(
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      ReviewsScreen(userId: product.sellerId),
                                ),
                              ),
                              icon: const Icon(Icons.reviews_outlined),
                              label: Text(context.tr('viewReviews')),
                            ),
                            if (!isOwner)
                              ElevatedButton.icon(
                                onPressed: _rateSeller,
                                icon: const Icon(Icons.star_rounded),
                                label: Text(context.tr('rateSeller')),
                              ),
                          ],
                        ),

                        const SizedBox(height: 28),

                        const Text(
                          "Información adicional",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 14),

                        Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(18),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.visibility,
                                      color: Colors.blue,
                                    ),

                                    const SizedBox(width: 12),

                                    const Text("Visualizaciones"),

                                    const Spacer(),

                                    Text(
                                      product.views.toString(),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),

                                const Divider(height: 30),

                                Row(
                                  children: [
                                    const Icon(
                                      Icons.favorite,
                                      color: Colors.red,
                                    ),

                                    const SizedBox(width: 12),

                                    const Text("Favoritos"),

                                    const Spacer(),

                                    Text(
                                      product.favorites.toString(),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),

                                const Divider(height: 30),

                                Row(
                                  children: [
                                    Icon(
                                      product.isSold
                                          ? Icons.cancel
                                          : Icons.check_circle,
                                      color: product.isSold
                                          ? Colors.red
                                          : Colors.green,
                                    ),

                                    const SizedBox(width: 12),

                                    const Text("Estado"),

                                    const Spacer(),

                                    Text(
                                      product.isSold ? "Vendido" : "Disponible",
                                      style: TextStyle(
                                        color: product.isSold
                                            ? Colors.red
                                            : Colors.green,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 30),

                        FutureBuilder<UserModel?>(
                          future: _sellerFuture,
                          builder: (context, snapshot) {
                            final seller = snapshot.data;
                            final phone = seller?.phone ?? product.sellerPhone;
                            final email = seller?.email ?? product.sellerEmail;

                            return Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF0646D8),
                                      foregroundColor: Colors.white,
                                      disabledBackgroundColor: const Color(
                                        0xFF0646D8,
                                      ).withValues(alpha: .35),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                      ),
                                    ),
                                    onPressed: phone.isEmpty
                                        ? null
                                        : () =>
                                              _openUrl(Uri.parse('tel:$phone')),
                                    icon: const Icon(Icons.phone, size: 19),
                                    label: const Text('Llamar'),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: const Color(0xFF0646D8),
                                      side: const BorderSide(
                                        color: Color(0xFF0646D8),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                      ),
                                    ),
                                    onPressed: email.isEmpty
                                        ? null
                                        : () => _openUrl(
                                            Uri(scheme: 'mailto', path: email),
                                          ),
                                    icon: const Icon(Icons.email, size: 19),
                                    label: const Text('Correo'),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFF20D1B),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                      ),
                                    ),
                                    onPressed: phone.isEmpty
                                        ? null
                                        : () {
                                            var number = phone.replaceAll(
                                              RegExp(r'[^0-9]'),
                                              '',
                                            );
                                            if (number.length == 9) {
                                              number = '56$number';
                                            }
                                            _openUrl(
                                              Uri.parse(
                                                'https://wa.me/$number',
                                              ),
                                            );
                                          },
                                    icon: const Icon(Icons.chat, size: 19),
                                    label: const Text('Chat'),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),

                        const SizedBox(height: 20),
                      ],
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
