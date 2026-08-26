import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  User? _user;

  User? get user => _user;

  bool get isLoggedIn => _user != null;

  AuthProvider() {
    _authService.authStateChanges.listen((user) {
      _user = user;
      notifyListeners();
    });
  }

  Future<void> login({required String email, required String password}) async {
    final credential = await _authService.login(
      email: email,
      password: password,
    );
    _user = credential.user;
    notifyListeners();
  }

  Future<void> register({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String country,
    required String language,
  }) async {
    await _authService.register(
      email: email,
      password: password,
      name: name,
      phone: phone,
      country: country,
      language: language,
    );
  }

  Future<void> requestPhoneCode({
    required String phoneNumber,
    required void Function(String verificationId) onCodeSent,
    required void Function(String message) onError,
  }) => _authService.requestPhoneCode(
    phoneNumber: phoneNumber,
    onCodeSent: onCodeSent,
    onError: onError,
  );

  Future<void> signInWithPhoneCode({
    required String verificationId,
    required String smsCode,
    String name = '',
    String country = 'Chile',
    String language = 'Español',
  }) async {
    await _authService.signInWithPhoneCode(
      verificationId: verificationId,
      smsCode: smsCode,
      name: name,
      country: country,
      language: language,
    );
    _user = _authService.currentUser;
    notifyListeners();
  }

  Future<void> logout() async {
    await _authService.logout();
    _user = null;
    notifyListeners();
  }

  Future<void> resetPassword(String email) async {
    await _authService.sendPasswordResetEmail(email);
  }
}
