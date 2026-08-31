import 'dart:convert';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class BackendFunctionsService {
  static const _projectId = 'ayitikonekt';
  static const _region = 'us-central1';
  static const _useEmulators = bool.fromEnvironment(
    'USE_FIREBASE_EMULATORS',
    defaultValue: false,
  );

  Future<Map<String, dynamic>> call(
    String functionName,
    Map<String, dynamic> payload,
  ) async {
    if (defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux) {
      return _callOverHttp(functionName, payload);
    }

    final result = await FirebaseFunctions.instance
        .httpsCallable(functionName)
        .call(payload);
    return Map<String, dynamic>.from(result.data as Map);
  }

  Future<Map<String, dynamic>> _callOverHttp(
    String functionName,
    Map<String, dynamic> payload,
  ) async {
    final token = await FirebaseAuth.instance.currentUser?.getIdToken();
    if (token == null || token.isEmpty) {
      throw StateError('Authentication required.');
    }

    const configuredHost = String.fromEnvironment('FIREBASE_EMULATOR_HOST');
    final useLocal = kDebugMode && _useEmulators;
    final uri = useLocal
        ? Uri.parse(
            'http://${configuredHost.isEmpty ? '127.0.0.1' : configuredHost}:5001/'
            '$_projectId/$_region/$functionName',
          )
        : Uri.parse(
            'https://$_region-$_projectId.cloudfunctions.net/$functionName',
          );

    final response = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'data': payload}),
    );
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final error = decoded['error'];
    if (response.statusCode < 200 || response.statusCode >= 300 || error != null) {
      final message = error is Map
          ? error['message']?.toString()
          : 'Backend request failed (${response.statusCode}).';
      throw StateError(message ?? 'Backend request failed.');
    }

    final data = decoded['data'] ?? decoded['result'];
    return Map<String, dynamic>.from(data as Map);
  }
}
