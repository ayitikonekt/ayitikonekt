import 'package:ayitikonekt_app/features/auth/presentation/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

Widget loginApp() => const MaterialApp(
  locale: Locale('es'),
  supportedLocales: [Locale('es')],
  localizationsDelegates: [
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  home: LoginScreen(),
);

void main() {
  testWidgets('valida correo y contraseña antes de llamar a Firebase', (
    tester,
  ) async {
    await tester.pumpWidget(loginApp());

    await tester.tap(find.widgetWithText(ElevatedButton, 'Iniciar sesión'));
    await tester.pump();

    expect(find.text('Ingrese un correo válido'), findsOneWidget);
    expect(find.text('Ingresa tu contraseña'), findsOneWidget);
  });

  testWidgets('exige formato internacional para iniciar con teléfono', (
    tester,
  ) async {
    await tester.pumpWidget(loginApp());

    await tester.tap(find.text('Teléfono'));
    await tester.pump();
    await tester.enterText(find.byType(TextFormField), '912345678');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Enviar código SMS'));
    await tester.pump();

    expect(
      find.text('Use el formato internacional, por ejemplo +56912345678'),
      findsOneWidget,
    );
  });
}
