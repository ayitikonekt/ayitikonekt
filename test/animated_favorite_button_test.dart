import 'package:ayitikonekt_app/shared/widgets/animated_favorite_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('cambia inmediatamente a corazón rojo al seleccionarlo', (
    tester,
  ) async {
    var presses = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AnimatedFavoriteButton(
            isFavorite: false,
            onPressed: () => presses++,
          ),
        ),
      ),
    );

    await tester.tap(find.byType(AnimatedFavoriteButton));
    await tester.pump();

    final icon = tester.widget<Icon>(find.byIcon(Icons.favorite));
    expect(icon.color, const Color(0xFFE31B23));

    await tester.pump(const Duration(milliseconds: 180));
    expect(presses, 1);
  });
}
