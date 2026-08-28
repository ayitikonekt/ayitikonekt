import 'package:flutter/material.dart';

import '../models/product_model.dart';
import '../services/favorite_service.dart';
import '../services/product_service.dart';

class MarketplaceProvider extends ChangeNotifier {
  final ProductRepository _service;
  final FavoriteRepository _favoriteService;

  MarketplaceProvider({
    ProductRepository? productService,
    FavoriteRepository? favoriteService,
  }) : _service = productService ?? ProductService(),
       _favoriteService = favoriteService ?? FavoriteService();

  List<ProductModel> _products = [];

  bool _loading = false;
  String? _errorMessage;

  String _search = "";
  String _category = "Todas";
  String _sort = "default";
  String _type = "Todos";
  String _location = "Todas";
  double? _minPrice;
  double? _maxPrice;

  final Set<String> _favoriteIds = <String>{};
  String? _userId;

  List<ProductModel> get products => _filteredProducts;

  List<ProductModel> get allProducts => List.unmodifiable(_products);

  List<ProductModel> get featuredProducts =>
      _products.where((p) => p.isFeatured).toList();

  List<ProductModel> get soldProducts =>
      _products.where((p) => p.isSold).toList();

  List<ProductModel> get favorites =>
      _products.where((p) => _favoriteIds.contains(p.id)).toList();

  bool get loading => _loading;

  String? get errorMessage => _errorMessage;

  String get selectedCategory => _category;
  String get selectedSort => _sort;
  String get selectedType => _type;
  String get selectedLocation => _location;
  double? get minPrice => _minPrice;
  double? get maxPrice => _maxPrice;

  bool isFavorite(ProductModel product) => _favoriteIds.contains(product.id);

  Future<void> loadProducts() async {
    if (_loading) return;

    _loading = true;
    _errorMessage = null;

    notifyListeners();

    try {
      _products = await _service.getProducts();
    } catch (_) {
      _errorMessage =
          "No se pudieron cargar los productos. Inténtalo nuevamente.";
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    await loadProducts();
  }

  Future<void> createProduct(ProductModel product) async {
    await _service.createProduct(product);
    await loadProducts();
  }

  Future<void> updateProduct(ProductModel product) async {
    await _service.updateProduct(product);
    await loadProducts();
  }

  Future<void> deleteProduct(String id) async {
    await _service.deleteProduct(id);

    _products.removeWhere((p) => p.id == id);

    notifyListeners();
  }

  Future<void> recordView(ProductModel product) async {
    final index = _products.indexWhere((item) => item.id == product.id);
    if (index >= 0) {
      _products[index] = _products[index].copyWith(
        views: _products[index].views + 1,
      );
      notifyListeners();
    }

    try {
      await _service.incrementViews(product.id);
    } catch (_) {
      // Revertimos el cambio visual si Firebase rechaza la operación.
      final currentIndex = _products.indexWhere(
        (item) => item.id == product.id,
      );
      if (currentIndex >= 0 && _products[currentIndex].views > 0) {
        _products[currentIndex] = _products[currentIndex].copyWith(
          views: _products[currentIndex].views - 1,
        );
        notifyListeners();
      }
    }
  }

  void updateSearch(String value) {
    _search = value;
    notifyListeners();
  }

  void updateCategory(String value) {
    _category = value;
    notifyListeners();
  }

  void updateSort(String value) {
    _sort = value;
    notifyListeners();
  }

  void applyFilters({
    required String category,
    required String type,
    required String location,
    required String sort,
    double? minPrice,
    double? maxPrice,
  }) {
    _category = category;
    _type = type;
    _location = location;
    _sort = sort;
    _minPrice = minPrice;
    _maxPrice = maxPrice;
    notifyListeners();
  }

  void clearFilters() {
    _search = "";
    _category = "Todas";
    _sort = "default";
    _type = "Todos";
    _location = "Todas";
    _minPrice = null;
    _maxPrice = null;

    notifyListeners();
  }

  void setUser(String? uid) {
    if (_userId == uid) return;

    _userId = uid;
    _favoriteIds.clear();
    notifyListeners();

    if (uid == null) return;

    _loadFavorites(uid);
  }

  Future<void> _loadFavorites(String uid) async {
    try {
      final favorites = await _favoriteService.getFavoriteIds(uid);
      if (_userId != uid) return;
      _favoriteIds.addAll(favorites);
      notifyListeners();
    } catch (_) {
      // Si no se pueden cargar, la cuenta sigue funcionando sin favoritos.
    }
  }

  Future<void> toggleFavorite(ProductModel product) async {
    final uid = _userId;
    if (uid == null) return;

    final wasFavorite = _favoriteIds.contains(product.id);
    if (wasFavorite) {
      _favoriteIds.remove(product.id);
    } else {
      _favoriteIds.add(product.id);
    }
    notifyListeners();

    try {
      final favoriteCount = await _favoriteService.toggleFavorite(
        uid: uid,
        productId: product.id,
        add: !wasFavorite,
      );
      if (_userId != uid) return;
      _products = _products
          .map(
            (item) => item.id == product.id
                ? item.copyWith(favorites: favoriteCount)
                : item,
          )
          .toList();
      notifyListeners();
    } catch (_) {
      if (_userId != uid) return;
      if (wasFavorite) {
        _favoriteIds.add(product.id);
      } else {
        _favoriteIds.remove(product.id);
      }
      notifyListeners();
    }
  }

  List<ProductModel> get _filteredProducts {
    List<ProductModel> list = List.from(_products);

    if (_search.isNotEmpty) {
      final query = _search.trim().toLowerCase();
      list = list
          .where(
            (product) =>
                product.title.toLowerCase().contains(query) ||
                product.description.toLowerCase().contains(query) ||
                product.category.toLowerCase().contains(query) ||
                product.city.toLowerCase().contains(query) ||
                product.country.toLowerCase().contains(query),
          )
          .toList();
    }

    if (_category != "Todas") {
      list = list.where((product) => product.category == _category).toList();
    }

    if (_type == "Productos") {
      list = list.where((product) => product.category != "Servicios").toList();
    } else if (_type == "Servicios") {
      list = list.where((product) => product.category == "Servicios").toList();
    }

    if (_minPrice != null) {
      list = list.where((product) => product.price >= _minPrice!).toList();
    }
    if (_maxPrice != null) {
      list = list.where((product) => product.price <= _maxPrice!).toList();
    }

    if (_location != "Todas") {
      list = list.where((product) => product.city == _location).toList();
    }

    switch (_sort) {
      case "priceAsc":
        list.sort((a, b) => a.price.compareTo(b.price));
        break;

      case "priceDesc":
        list.sort((a, b) => b.price.compareTo(a.price));
        break;

      case "newest":
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;

      case "oldest":
        list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
    }

    return list;
  }
}
