import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../shared/widgets/app_back_button.dart';
import '../../auth/providers/auth_provider.dart';
import '../../marketplace/models/product_model.dart';
import '../../marketplace/presentation/product_detail_screen.dart';
import '../../marketplace/providers/marketplace_provider.dart';

class MyProductsScreen extends StatefulWidget {
  const MyProductsScreen({super.key});

  @override
  State<MyProductsScreen> createState() => _MyProductsScreenState();
}

class _MyProductsScreenState extends State<MyProductsScreen> {
  final Set<String> _selectedIds = {};
  bool _deleting = false;

  bool get _selectionMode => _selectedIds.isNotEmpty;

  void _toggleSelection(String id) {
    setState(() {
      if (!_selectedIds.add(id)) _selectedIds.remove(id);
    });
  }

  void _toggleSelectAll(List<ProductModel> products) {
    final productIds = products.map((product) => product.id).toSet();
    final allSelected =
        productIds.isNotEmpty && _selectedIds.containsAll(productIds);

    setState(() {
      if (allSelected) {
        _selectedIds.removeAll(productIds);
      } else {
        _selectedIds.addAll(productIds);
      }
    });
  }

  Future<void> _openProduct(ProductModel product) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => ProductDetailScreen(product: product)),
    );
    if (changed == true && mounted) {
      await context.read<MarketplaceProvider>().loadProducts();
    }
  }

  Future<void> _deleteSelected() async {
    if (_selectedIds.isEmpty || _deleting) return;

    final count = _selectedIds.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          count == 1 ? 'Eliminar publicación' : 'Eliminar publicaciones',
        ),
        content: Text(
          count == 1
              ? '¿Quieres eliminar esta publicación definitivamente?'
              : '¿Quieres eliminar las $count publicaciones seleccionadas definitivamente?',
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
    final provider = context.read<MarketplaceProvider>();
    final ids = _selectedIds.toList();

    try {
      for (final id in ids) {
        await provider.deleteProduct(id);
      }
      if (!mounted) return;
      setState(() {
        _selectedIds.clear();
        _deleting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            count == 1
                ? 'Publicación eliminada'
                : '$count publicaciones eliminadas',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _deleting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudieron eliminar: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final marketplaceProvider = context.watch<MarketplaceProvider>();
    final uid = authProvider.user?.uid;

    final myProducts = uid == null
        ? <ProductModel>[]
        : marketplaceProvider.allProducts
              .where((product) => product.sellerId == uid)
              .toList();

    return Scaffold(
      appBar: AppBar(
        leadingWidth: 112,
        leading: _selectionMode
            ? IconButton(
                tooltip: 'Cancelar selección',
                onPressed: _deleting
                    ? null
                    : () => setState(_selectedIds.clear),
                icon: const Icon(Icons.close, color: Colors.white),
              )
            : const AppBackButton(
                showWhenCannotPop: false,
                foregroundColor: Colors.white,
              ),
        backgroundColor: const Color(0xFF0646D8),
        foregroundColor: Colors.white,
        title: Text(
          _selectionMode
              ? '${_selectedIds.length} seleccionada${_selectedIds.length == 1 ? '' : 's'}'
              : 'Mis publicaciones',
        ),
        actions: [
          if (myProducts.isNotEmpty)
            IconButton(
              tooltip:
                  _selectedIds.containsAll(
                    myProducts.map((product) => product.id),
                  )
                  ? 'Deseleccionar todas'
                  : 'Seleccionar todas',
              onPressed: _deleting ? null : () => _toggleSelectAll(myProducts),
              icon: Icon(
                _selectedIds.containsAll(
                      myProducts.map((product) => product.id),
                    )
                    ? Icons.deselect
                    : Icons.select_all,
                color: Colors.white,
              ),
            ),
          if (_selectionMode)
            IconButton(
              tooltip: 'Eliminar seleccionadas',
              onPressed: _deleting ? null : _deleteSelected,
              icon: _deleting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.red,
                      ),
                    )
                  : const Icon(Icons.delete_outline, color: Colors.red),
            ),
        ],
      ),
      body: uid == null
          ? const Center(child: Text('Usuario no autenticado'))
          : _buildBody(marketplaceProvider, myProducts),
    );
  }

  Widget _buildBody(MarketplaceProvider provider, List<ProductModel> products) {
    if (provider.loading && provider.allProducts.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (products.isEmpty) {
      return RefreshIndicator(
        onRefresh: provider.loadProducts,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 150),
            Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey),
            SizedBox(height: 20),
            Center(
              child: Text(
                'Aún no tienes publicaciones',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(height: 8),
            Center(child: Text('Tus productos publicados aparecerán aquí.')),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: provider.loadProducts,
      child: ListView.separated(
        padding: EdgeInsets.symmetric(
          horizontal: MediaQuery.sizeOf(context).width > 840
              ? (MediaQuery.sizeOf(context).width - 800) / 2
              : 16,
          vertical: 16,
        ),
        itemCount: products.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final product = products[index];
          final selected = _selectedIds.contains(product.id);

          return Card(
            color: selected ? const Color(0xFFE8F0FE) : null,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(
                color: selected ? const Color(0xFF0D47A1) : Colors.transparent,
                width: 2,
              ),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(12),
              onTap: () => _selectionMode
                  ? _toggleSelection(product.id)
                  : _openProduct(product),
              onLongPress: () => _toggleSelection(product.id),
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 70,
                  height: 70,
                  child: product.images.isNotEmpty
                      ? ColoredBox(
                          color: const Color(0xFFF1F5F9),
                          child: Image.network(
                            product.images.first,
                            fit: BoxFit.contain,
                            errorBuilder: (_, _, _) =>
                                const Icon(Icons.image_not_supported_outlined),
                          ),
                        )
                      : const ColoredBox(
                          color: Color(0xFFF1F5F9),
                          child: Icon(Icons.image_outlined),
                        ),
                ),
              ),
              title: Text(
                product.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '\$${product.price.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0D47A1),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text('${product.city}, ${product.country}'),
                  ],
                ),
              ),
              trailing: Checkbox(
                value: selected,
                onChanged: (_) => _toggleSelection(product.id),
              ),
            ),
          );
        },
      ),
    );
  }
}
