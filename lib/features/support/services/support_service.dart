import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

import '../../marketplace/services/storage_service.dart';
import '../models/support_ticket.dart';

class SupportService {
  final FirebaseFirestore _firestore;
  final StorageService _storageService;

  SupportService({FirebaseFirestore? firestore, StorageService? storageService})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _storageService = storageService ?? StorageService();

  Stream<List<SupportTicket>> ticketsFor(String userId) => _firestore
      .collection('supportTickets')
      .where('userId', isEqualTo: userId)
      .snapshots()
      .map((snapshot) {
        final tickets = snapshot.docs.map(SupportTicket.fromDocument).toList();
        tickets.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return tickets;
      });

  Future<String> createTicket({
    required String userId,
    required String category,
    required String subject,
    required String description,
    required String contact,
    required List<XFile> attachments,
  }) async {
    final reference = _firestore.collection('supportTickets').doc();
    final urls = <String>[];
    for (final attachment in attachments.take(3)) {
      urls.add(
        await _storageService.uploadSupportAttachment(
          file: attachment,
          userId: userId,
          ticketId: reference.id,
        ),
      );
    }
    await reference.set({
      'userId': userId,
      'category': category,
      'subject': subject.trim(),
      'description': description.trim(),
      'contact': contact.trim(),
      'attachments': urls,
      'status': 'received',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return reference.id;
  }
}
