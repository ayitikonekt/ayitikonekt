import 'features/auth/providers/auth_provider.dart';
import 'core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'core/firebase/firebase_emulator_config.dart';

import 'features/marketplace/providers/marketplace_provider.dart';
import 'features/splash/presentation/splash_screen.dart';
import 'core/localization/app_locale_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await connectToFirebaseEmulators();

  runApp(const AyitiKonektApp());
}

class AyitiKonektApp extends StatelessWidget {
  const AyitiKonektApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),

        ChangeNotifierProvider(create: (_) => MarketplaceProvider()),

        ChangeNotifierProvider(create: (_) => AppLocaleProvider()),
      ],
      child: Consumer<AppLocaleProvider>(
        builder: (context, localeProvider, _) => MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'AyitiKonekt',
          locale: localeProvider.locale,
          localizationsDelegates: const [
            HaitianMaterialLocalizationsDelegate(),
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('es'),
            Locale('en'),
            Locale('fr'),
            Locale('ht'),
            Locale('pt'),
          ],
          theme: AppTheme.lightTheme,
          home: const SplashScreen(),
        ),
      ),
    );
  }
}
