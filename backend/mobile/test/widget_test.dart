import 'package:flutter_test/flutter_test.dart';
import 'package:supplylink/main.dart';

void main() {
  testWidgets('App starts', (WidgetTester tester) async {
    await tester.pumpWidget(const SupplyLinkApp());
    expect(find.byType(SupplyLinkApp), findsOneWidget);
  });
}
