import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/localization/app_locale_provider.dart';
import '../../../shared/widgets/app_back_button.dart';
import '../../auth/providers/auth_provider.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  CollectionReference<Map<String, dynamic>> _collection(String uid) =>
      FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('notifications');

  Future<void> _markAllRead(
    String uid,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> documents,
  ) async {
    final batch = FirebaseFirestore.instance.batch();
    for (final document in documents) {
      if (document.data()['read'] != true) {
        batch.update(document.reference, {'read': true});
      }
    }
    await batch.commit();
  }

  IconData _iconFor(String type) => switch (type) {
    'favorite' => Icons.favorite_rounded,
    'message' => Icons.chat_bubble_rounded,
    'sale' => Icons.shopping_bag_rounded,
    'verified' => Icons.verified_rounded,
    _ => Icons.notifications_rounded,
  };

  Color _colorFor(String type) => switch (type) {
    'favorite' => Colors.red,
    'message' => Colors.blue,
    'sale' => Colors.orange,
    'verified' => Colors.green,
    _ => const Color(0xFF0D47A1),
  };

  String _dateLabel(dynamic value) {
    if (value is! Timestamp) return '';
    final date = value.toDate();
    final now = DateTime.now();
    final difference = now.difference(date);
    if (difference.inMinutes < 1) return 'Ahora';
    if (difference.inHours < 1) return 'Hace ${difference.inMinutes} min';
    if (difference.inDays < 1) return 'Hace ${difference.inHours} h';
    if (difference.inDays < 7) return 'Hace ${difference.inDays} d';
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final uid = context.watch<AuthProvider>().user?.uid;

    return Scaffold(
      appBar: AppBar(
        leadingWidth: 112,
        leading: const AppBackButton(
          showWhenCannotPop: false,
          foregroundColor: Colors.white,
        ),
        backgroundColor: const Color(0xFF0646D8),
        foregroundColor: Colors.white,
        title: Text(context.tr('notifications')),
      ),
      body: uid == null
          ? const Center(child: Text('Usuario no autenticado'))
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _collection(
                uid,
              ).orderBy('createdAt', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'No se pudieron cargar las notificaciones.\n${snapshot.error}',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final documents = snapshot.data!.docs;
                if (documents.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.notifications_none_rounded,
                          size: 82,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No tienes notificaciones',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final unread = documents
                    .where((document) => document.data()['read'] != true)
                    .length;

                return Column(
                  children: [
                    if (unread > 0)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: () => _markAllRead(uid, documents),
                          icon: const Icon(Icons.done_all_rounded),
                          label: const Text('Marcar todas como leídas'),
                        ),
                      ),
                    Expanded(
                      child: ListView.separated(
                        padding: EdgeInsets.fromLTRB(
                          MediaQuery.sizeOf(context).width > 840
                              ? (MediaQuery.sizeOf(context).width - 800) / 2
                              : 16,
                          4,
                          MediaQuery.sizeOf(context).width > 840
                              ? (MediaQuery.sizeOf(context).width - 800) / 2
                              : 16,
                          20,
                        ),
                        itemCount: documents.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final document = documents[index];
                          final data = document.data();
                          final type = data['type']?.toString() ?? '';
                          final read = data['read'] == true;

                          return Card(
                            color: read
                                ? Colors.white
                                : const Color(0xFFE8F0FE),
                            child: ListTile(
                              onTap: read
                                  ? null
                                  : () => document.reference.update({
                                      'read': true,
                                    }),
                              leading: CircleAvatar(
                                backgroundColor: _colorFor(
                                  type,
                                ).withValues(alpha: .12),
                                child: Icon(
                                  _iconFor(type),
                                  color: _colorFor(type),
                                ),
                              ),
                              title: Text(
                                data['title']?.toString() ?? 'AyitiKonekt',
                                style: TextStyle(
                                  fontWeight: read
                                      ? FontWeight.w500
                                      : FontWeight.bold,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text(data['message']?.toString() ?? ''),
                                  const SizedBox(height: 5),
                                  Text(
                                    _dateLabel(data['createdAt']),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                              trailing: read
                                  ? null
                                  : const Icon(
                                      Icons.circle,
                                      size: 10,
                                      color: Color(0xFF0D47A1),
                                    ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}
