import 'package:flutter_test/flutter_test.dart';
import 'package:cybershield_wifi/main.dart';

void main() {
  testWidgets('CyberShield App Smoke Test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const CyberShieldApp());

    // Verify that our app bar title is displayed.
    expect(find.text('CYBERSHIELD WiFi'), findsOneWidget);

    // Verify that we have a bottom navigation bar with DASHBOARD.
    expect(find.text('DASHBOARD'), findsOneWidget);
  });
}
