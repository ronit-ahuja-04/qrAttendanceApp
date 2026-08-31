import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/glass_bottom_nav.dart';
import 'faculty_dashboard_screen.dart';
import 'faculty_readonly_timetable_screen.dart';
import 'faculty_session_history_screen.dart';
import 'faculty_profile_screen.dart';

class FacultyMainLayout extends StatefulWidget {
  const FacultyMainLayout({super.key});

  @override
  State<FacultyMainLayout> createState() => _FacultyMainLayoutState();
}

class _FacultyMainLayoutState extends State<FacultyMainLayout> {
  int _currentIndex = 0;

  late final List<ScrollController> _scrollControllers;
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _scrollControllers = List.generate(4, (_) => ScrollController());
    _screens = [
      FacultyDashboardScreen(
        onProfileTap: () => _onTabTapped(3),
        scrollController: _scrollControllers[0],
      ),
      const FacultyReadonlyTimetableScreen(),
      const FacultySessionHistoryScreen(),
      FacultyProfileScreen(scrollController: _scrollControllers[3]),
    ];
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
  void dispose() {
    for (var controller in _scrollControllers) {
      controller.dispose();
    }
    super.dispose();
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
                    GlassNavItem(icon: Icons.calendar_today_rounded, label: 'Timetable'),
                    GlassNavItem(icon: Icons.history_rounded, label: 'History'),
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
