import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/product_model.dart';

class ProductService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Crear producto
  Future<void> createProduct(ProductModel product) async {
    await _firestore
        .collection('products')
        .doc(product.id)
        .set(product.toMap());
  }

  /// Obtener productos (consulta única)
  Future<List<ProductModel>> getProducts() async {
    final snapshot = await _firestore
        .collection('products')
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => ProductModel.fromMap(doc.data()))
        .toList();
  }

  /// Obtener productos en tiempo real
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
  Future<void> updateProduct(ProductModel product) async {
    await _firestore
        .collection('products')
        .doc(product.id)
        .update(product.toMap());
  }

  /// Incrementa de forma atómica para no perder vistas simultáneas.
  Future<void> incrementViews(String productId) async {
    await _firestore.collection('products').doc(productId).update({
      'views': FieldValue.increment(1),
    });
  }

  /// Eliminar producto
  Future<void> deleteProduct(String id) async {
    await _firestore
        .collection('products')
        .doc(id)
        .delete();
  }
}
