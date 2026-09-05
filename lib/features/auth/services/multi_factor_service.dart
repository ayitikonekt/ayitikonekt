import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class MultiFactorService {
  MultiFactorService({FirebaseAuth? auth})
    : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  static bool get isSupportedMobilePlatform =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  Future<String?> administrativeRole({bool forceRefresh = false}) async {
    final user = _auth.currentUser;
    if (user == null) return null;
    Map<String, dynamic> claims = const {};
    try {
      claims = (await user.getIdTokenResult(forceRefresh)).claims ?? const {};
    } on FirebaseAuthException {
      // Algunas versiones del complemento nativo de Windows no construyen
      // IdTokenResult correctamente. La autorización real permanece en las
      // reglas y Functions; este fallback solo decide si se muestra la UI.
    }
    if (!_hasAdministrativeClaim(claims)) {
      final token = await user.getIdToken(forceRefresh);
      if (token != null) claims = _decodeClaims(token);
    }
    if (claims['admin'] == true) return 'admin';
    if (claims['moderator'] == true) return 'moderator';
    if (claims['support'] == true) return 'support';
    return null;
  }

  bool _hasAdministrativeClaim(Map<String, dynamic> claims) =>
      claims['admin'] == true ||
      claims['moderator'] == true ||
      claims['support'] == true;

  Map<String, dynamic> _decodeClaims(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return const {};
      final payload = utf8.decode(
        base64Url.decode(base64Url.normalize(parts[1])),
      );
      final decoded = jsonDecode(payload);
      return decoded is Map<String, dynamic> ? decoded : const {};
    } on FormatException {
      return const {};
    }
  }

  Future<List<MultiFactorInfo>> enrolledFactors() async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('Authentication required.');
    return user.multiFactor.getEnrolledFactors();
  }

  Future<void> startEnrollment({
    required String phoneNumber,
    required PhoneVerificationCompleted verificationCompleted,
    required PhoneVerificationFailed verificationFailed,
    required PhoneCodeSent codeSent,
    required PhoneCodeAutoRetrievalTimeout codeAutoRetrievalTimeout,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('Authentication required.');
    final session = await user.multiFactor.getSession();
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      multiFactorSession: session,
      verificationCompleted: verificationCompleted,
      verificationFailed: verificationFailed,
      codeSent: codeSent,
      codeAutoRetrievalTimeout: codeAutoRetrievalTimeout,
    );
  }

  Future<void> finishEnrollment({
    required String verificationId,
    required String smsCode,
  }) async {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    await finishEnrollmentWithCredential(credential);
  }

  Future<void> finishEnrollmentWithCredential(
    PhoneAuthCredential credential,
  ) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('Authentication required.');
    await user.multiFactor.enroll(
      PhoneMultiFactorGenerator.getAssertion(credential),
      displayName: 'AyitiKonekt administrative phone',
    );
  }

  Future<void> startSignInChallenge({
    required MultiFactorResolver resolver,
    required PhoneMultiFactorInfo factor,
    required PhoneVerificationCompleted verificationCompleted,
    required PhoneVerificationFailed verificationFailed,
    required PhoneCodeSent codeSent,
    required PhoneCodeAutoRetrievalTimeout codeAutoRetrievalTimeout,
  }) => _auth.verifyPhoneNumber(
    multiFactorSession: resolver.session,
    multiFactorInfo: factor,
    verificationCompleted: verificationCompleted,
    verificationFailed: verificationFailed,
    codeSent: codeSent,
    codeAutoRetrievalTimeout: codeAutoRetrievalTimeout,
  );

  Future<UserCredential> finishSignInChallenge({
    required MultiFactorResolver resolver,
    required String verificationId,
    required String smsCode,
  }) {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    return finishSignInChallengeWithCredential(
      resolver: resolver,
      credential: credential,
    );
  }

  Future<UserCredential> finishSignInChallengeWithCredential({
    required MultiFactorResolver resolver,
    required PhoneAuthCredential credential,
  }) => resolver.resolveSignIn(
    PhoneMultiFactorGenerator.getAssertion(credential),
  );
}
