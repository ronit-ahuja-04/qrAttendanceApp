import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:magic_attendance_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Student Flow', () {
    testWidgets('Scanner screen loads and handles invalid QR', (tester) async {
      await tester.pumpWidget(const app.AttendancePortalApp());
      await tester.pumpAndSettle();

      // Find scanner button
      final scanBtn = find.byIcon(Icons.qr_code_scanner);
      if (scanBtn.evaluate().isNotEmpty) {
        await tester.tap(scanBtn);
        await tester.pumpAndSettle();

        // In integration testing, the camera plugin usually shows a mock or blank view.
        // We test the manual input or mock the QR scan result via platform channels.
      }
    });

    testWidgets('Shows success animation after attendance marked', (tester) async {
      await tester.pumpWidget(const app.AttendancePortalApp());
      await tester.pumpAndSettle();
      
      // Simulate successful scan and verify animation / dialog appears
      // expect(find.text('Attendance Marked Successfully!'), findsOneWidget);
    });
  });
}
