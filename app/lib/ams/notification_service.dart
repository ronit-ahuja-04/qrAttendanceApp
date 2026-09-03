import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart'; // For kIsWeb
import 'package:shared_preferences/shared_preferences.dart';

import '../screens/student_dashboard_screen.dart';
import '../screens/attendance_history_screen.dart';
import '../screens/faculty_dashboard_screen.dart';
import '../screens/generate_report_screen.dart';
import '../theme/app_colors.dart';
import 'api_services.dart';
import 'globals.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `initializeApp` before using other Firebase services.
  print("Handling a background message: ${message.messageId}");
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  
  bool _initialized = false;
  GlobalKey<NavigatorState>? _navigatorKey;
  String? currentToken;
  
  Future<void> init(GlobalKey<NavigatorState> navigatorKey) async {
    _navigatorKey = navigatorKey;
    if (_initialized) return;
    
    if (!kIsWeb) {
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings initializationSettingsIOS = DarwinInitializationSettings();

      const InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );

      await flutterLocalNotificationsPlugin.initialize(
        settings: initializationSettings,
        onDidReceiveNotificationResponse: _onTap,
      );
      
      // Create the high importance channel explicitly for FCM background notifications
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'ams_channel_id', // id
        'AMS Notifications', // title
        importance: Importance.max,
        enableVibration: true,
        playSound: true,
      );

      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);

      // Request local notification permissions
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    }
    
    // Set up Firebase Cloud Messaging
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    // Explicitly enable OS level foreground notifications
    await messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    print('User granted permission: ${settings.authorizationStatus}');

    try {
      final token = await messaging.getToken();
      currentToken = token;
      print('\n=========================================');
      print('🔥 YOUR FCM TEST TOKEN 🔥');
      print(token);
      print('=========================================\n');
      
      // Send token to backend if logged in
      if (token != null && AmsGlobals.loggedInUser != null) {
        await ApiSessionService().updateFcmToken(AmsGlobals.loggedInUser!.id, token);
      }
      
      // Also listen for token refreshes
      messaging.onTokenRefresh.listen((newToken) {
        currentToken = newToken;
        if (AmsGlobals.loggedInUser != null) {
          ApiSessionService().updateFcmToken(AmsGlobals.loggedInUser!.id, newToken);
        }
      });
    } catch (e) {
      print('Failed to get FCM token: $e');
    }

    // Handle tapping a background notification (app in memory)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (message.data.isNotEmpty) {
        _onTap(NotificationResponse(
            notificationResponseType: NotificationResponseType.selectedNotification, 
            payload: jsonEncode(message.data)));
      }
    });

    // Handle tapping a terminated notification (app completely killed)
    FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
      if (message != null && message.data.isNotEmpty) {
        // Wait a tiny bit for the UI to mount before navigating
        Future.delayed(const Duration(milliseconds: 500), () {
          _onTap(NotificationResponse(
              notificationResponseType: NotificationResponseType.selectedNotification, 
              payload: jsonEncode(message.data)));
        });
      }
    });

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Got a message whilst in the foreground!');
      print('Message data: ${message.data}');

      if (message.notification != null) {
        print('Message also contained a notification: ${message.notification}');
        showNotification(
          title: message.notification!.title ?? 'New Alert',
          body: message.notification!.body ?? '',
          payload: jsonEncode(message.data),
        );
      }
      
      _eventController.add(message.data);
    });

    _initialized = true;
  }

  void _onTap(NotificationResponse response) {
    if (response.payload != null) {
      final context = _navigatorKey?.currentState?.context;
      if (context == null) return;
      
      try {
        final event = jsonDecode(response.payload!);
        final type = event['type'];

        switch (type) {
          case 'N001':
          case 'N002':
          case 'N004':
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const StudentDashboardScreen()));
            break;
          case 'N003':
          case 'N005':
          case 'LOW_ATTENDANCE':
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AttendanceHistoryScreen()));
            break;
          case 'N006':
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FacultyDashboardScreen()));
            break;
          case 'N007':
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const GenerateReportScreen()));
            break;
          default:
            break;
        }
      } catch (e) {
        print('Error handling notification tap: $e');
      }
    }
  }

  static DateTime? _lastNotificationTime;
  static String? _lastNotificationTitle;

  void showNotification({required String title, required String body, String? payload}) async {
    final now = DateTime.now();
    if (_lastNotificationTime != null && _lastNotificationTitle == title) {
      if (now.difference(_lastNotificationTime!).inSeconds < 5) {
        return; // Deduplicate identical notifications within 5 seconds
      }
    }
    _lastNotificationTime = now;
    _lastNotificationTitle = title;
    final prefs = await SharedPreferences.getInstance();
    
    // Default system master switch
    final notificationsEnabled = prefs.getBool('notif_master') ?? true;
    if (!notificationsEnabled) {
      print('Skipping push notification because master toggle is off.');
      return;
    }

    // Granular Faculty Settings
    if (payload != null) {
      try {
        final event = jsonDecode(payload);
        final type = event['type'] as String?;
        if (type == 'N006') { // Lecture/Lab Alerts
          if (!(prefs.getBool('notif_alerts') ?? true)) return;
        } else if (type == 'N008') { // Proxy Approvals
          if (!(prefs.getBool('notif_proxy') ?? true)) return;
        } else if (type == 'N007') { // Attendance Reports
          if (!(prefs.getBool('notif_attendance') ?? true)) return;
        }
      } catch (e) {
        print('Failed to parse payload for notification filtering: $e');
      }
    }

    final context = _navigatorKey?.currentState?.context;
    final overlay = _navigatorKey?.currentState?.overlay;
    final state = WidgetsBinding.instance.lifecycleState;
    
    // If we have an overlay and app is in foreground, show a beautiful custom bubble!
    if (overlay != null && state == AppLifecycleState.resumed) {
      _showInAppBubble(overlay, title: title, body: body, payload: payload);
    } 
    
    if (!kIsWeb && state != AppLifecycleState.resumed) {
      // Fallback to OS notification if app is in background or context is missing
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
              'ams_channel_id', 'AMS Notifications',
              importance: Importance.max,
              priority: Priority.high,
              color: Color(0xFF002147),
              enableVibration: true,
              playSound: true,
              showWhen: true);
              
      const NotificationDetails platformChannelSpecifics =
          NotificationDetails(android: androidPlatformChannelSpecifics);
          
      await flutterLocalNotificationsPlugin.show(
          id: DateTime.now().millisecondsSinceEpoch % 100000, 
          title: title, 
          body: body, 
          payload: payload,
          notificationDetails: platformChannelSpecifics);
    }
  }

  void _showInAppBubble(OverlayState overlayState, {required String title, required String body, String? payload}) {
    try {
      late OverlayEntry overlayEntry;
      
      overlayEntry = OverlayEntry(
        builder: (context) {
          final isWebDesktop = kIsWeb && MediaQuery.of(context).size.width > 800;
          return Positioned(
            top: isWebDesktop ? null : MediaQuery.of(context).padding.top + 16,
            bottom: isWebDesktop ? 24 : null,
            right: isWebDesktop ? 24 : 16,
            left: isWebDesktop ? null : 16,
            width: isWebDesktop ? 400 : null,
            child: Material(
            color: Colors.transparent,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: -100.0, end: 0.0),
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return Transform.translate(
                  offset: Offset(0, value),
                  child: Opacity(
                    opacity: (1 - (value / -100)).clamp(0.0, 1.0),
                    child: child,
                  ),
                );
              },
              child: GestureDetector(
                onTap: () {
                  overlayEntry.remove();
                  if (payload != null) {
                    _onTap(NotificationResponse(notificationResponseType: NotificationResponseType.selectedNotification, payload: payload));
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B), // Sleek dark slate bubble
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 10)),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF002147).withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.notifications_active, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(height: 4),
                            Text(body, style: const TextStyle(color: Colors.white70, fontSize: 14)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

      overlayState.insert(overlayEntry);
      
      // Auto-dismiss after 4 seconds
      Future.delayed(const Duration(seconds: 4), () {
        if (overlayEntry.mounted) overlayEntry.remove();
      });
    } catch (e) {
      print('Failed to show in-app bubble: $e');
    }
  }

  final StreamController<Map<String, dynamic>> _eventController = StreamController.broadcast();
  Stream<Map<String, dynamic>> get events => _eventController.stream;

  StreamSubscription? _sseSubscription;
  bool _sseDisconnectRequested = false;

  void disconnectSse() {
    _sseDisconnectRequested = true;
    _sseSubscription?.cancel();
    _sseSubscription = null;
  }

  void connectSse(String userId) {
    disconnectSse();
    _sseDisconnectRequested = false;
    _connectWithRetry(userId);
  }

  void _connectWithRetry(String userId) async {
    if (_sseDisconnectRequested) return;
    try {
      final token = AmsGlobals.loggedInUser?.token ?? '';
      final request = http.Request('GET', Uri.parse('$baseUrl/notifications/stream?userId=$userId&token=$token'));
      final response = await request.send();

      _sseSubscription = response.stream.transform(utf8.decoder).listen((data) {
        for (final line in data.split('\n')) {
          if (line.startsWith('data: ')) {
            final jsonStr = line.substring(6).trim();
            if (jsonStr.isNotEmpty) {
              try {
                final event = jsonDecode(jsonStr);
                final title = event['title'] as String?;
                final body = event['body'] ?? event['message'] as String?;
                if (title != null && body != null) {
                  SharedPreferences.getInstance().then((prefs) {
                    final notificationsEnabled = prefs.getBool('push_notifications') ?? true;
                    if (notificationsEnabled) {
                      showNotification(title: title, body: body, payload: jsonStr);
                    }
                  });
                }
                _eventController.add(event);
              } catch (e) {
                print('Error parsing SSE json: $e');
              }
            }
          }
        }
      }, onError: (e) {
        if (_sseDisconnectRequested) return;
        print('SSE stream error: $e. Reconnecting in 3 seconds...');
        Future.delayed(const Duration(seconds: 3), () => _connectWithRetry(userId));
      }, onDone: () {
        if (_sseDisconnectRequested) return;
        print('SSE stream closed. Reconnecting in 3 seconds...');
        Future.delayed(const Duration(seconds: 3), () => _connectWithRetry(userId));
      });
    } catch (e) {
      print('SSE Connection Error: $e. Reconnecting in 3 seconds...');
      Future.delayed(const Duration(seconds: 3), () => _connectWithRetry(userId));
    }
  }
}
