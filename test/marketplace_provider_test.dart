import 'dart:async';

import 'package:ayitikonekt_app/features/marketplace/models/product_model.dart';
import 'package:ayitikonekt_app/features/marketplace/providers/marketplace_provider.dart';
import 'package:ayitikonekt_app/features/marketplace/services/favorite_service.dart';
import 'package:ayitikonekt_app/features/marketplace/services/product_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MarketplaceProvider', () {
    late FakeProductRepository products;
    late FakeFavoriteRepository favorites;
    late MarketplaceProvider provider;

    setUp(() {
      products = FakeProductRepository([
        product(id: '1', title: 'Teléfono', price: 100),
        product(id: '2', title: 'Casa', price: 200),
      ]);
      favorites = FakeFavoriteRepository();
      provider = MarketplaceProvider(
        productService: products,
        favoriteService: favorites,
      );
    });

    test('carga, busca y ordena publicaciones', () async {
      await provider.loadProducts();

      expect(provider.allProducts, hasLength(2));
      provider.updateSearch('teléfono');
      expect(provider.products.single.id, '1');

      provider.clearFilters();
      provider.updateSort('priceDesc');
      expect(provider.products.map((item) => item.id), ['2', '1']);
    });

    test('Todas restablece búsqueda y filtros del Market', () async {
      await provider.loadProducts();
      provider.updateSearch('teléfono');
      provider.applyFilters(
        category: 'Electrónica',
        type: 'Productos',
        location: 'Santiago',
        sort: 'priceDesc',
        minPrice: 90,
        maxPrice: 110,
      );

      provider.clearFilters();

      expect(provider.selectedCategory, 'Todas');
      expect(provider.selectedType, 'Todos');
      expect(provider.selectedLocation, 'Todas');
      expect(provider.products, hasLength(2));
    });

    test('elimina una publicación de la fuente y de la lista', () async {
      await provider.loadProducts();
      await provider.deleteProduct('1');

      expect(products.deletedIds, ['1']);
      expect(provider.allProducts.map((item) => item.id), ['2']);
    });

    test('marca favorito y actualiza el contador', () async {
      await provider.loadProducts();
      provider.setUser('user-1');
      await pumpEventQueue();
      favorites.nextCount = 8;

      await provider.toggleFavorite(provider.allProducts.first);

      expect(provider.isFavorite(provider.allProducts.first), isTrue);
      expect(provider.allProducts.first.favorites, 8);
      expect(favorites.lastAdd, isTrue);
    });

    test('revierte el favorito si el guardado remoto falla', () async {
      await provider.loadProducts();
      provider.setUser('user-1');
      await pumpEventQueue();
      favorites.failToggle = true;

      await provider.toggleFavorite(provider.allProducts.first);

      expect(provider.isFavorite(provider.allProducts.first), isFalse);
    });
  });
}

ProductModel product({
  required String id,
  required String title,
  required double price,
}) {
  final now = DateTime(2026, 8, 27);
  return ProductModel(
    id: id,
    title: title,
    description: 'Descripción de $title',
    price: price,
    category: 'Electrónica',
    city: 'Santiago',
    country: 'Chile',
    createdAt: now,
    updatedAt: now,
  );
}

class FakeProductRepository implements ProductRepository {
  FakeProductRepository(this.items);

  final List<ProductModel> items;
  final List<String> deletedIds = [];

  @override
  Future<void> createProduct(ProductModel product) async => items.add(product);

  @override
  Future<void> deleteProduct(String id) async {
    deletedIds.add(id);
    items.removeWhere((item) => item.id == id);
  }

  @override
  Future<List<ProductModel>> getProducts() async => List.of(items);

  @override
  Stream<List<ProductModel>> getProductsStream() => Stream.value(items);

  @override
  Future<int> incrementViews(String productId) async {
    final product = items.firstWhere((item) => item.id == productId);
    return product.views;
  }

  @override
  Future<void> updateProduct(ProductModel product) async {
    final index = items.indexWhere((item) => item.id == product.id);
    if (index >= 0) items[index] = product;
  }
}

class FakeFavoriteRepository implements FavoriteRepository {
  bool failToggle = false;
  bool? lastAdd;
  int nextCount = 1;
  Set<String> initialIds = {};

  @override
  Future<Set<String>> getFavoriteIds(String uid) async => initialIds;

  @override
  Future<int> toggleFavorite({
    required String uid,
    required String productId,
    required bool add,
  }) async {
    lastAdd = add;
    if (failToggle) throw StateError('Firebase no disponible');
    return nextCount;
  }
}
