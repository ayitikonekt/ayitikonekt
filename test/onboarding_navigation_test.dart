import 'package:ayitikonekt_app/features/splash/presentation/country_selection_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('permite volver de idioma para corregir el país', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(locale: Locale('es'), home: CountrySelectionScreen()),
    );

    await tester.tap(find.text('Chile'));
    await tester.pump();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Continuar'));
    await tester.pumpAndSettle();

    expect(find.text('Chwazi lang ou /\nElige tu idioma'), findsOneWidget);
    expect(find.text('Volver'), findsOneWidget);

    await tester.tap(find.text('Volver'));
    await tester.pumpAndSettle();

    expect(find.text('Selecciona tu país de residencia'), findsOneWidget);
    expect(find.text('Chile'), findsOneWidget);
  });
}
