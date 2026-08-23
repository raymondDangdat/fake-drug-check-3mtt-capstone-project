import 'package:flutter_test/flutter_test.dart';
import 'package:fake_drug_checker/main.dart';

void main() {
  testWidgets('App loads splash screen smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const FakeDrugCheckerApp());
    expect(find.text('FakeDrugChecker'), findsOneWidget);
  });
}
