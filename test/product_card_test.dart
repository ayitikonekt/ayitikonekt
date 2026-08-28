import 'package:ayitikonekt_app/shared/widgets/product_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('no desborda con un título de dos líneas en iPhone', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 186,
            height: 370,
            child: ProductCard(
              title: 'Teléfono prueba edición',
              price: 100000,
              location: 'Santiago centro estado de norte, Chile',
              category: 'Electrónica',
              imagePath: '',
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Teléfono prueba edición'), findsOneWidget);
    expect(find.text('Electrónica'), findsOneWidget);
  });
}
