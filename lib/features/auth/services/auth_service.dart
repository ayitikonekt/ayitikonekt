import 'package:firebase_auth/firebase_auth.dart';

import '../data/user_model.dart';
import 'user_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final UserService _userService = UserService();

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserCredential> register({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String country,
    required String language,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final firebaseUser = credential.user!;

    final user = UserModel(
      uid: firebaseUser.uid,
      email: firebaseUser.email ?? "",
      name: name,
      lastName: "",
      phone: phone,
      country: country,
      city: "",
      language: language,
      photo: "",
      verified: false,
      reputation: 5,
      createdAt: DateTime.now(),
    );

    await _userService.createUser(user);

    return credential;
  }

  Future<void> requestPhoneCode({
    required String phoneNumber,
    required void Function(String verificationId) onCodeSent,
    required void Function(String message) onError,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (_) {},
      verificationFailed: (error) => onError(error.message ?? error.code),
      codeSent: (verificationId, _) => onCodeSent(verificationId),
      codeAutoRetrievalTimeout: (_) {},
    );
  }

  Future<void> signInWithPhoneCode({
    required String verificationId,
    required String smsCode,
    String name = '',
    String country = 'Chile',
    String language = 'Español',
  }) async {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    final result = await _auth.signInWithCredential(credential);
    final firebaseUser = result.user;
    if (firebaseUser == null) return;

    final existingUser = await _userService.getUser(firebaseUser.uid);
    if (existingUser != null) return;

    await _userService.createUser(
      UserModel(
        uid: firebaseUser.uid,
        email: firebaseUser.email ?? '',
        name: name,
        lastName: '',
        phone: firebaseUser.phoneNumber ?? '',
        country: country,
        city: '',
        language: language,
        photo: '',
        verified: firebaseUser.phoneNumber != null,
        reputation: 5,
        createdAt: DateTime.now(),
      ),
    );
  }

  Future<UserCredential> login({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }
}
