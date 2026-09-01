import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/firebase/backend_functions_service.dart';
import '../data/user_model.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final BackendFunctionsService _functions = BackendFunctionsService();
  static final Set<String> _syncedProfiles = <String>{};

  Future<void> createUser(UserModel user) async {
    await _firestore
        .collection("users")
        .doc(user.uid)
        .set(user.toMap());
  }

  Future<UserModel?> getUser(String uid) async {
    final doc = await _firestore
        .collection("users")
        .doc(uid)
        .get();

    if (!doc.exists) return null;

    if (_syncedProfiles.add(uid)) {
      try {
        await _functions.call('syncMyPublicProfile', const {});
      } catch (_) {
        _syncedProfiles.remove(uid);
      }
    }

    return UserModel.fromMap(doc.data()!);
  }

  Future<UserModel?> getPublicUser(String uid) async {
    final doc = await _firestore.collection('publicProfiles').doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromMap(doc.data()!);
  }

  Future<void> updateUser(UserModel user) async {
    await _firestore
        .collection("users")
        .doc(user.uid)
        .update(user.toMap());
  }
}
