import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/firebase/backend_functions_service.dart';
import '../../marketplace/services/storage_service.dart';
import '../models/support_ticket.dart';

class SupportService {
  final FirebaseFirestore _firestore;
  final StorageService _storageService;
  final BackendFunctionsService _backendFunctions;

  SupportService({
    FirebaseFirestore? firestore,
    StorageService? storageService,
    BackendFunctionsService? backendFunctions,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _storageService = storageService ?? StorageService(),
       _backendFunctions = backendFunctions ?? BackendFunctionsService();

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
    final ticketId = _firestore.collection('supportTickets').doc().id;
    final attachmentPaths = <String>[];
    for (final attachment in attachments.take(3)) {
      attachmentPaths.add(
        await _storageService.uploadSupportAttachment(
          file: attachment,
          userId: userId,
          ticketId: ticketId,
        ),
      );
    }
    final result = await _backendFunctions.call('createSupportTicket', {
      'ticketId': ticketId,
      'category': category,
      'subject': subject.trim(),
      'description': description.trim(),
      'contact': contact.trim(),
      'attachmentPaths': attachmentPaths,
    });
    return result['ticketId']?.toString() ?? ticketId;
  }
}
