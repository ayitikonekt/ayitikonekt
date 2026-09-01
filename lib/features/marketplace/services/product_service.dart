import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/firebase/backend_functions_service.dart';
import '../models/product_model.dart';

abstract interface class ProductRepository {
  Future<void> createProduct(ProductModel product);
  Future<List<ProductModel>> getProducts();
  Stream<List<ProductModel>> getProductsStream();
  Future<void> updateProduct(ProductModel product);
  Future<int> incrementViews(String productId);
  Future<void> deleteProduct(String id);
}

class ProductService implements ProductRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final BackendFunctionsService _functions = BackendFunctionsService();

  /// Crear producto
  @override
  Future<void> createProduct(ProductModel product) async {
    final data = product.toMap()
      ..['createdAt'] = FieldValue.serverTimestamp()
      ..['updatedAt'] = FieldValue.serverTimestamp();
    await _firestore
        .collection('products')
        .doc(product.id)
        .set(data);
  }

  /// Obtener productos (consulta única)
  @override
  Future<List<ProductModel>> getProducts() async {
    final snapshot = await _firestore
        .collection('products')
        .orderBy('createdAt', descending: true)
        // El catálogo debe reflejar el estado real del servidor. Evitamos que
        // macOS, Windows o iOS muestren publicaciones antiguas conservadas en
        // sus cachés locales.
        .get(const GetOptions(source: Source.server));

    return snapshot.docs
        .map((doc) => ProductModel.fromMap(doc.data()))
        .toList();
  }

  /// Obtener productos en tiempo real
  @override
  Stream<List<ProductModel>> getProductsStream() {
    return _firestore
        .collection('products')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ProductModel.fromMap(doc.data()))
              .toList(),
        );
  }

  /// Actualizar producto
  @override
  Future<void> updateProduct(ProductModel product) async {
    final data = product.toMap()
      ..['updatedAt'] = FieldValue.serverTimestamp();
    await _firestore
        .collection('products')
        .doc(product.id)
        .update(data);
  }

  /// Incrementa de forma atómica para no perder vistas simultáneas.
  @override
  Future<int> incrementViews(String productId) async {
    final data = await _functions.call('recordProductView', {
      'productId': productId,
    });
    return (data['viewCount'] as num).toInt();
  }

  /// Eliminar producto
  @override
  Future<void> deleteProduct(String id) async {
    await _firestore.collection('products').doc(id).delete();
  }
}
