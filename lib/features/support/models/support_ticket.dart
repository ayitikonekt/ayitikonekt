import 'package:cloud_firestore/cloud_firestore.dart';

class SupportTicket {
  final String id;
  final String category;
  final String subject;
  final String description;
  final String contact;
  final String status;
  final List<String> attachments;
  final DateTime createdAt;

  const SupportTicket({
    required this.id,
    required this.category,
    required this.subject,
    required this.description,
    required this.contact,
    required this.status,
    required this.attachments,
    required this.createdAt,
  });

  factory SupportTicket.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? const <String, dynamic>{};
    final rawDate = data['createdAt'];
    return SupportTicket(
      id: document.id,
      category: data['category']?.toString() ?? '',
      subject: data['subject']?.toString() ?? '',
      description: data['description']?.toString() ?? '',
      contact: data['contact']?.toString() ?? '',
      status: data['status']?.toString() ?? 'received',
      attachments: List<String>.from(data['attachments'] ?? const <String>[]),
      createdAt: rawDate is Timestamp ? rawDate.toDate() : DateTime.now(),
    );
  }
}
