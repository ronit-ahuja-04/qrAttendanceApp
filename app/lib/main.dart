import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'screens/login_screen.dart';
import 'theme/app_colors.dart';
import 'ams/notification_service.dart';
import 'ams/globals.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await NotificationService().init(navigatorKey);
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
          navigatorKey: navigatorKey,
          title: 'VESIT Attendance Portal',
          debugShowCheckedModeBanner: false,
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
          home: const LoginScreen(),
        );
      }
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
