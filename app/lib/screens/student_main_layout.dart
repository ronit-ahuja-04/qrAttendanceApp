import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/glass_bottom_nav.dart';
import 'student_dashboard_screen.dart';
import 'qr_scanner_screen.dart';
import 'attendance_history_screen.dart';
import 'student_timetable_screen.dart';
import 'student_profile_screen.dart';

class StudentMainLayout extends StatefulWidget {
  const StudentMainLayout({super.key});

  @override
  State<StudentMainLayout> createState() => _StudentMainLayoutState();
}

class _StudentMainLayoutState extends State<StudentMainLayout> {
  int _currentIndex = 0;
  late final List<ScrollController> _scrollControllers;
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _scrollControllers = List.generate(4, (_) => ScrollController());
    _screens = [
      StudentDashboardScreen(
        onProfileTap: () => _onTabTapped(3),
        scrollController: _scrollControllers[0],
      ),
      AttendanceHistoryScreen(scrollController: _scrollControllers[1]),
      StudentTimetableScreen(scrollController: _scrollControllers[2]),
      StudentProfileScreen(scrollController: _scrollControllers[3]),
    ];
  }

  @override
  void dispose() {
    for (var controller in _scrollControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _onTabTapped(int index) {
    if (_currentIndex == index) {
      if (_scrollControllers[index].hasClients) {
        _scrollControllers[index].animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        );
      }
    } else {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _currentIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _currentIndex != 0) {
          setState(() {
            _currentIndex = 0;
          });
        }
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: context.colors.surface,
        body: Stack(
          children: [
            IndexedStack(
              index: _currentIndex,
              children: _screens,
            ),
            if (MediaQuery.of(context).size.width <= 800)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: GlassBottomNav(
                  currentIndex: _currentIndex,
                  onTap: _onTabTapped,
                  items: [
                    GlassNavItem(icon: Icons.home_rounded, label: 'Home'),
                    GlassNavItem(icon: Icons.history_rounded, label: 'History'),
                    GlassNavItem(icon: Icons.calendar_today_rounded, label: 'Timetable'),
                    GlassNavItem(icon: Icons.person_rounded, label: 'Profile'),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
