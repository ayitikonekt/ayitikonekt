import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  ({String mime, String extension})? _detectImageType(List<int> bytes) {
    if (bytes.length >= 3 &&
        bytes[0] == 0xff &&
        bytes[1] == 0xd8 &&
        bytes[2] == 0xff) {
      return (mime: 'image/jpeg', extension: 'jpg');
    }
    const png = [0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a];
    if (bytes.length >= png.length &&
        List.generate(png.length, (index) => bytes[index]).join(',') ==
            png.join(',')) {
      return (mime: 'image/png', extension: 'png');
    }
    if (bytes.length >= 12 &&
        bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x46 &&
        bytes[8] == 0x57 &&
        bytes[9] == 0x45 &&
        bytes[10] == 0x42 &&
        bytes[11] == 0x50) {
      return (mime: 'image/webp', extension: 'webp');
    }
    if (bytes.length >= 12 &&
        bytes[4] == 0x66 &&
        bytes[5] == 0x74 &&
        bytes[6] == 0x79 &&
        bytes[7] == 0x70) {
      final brand = String.fromCharCodes(bytes.sublist(8, 12));
      if (const ['heic', 'heix', 'hevc', 'hevx'].contains(brand)) {
        return (mime: 'image/heic', extension: 'heic');
      }
      if (const ['mif1', 'msf1'].contains(brand)) {
        return (mime: 'image/heif', extension: 'heif');
      }
    }
    return null;
  }

  Future<String> uploadProductImage({
    required XFile file,
    required String productId,
    required String ownerId,
  }) async {
    final bytes = await file.readAsBytes();
    if (bytes.isEmpty || bytes.length > 8 * 1024 * 1024) {
      throw const FormatException('La imagen debe pesar entre 1 byte y 8 MB.');
    }
    final imageType = _detectImageType(bytes);
    if (imageType == null) {
      throw const FormatException(
        'El archivo seleccionado no es una imagen válida.',
      );
    }
    final fileName =
        '${DateTime.now().microsecondsSinceEpoch}.${imageType.extension}';

    final ref = _storage
        .ref()
        .child('products')
        .child(ownerId)
        .child(productId)
        .child(fileName);

    final snapshot = await ref.putData(
      bytes,
      SettableMetadata(contentType: imageType.mime),
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
    // El backend recibe la ruta, verifica propietario, tipo y tamaÃ±o, y solo
    // entonces la asocia al ticket. No se confÃ­a en una URL enviada al cliente.
    return snapshot.ref.fullPath;
  }

  Future<void> deleteImage(String imageUrl) async {
    try {
      await _storage.refFromURL(imageUrl).delete();
    } catch (_) {
      // Ignorar si la imagen ya no existe.
    }
  }
}
