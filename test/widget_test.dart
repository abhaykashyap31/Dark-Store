import 'package:darkstore/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App boots into splash or login', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: DarkstoreApp(),
      ),
    );

    await tester.pump();
    expect(find.byType(MaterialApp), findsOneWidget);

    // Allow splash → login transition if session restore completes quickly.
    await tester.pump(const Duration(milliseconds: 100));
    expect(
      find.textContaining('DarkStore').evaluate().isNotEmpty ||
          find.text('Login').evaluate().isNotEmpty ||
          find.text('Restoring session…').evaluate().isNotEmpty,
      isTrue,
    );
  });
}
