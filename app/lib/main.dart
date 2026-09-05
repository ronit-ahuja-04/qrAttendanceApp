import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'screens/login_screen.dart';
import 'theme/app_colors.dart';
import 'ams/notification_service.dart';
import 'ams/globals.dart';
import 'ams/api_services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'ams/models.dart';
import 'screens/maintenance_screen.dart';
import 'screens/faculty_main_layout.dart';
import 'screens/student_main_layout.dart';
import 'ams/globals.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    // Connect to Notifications stream if user is logged in
    await NotificationService().init(AmsGlobals.navigatorKey);
  } catch (e) {
    print('Failed to initialize Firebase: $e');
  }

  // Real-time Maintenance Mode Monitor
  Timer.periodic(const Duration(seconds: 15), (timer) async {
    try {
      final response = await httpClient.get(Uri.parse('$baseUrl/api/health')).timeout(const Duration(seconds: 5));
      final context = AmsGlobals.navigatorKey.currentContext;
      if (context != null) {
        bool isMaintenanceRoute = false;
        Navigator.popUntil(context, (route) {
          if (route.settings.name == '/maintenance') {
            isMaintenanceRoute = true;
          }
          return true; // Don't actually pop anything
        });

        if (response.statusCode == 503 && !isMaintenanceRoute) {
          Navigator.of(context).pushReplacementNamed('/maintenance');
        } else if (response.statusCode == 200 && isMaintenanceRoute) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          );
        }
      }
    } catch (e) {
      // Ignore network errors, only act on explicit 503 or 200
    }
  });

  await AmsGlobals.initTheme();
  runApp(const AttendancePortalApp());
}

class AttendancePortalApp extends StatelessWidget {
  const AttendancePortalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AmsGlobals.themeNotifier,
      builder: (context, themeMode, child) {
        return MaterialApp(
          navigatorKey: AmsGlobals.navigatorKey,
          title: 'VESIT Attendance Portal',
          debugShowCheckedModeBanner: false,
          routes: {
            '/maintenance': (context) => const MaintenanceScreen(),
          },
          scrollBehavior: const MaterialScrollBehavior().copyWith(
            dragDevices: {PointerDeviceKind.mouse, PointerDeviceKind.touch, PointerDeviceKind.stylus, PointerDeviceKind.unknown},
          ),
          themeMode: themeMode,
          theme: ThemeData(
            useMaterial3: true,
            scaffoldBackgroundColor: AppThemeColors.light.vesitGray,
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppThemeColors.light.vesitPrimary,
              primary: AppThemeColors.light.vesitPrimary,
              surface: AppThemeColors.light.vesitWhite,
            ),
            extensions: const <ThemeExtension<dynamic>>[AppThemeColors.light],
            pageTransitionsTheme: const PageTransitionsTheme(
              builders: {
                TargetPlatform.android: _VesitPageTransition(),
                TargetPlatform.iOS: _VesitPageTransition(),
                TargetPlatform.macOS: _VesitPageTransition(),
                TargetPlatform.windows: _VesitPageTransition(),
                TargetPlatform.linux: _VesitPageTransition(),
              },
            ),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            scaffoldBackgroundColor: AppThemeColors.dark.vesitGray,
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppThemeColors.dark.vesitPrimary,
              brightness: Brightness.dark,
              primary: AppThemeColors.dark.vesitPrimary,
              surface: AppThemeColors.dark.vesitWhite,
            ),
            extensions: const <ThemeExtension<dynamic>>[AppThemeColors.dark],
            pageTransitionsTheme: const PageTransitionsTheme(
              builders: {
                TargetPlatform.android: _VesitPageTransition(),
                TargetPlatform.iOS: _VesitPageTransition(),
                TargetPlatform.macOS: _VesitPageTransition(),
                TargetPlatform.windows: _VesitPageTransition(),
                TargetPlatform.linux: _VesitPageTransition(),
              },
            ),
          ),
          home: const AmsBootLoader(),
        );
      }
    );
  }
}

class AmsBootLoader extends StatefulWidget {
  const AmsBootLoader({super.key});

  @override
  State<AmsBootLoader> createState() => _AmsBootLoaderState();
}

class _AmsBootLoaderState extends State<AmsBootLoader> {
  @override
  void initState() {
    super.initState();
    _checkLoginState();
  }

  Future<void> _checkLoginState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionJson = prefs.getString('ams_user_session');
      if (sessionJson != null && sessionJson.isNotEmpty) {
        final Map<String, dynamic> userMap = jsonDecode(sessionJson);
        final user = User.fromJson(userMap);
        AmsGlobals.loggedInUser = user;
        
        // Ensure FCM token is synced since BootLoader bypassed the login screen
        final token = NotificationService().currentToken;
        if (token != null) {
          ApiSessionService().updateFcmToken(user.id, token).catchError((_) {});
        }

        if (!mounted) return;
        if (user.role == 'faculty') {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const FacultyMainLayout()),
          );
        } else {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const StudentMainLayout()),
          );
        }
        return;
      }
    } catch (e) {
      print('Bootloader error: $e');
    }
    
    // Ping backend to check for Maintenance Mode (503)
    try {
      final response = await httpClient.get(Uri.parse('$baseUrl/api/health')).timeout(const Duration(seconds: 5));
      if (response.statusCode == 503) {
        if (!mounted) return;
        Navigator.of(context).pushReplacementNamed('/maintenance');
        return;
      }
    } catch (e) {
      // Ignore normal connection errors or timeouts, we just want to catch the explicit 503
    }

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppThemeColors.light.vesitGray,
      body: Center(
        child: CircularProgressIndicator(
          color: AppThemeColors.light.vesitPrimary,
        ),
      ),
    );
  }
}

// ─── Premium Vesit Slide+Fade Transition ───────────────────────────────────
class _VesitPageTransition extends PageTransitionsBuilder {
  const _VesitPageTransition();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final slide = Tween<Offset>(
      begin: const Offset(0.0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
    ));

    final fade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: animation,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
      ),
    );

    return FadeTransition(
      opacity: fade,
      child: SlideTransition(position: slide, child: child),
    );
  }
}
