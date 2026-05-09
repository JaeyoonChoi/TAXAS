import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:taxas/main.dart';

void main() {
  testWidgets('TaxasApp builds without throwing', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: TaxasApp()),
    );
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
