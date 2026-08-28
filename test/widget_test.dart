import 'package:ayitikonekt_app/shared/widgets/app_search_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('El buscador transmite el texto escrito', (tester) async {
    String? search;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppSearchBar(onChanged: (value) => search = value),
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), 'vivienda');
    expect(search, 'vivienda');
  });
}
