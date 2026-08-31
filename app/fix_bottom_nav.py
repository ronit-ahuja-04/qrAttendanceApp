import re

with open('lib/widgets/tactile_widgets.dart', 'r') as f:
    content = f.read()

# Replace the whole build method of TactileBottomNav
nav_start = '''  @override
  Widget build(BuildContext context) {
    return Container(
      height: 76,
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, -4))],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(_items.length, (i) {
            final item = _items[i];
            final active = i == currentIndex;
            return GestureDetector(
              onTap: () {
                if (active) return;
                if (item.label == 'Profile') {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const StudentProfileScreen()),
                  );
                  return;
                }
                if (item.label == 'Home') {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const StudentDashboardScreen()),
                  );
                  return;
                }
                if (item.label == 'Attendance') {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const AttendanceHistoryScreen()),
                  );
                  return;
                }
                if (item.label == 'Timetable') {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const StudentTimetableScreen()),
                  );
                  return;
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${item.label} — coming soon'), duration: const Duration(seconds: 1)),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: active ? AppColors.surfaceContainerHighest : Colors.transparent,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      active ? item.activeIcon : item.icon,
                      color: active ? AppColors.primaryContainer : AppColors.secondary,
                      size: 24,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.label.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: active ? AppColors.primaryContainer : AppColors.secondary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }'''

nav_new = '''  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.vesitWhite,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, -2))],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(_items.length, (i) {
              final item = _items[i];
              final active = i == currentIndex;
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  if (active) return;
                  if (item.label == 'Profile') {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const StudentProfileScreen()),
                    );
                    return;
                  }
                  if (item.label == 'Home') {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const StudentDashboardScreen()),
                    );
                    return;
                  }
                  if (item.label == 'Attendance') {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const AttendanceHistoryScreen()),
                    );
                    return;
                  }
                  if (item.label == 'Timetable') {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const StudentTimetableScreen()),
                    );
                    return;
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${item.label} — coming soon'), duration: const Duration(seconds: 1)),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: active ? AppColors.vesitPrimary.withOpacity(0.08) : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        active ? item.activeIcon : item.icon,
                        color: active ? AppColors.vesitPrimary : Colors.grey.shade500,
                        size: 26,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: active ? FontWeight.bold : FontWeight.w600,
                          color: active ? AppColors.vesitPrimary : Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }'''

content = content.replace(nav_start, nav_new)

with open('lib/widgets/tactile_widgets.dart', 'w') as f:
    f.write(content)
