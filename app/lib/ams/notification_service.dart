import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart'; // For kIsWeb

import '../screens/student_dashboard_screen.dart';
import '../screens/attendance_history_screen.dart';
import '../screens/faculty_dashboard_screen.dart';
import '../screens/generate_report_screen.dart';
import '../theme/app_colors.dart';
import 'api_services.dart' show baseUrl;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  
  bool _initialized = false;
  GlobalKey<NavigatorState>? _navigatorKey;
  
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
      
      // Request permissions
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    }
    
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

  void showNotification({required String title, required String body, String? payload}) async {
    if (kIsWeb) {
      // In web, fallback to simple print or generic web notification if possible
      print('WEB NOTIFICATION: $title - $body');
      return;
    }

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
            'ams_channel_id', 'AMS Notifications',
            importance: Importance.max,
            priority: Priority.high,
            color: AppColors.primaryContainer,
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

  final StreamController<Map<String, dynamic>> _eventController = StreamController.broadcast();
  Stream<Map<String, dynamic>> get events => _eventController.stream;

  void connectSse(String userId) async {
    try {
      final request = http.Request('GET', Uri.parse('$baseUrl/notifications/stream?userId=$userId'));
      final response = await request.send();

      response.stream.transform(utf8.decoder).listen((data) {
        if (data.startsWith('data: ')) {
          final jsonStr = data.substring(6).trim();
          if (jsonStr.isNotEmpty) {
            try {
              final event = jsonDecode(jsonStr);
              showNotification(title: event['title'], body: event['message'], payload: jsonStr);
              _eventController.add(event);
            } catch (e) {
              print('Error parsing SSE json: $e');
            }
          }
        }
      }, onError: (e) {
        print('SSE stream error: $e');
      });
    } catch (e) {
      print('SSE Connection Error: $e');
    }
  }
}
