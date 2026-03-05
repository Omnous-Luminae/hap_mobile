import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Hello World smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('Hello World'),
          ),
        ),
      ),
    );

    expect(find.text('Hello World'), findsOneWidget);
  });
}
