import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fake_drug_checker/main.dart';
import 'package:fake_drug_checker/models/drug_check_result.dart';
import 'package:fake_drug_checker/widgets/status_badge.dart';
import 'package:fake_drug_checker/widgets/confidence_meter.dart';
import 'package:fake_drug_checker/widgets/app_button.dart';
import 'package:fake_drug_checker/widgets/disclaimer_card.dart';

void main() {
  testWidgets('App loads splash screen and navigates to home smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const FakeDrugCheckerApp());
    expect(find.text('FakeDrugChecker'), findsWidgets);

    // Advance past splash transition
    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    // Verify Home screen elements
    expect(find.text('Verify Before You Trust'), findsOneWidget);
    expect(find.text('Scan Product Barcode'), findsOneWidget);
    expect(find.text('Enter Medication Details'), findsOneWidget);
  });

  testWidgets('StatusBadge renders genuine and suspicious variants correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              StatusBadge.genuine(label: 'Appears Consistent'),
              StatusBadge.suspicious(label: 'Suspicious Anomaly'),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Appears Consistent'), findsOneWidget);
    expect(find.text('Suspicious Anomaly'), findsOneWidget);
  });

  testWidgets('ConfidenceMeter renders correct percentage score', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ConfidenceMeter(
            confidence: 0.94,
            isGenuine: true,
          ),
        ),
      ),
    );

    expect(find.text('94% (High Confidence)'), findsOneWidget);
  });

  testWidgets('AppButton triggers onPressed callback when enabled', (WidgetTester tester) async {
    bool wasPressed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppButton.primary(
            label: 'Verify Medicine',
            onPressed: () {
              wasPressed = true;
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Verify Medicine'));
    expect(wasPressed, isTrue);
  });

  testWidgets('DisclaimerCard displays regulatory verification notice', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: DisclaimerCard(),
        ),
      ),
    );

    expect(find.text('Regulatory Verification Notice'), findsOneWidget);
  });

  test('DrugCheckResult model serialization and getters work correctly', () {
    final result = DrugCheckResult(
      prediction: 'Genuine',
      confidence: 0.94,
      confidencePercent: '94%',
      explanation: ['NAFDAC number matches format', 'Manufacturer verified'],
      recommendation: 'Product details match reference records.',
      inputData: {
        'Drug Name': 'Paracetamol',
        'Manufacturer': 'Emzor Pharmaceutical Industries',
        'NAFDAC Number': 'A4-7823',
      },
    );

    expect(result.isGenuine, isTrue);
    expect(result.isSuspicious, isFalse);
    expect(result.drugName, equals('Paracetamol'));
    expect(result.verdictTitle, contains('Appears Consistent'));

    final jsonStr = result.toJsonString();
    final restored = DrugCheckResult.fromJsonString(jsonStr);

    expect(restored.prediction, equals('Genuine'));
    expect(restored.confidencePercent, equals('94%'));
    expect(restored.drugName, equals('Paracetamol'));
  });
}
