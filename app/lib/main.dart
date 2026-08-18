import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'theme/app_colors.dart';
import 'ams/notification_service.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService().init(navigatorKey);
  runApp(const AttendancePortalApp());
}

class AttendancePortalApp extends StatelessWidget {
  const AttendancePortalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'VESIT Attendance Portal',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.wall,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          surface: AppColors.surface,
        ),
      ),
      home: const LoginScreen(),
    );
  }
}
