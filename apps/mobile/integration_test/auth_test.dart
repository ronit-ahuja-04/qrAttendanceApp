import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:magic_attendance_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Authentication Flow', () {
    testWidgets('Shows error when logging in with empty fields', (tester) async {
      await tester.pumpWidget(const app.AttendancePortalApp());
      await tester.pumpAndSettle();

      // Find login button
      final loginButton = find.text('Login');
      expect(loginButton, findsOneWidget);

      // Tap login without entering credentials
      await tester.tap(loginButton);
      await tester.pumpAndSettle();

      // Check for validation errors (Assuming standard Snackbar or text)
      // Since it calls API, it might show "Missing email or password" snackbar.
      expect(find.text('Please enter email'), findsWidgets); // fallback check
    });

    testWidgets('Can toggle password visibility', (tester) async {
      await tester.pumpWidget(const app.AttendancePortalApp());
      await tester.pumpAndSettle();

      final passwordField = find.byType(TextField).last; // Assuming second is password
      final visibilityIcon = find.byIcon(Icons.visibility_off);

      expect(visibilityIcon, findsOneWidget);

      await tester.tap(visibilityIcon);
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.visibility), findsOneWidget);
    });
  });
}
