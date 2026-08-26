import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> uploadProductImage({
    required XFile file,
    required String productId,
  }) async {
    final fileName = DateTime.now().millisecondsSinceEpoch.toString();

    final ref = _storage
        .ref()
        .child('products')
        .child(productId)
        .child(fileName);

    final snapshot = await ref.putData(
      await file.readAsBytes(),
      SettableMetadata(contentType: file.mimeType ?? 'image/jpeg'),
    );

    return snapshot.ref.getDownloadURL();
  }

  Future<String> uploadProfileImage({
    required XFile file,
    required String uid,
  }) async {
    final ref = _storage
        .ref()
        .child('profile_images')
        .child(uid)
        .child('profile.jpg');

    final snapshot = await ref.putData(
      await file.readAsBytes(),
      SettableMetadata(contentType: file.mimeType ?? 'image/jpeg'),
    );

    return snapshot.ref.getDownloadURL();
  }

  Future<String> uploadSupportAttachment({
    required XFile file,
    required String userId,
    required String ticketId,
  }) async {
    final fileName = '${DateTime.now().microsecondsSinceEpoch}.jpg';
    final ref = _storage
        .ref()
        .child('support_tickets')
        .child(userId)
        .child(ticketId)
        .child(fileName);
    final snapshot = await ref.putData(
      await file.readAsBytes(),
      SettableMetadata(contentType: file.mimeType ?? 'image/jpeg'),
    );
    return snapshot.ref.getDownloadURL();
  }

  Future<void> deleteImage(String imageUrl) async {
    try {
      await _storage.refFromURL(imageUrl).delete();
    } catch (_) {
      // Ignorar si la imagen ya no existe.
    }
  }
}
