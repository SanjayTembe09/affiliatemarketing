
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_affiliate_app/main.dart';

void main() {
  testWidgets('NanoConnectApp launches successfully', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const NanoConnectApp());
    await tester.pump();

    expect(find.byType(NanoConnectApp), findsOneWidget);
  });
}
