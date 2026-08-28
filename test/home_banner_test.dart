import 'package:ayitikonekt_app/shared/widgets/home_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('el encabezado compacto cabe en el ancho de un iPhone', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('es'),
        home: Scaffold(
          body: SizedBox(
            width: 430,
            height: 118,
            child: HomeBanner(country: 'Chile'),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.textContaining('Haitian community'), findsOneWidget);
  });
}
