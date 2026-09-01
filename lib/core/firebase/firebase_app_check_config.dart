import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';

const _webRecaptchaSiteKey = String.fromEnvironment(
  'APP_CHECK_WEB_RECAPTCHA_SITE_KEY',
);
const _windowsDebugToken = String.fromEnvironment(
  'APP_CHECK_DEBUG_TOKEN',
);

bool _appCheckActivated = false;

bool get isFirebaseAppCheckActivated => _appCheckActivated;

Future<void> activateFirebaseAppCheck() async {
  if (kIsWeb) {
    if (!kDebugMode && _webRecaptchaSiteKey.isEmpty) {
      debugPrint('App Check supervision skipped: missing web reCAPTCHA site key.');
      return;
    }
    await FirebaseAppCheck.instance.activate(
      providerWeb: kDebugMode
          ? WebDebugProvider()
          : ReCaptchaV3Provider(_webRecaptchaSiteKey),
    );
    _appCheckActivated = true;
    return;
  }

  if (defaultTargetPlatform == TargetPlatform.windows) {
    if (_windowsDebugToken.isEmpty) {
      debugPrint('App Check supervision skipped on Windows: missing debug token.');
      return;
    }
    await FirebaseAppCheck.instance.activate(
      providerWindows: WindowsDebugProvider(debugToken: _windowsDebugToken),
    );
    _appCheckActivated = true;
    return;
  }

  if (defaultTargetPlatform == TargetPlatform.android) {
    await FirebaseAppCheck.instance.activate(
      providerAndroid: kDebugMode
          ? const AndroidDebugProvider()
          : const AndroidPlayIntegrityProvider(),
    );
    _appCheckActivated = true;
    return;
  }

  if (defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.macOS) {
    await FirebaseAppCheck.instance.activate(
      providerApple: kDebugMode
          ? const AppleDebugProvider()
          : const AppleAppAttestWithDeviceCheckFallbackProvider(),
    );
    _appCheckActivated = true;
  }
}
