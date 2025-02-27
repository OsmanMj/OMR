import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quiztara/main.dart';

void main() {
  testWidgets('OMR Grading App navigation test', (WidgetTester tester) async {
    // Build the app and trigger a frame.
    await tester.pumpWidget(OMRGradingApp());

    // Verify that the Login page is displayed.
    expect(find.text('Login'), findsOneWidget);

    // Fill in the email and password fields and tap the Login button.
    await tester.enterText(find.byType(TextField).at(0), 'test@example.com');
    await tester.enterText(find.byType(TextField).at(1), 'password');
    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle();

    // Verify that the Create Test page is displayed after logging in.
    expect(find.text('Create Test'), findsOneWidget);

    // Fill in the test details and create a test.
    await tester.enterText(find.byType(TextField).at(0), 'Math Test');
    await tester.enterText(find.byType(TextField).at(1), '2024-12-01');
    await tester.enterText(find.byType(TextField).at(2), '10');
    await tester.tap(find.text('Create Test'));
    await tester.pumpAndSettle();

    // Verify that the Test Details page is displayed and shows the created test.
    expect(find.text('Test Details'), findsOneWidget);
    expect(find.text('Math Test'), findsOneWidget);

    // Tap on the test card to open the Answer Key page.
    await tester.tap(find.text('Math Test'));
    await tester.pumpAndSettle();

    // Verify that the Answer Key page is displayed.
    expect(find.text('Answer Key'), findsOneWidget);

    // Set answers for the test and save.
    for (int i = 0; i < 10; i++) {
      await tester.tap(find
          .byType(ChoiceChip)
          .at(i * 4)); // Select option A for each question.
    }
    await tester.tap(find.byIcon(Icons.save));
    await tester.pumpAndSettle();

    // Verify that the grading page can be opened.
    await tester
        .longPress(find.text('Math Test')); // Long press to start grading.
    await tester.pumpAndSettle();

    // Verify that the Grading Page is displayed.
    expect(find.text('Grading Page'), findsOneWidget);
  });
}
