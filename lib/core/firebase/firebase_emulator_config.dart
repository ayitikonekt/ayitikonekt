import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

const _useFirebaseEmulators = bool.fromEnvironment(
  'USE_FIREBASE_EMULATORS',
  defaultValue: false,
);

Future<void> connectToFirebaseEmulators() async {
  if (!kDebugMode || !_useFirebaseEmulators) {
    await _validateProductionAuthSession();
    return;
  }

  const configuredHost = String.fromEnvironment('FIREBASE_EMULATOR_HOST');
  final host = configuredHost.isNotEmpty
      ? configuredHost
      : defaultTargetPlatform == TargetPlatform.android
      ? '10.0.2.2'
      : '127.0.0.1';

  // Evita mezclar la caché de producción con la base local de pruebas.
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: false,
  );

  await FirebaseAuth.instance.useAuthEmulator(host, 9099);
  await _clearStaleEmulatorSession();
  FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);
  if (defaultTargetPlatform != TargetPlatform.windows &&
      defaultTargetPlatform != TargetPlatform.linux) {
    FirebaseFunctions.instance.useFunctionsEmulator(host, 5001);
  }
  await FirebaseStorage.instance.useStorageEmulator(host, 9199);
}

Future<void> _validateProductionAuthSession() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  try {
    // Fuerza a Firebase real a validar la sesión persistida. Una sesión
    // creada por Auth Emulator no es válida en el proyecto de producción.
    await user.getIdToken(true);
  } catch (error) {
    debugPrint('Descartando sesión incompatible con producción: $error');
    await FirebaseAuth.instance.signOut();
  }
}

Future<void> _clearStaleEmulatorSession() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  try {
    await user.reload();
  } catch (error) {
    // Al cambiar de Firebase real al emulador, Windows puede conservar una
    // sesión que el emulador no conoce. FlutterFire suele informarlo como
    // `unknown`, por lo que no conviene impedir que la aplicación arranque.
    debugPrint('Descartando sesión anterior del emulador: $error');
    try {
      await FirebaseAuth.instance.signOut();
    } catch (signOutError) {
      debugPrint('No se pudo limpiar la sesión local: $signOutError');
    }
  }
}
