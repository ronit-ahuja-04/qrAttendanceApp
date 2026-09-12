import re

with open('lib/screens/attendance_history_screen.dart', 'r') as f:
    content = f.read()

# 1. Add state variables for stats
state_start = 'class _AttendanceHistoryScreenState extends State<AttendanceHistoryScreen> {\n  List<_AttendanceEntry> _today = [];\n  List<_DayGroup> _earlierThisWeek = [];\n  bool _loading = true;'
state_new = 'class _AttendanceHistoryScreenState extends State<AttendanceHistoryScreen> {\n  List<_AttendanceEntry> _today = [];\n  List<_DayGroup> _earlierThisWeek = [];\n  bool _loading = true;\n  int _totalCount = 0;\n  int _attendedCount = 0;\n  int _missedCount = 0;'
content = content.replace(state_start, state_new)

# 2. Calculate stats in _loadHistory and filter to 5 days
load_history_start = '''    final List<_DayGroup> earlier = [];
    bool dimFlag = false;
    groupMap.forEach((label, entries) {
      earlier.add(_DayGroup(label: label, entries: entries, dim: dimFlag));
      dimFlag = !dimFlag; // alternate dimming for older days
    });

    if (mounted) {
      setState(() {
        _today = todayEntries;
        _earlierThisWeek = earlier;
        _loading = false;
      });
    }'''

load_history_new = '''    final List<_DayGroup> earlier = [];
    bool dimFlag = false;
    
    // Sort groupMap keys (dates) descending to pick top 5
    // But our keys are "Yesterday, Oct 23" which is hard to sort. 
    // Actually the history is already sorted DESC from backend!
    int count = 0;
    groupMap.forEach((label, entries) {
      if (count < 5) {
        earlier.add(_DayGroup(label: label, entries: entries, dim: dimFlag));
        dimFlag = !dimFlag;
        count++;
      }
    });

    int attended = 0;
    int missed = 0;
    for (var h in history) {
      if (h['status'] == 'present') attended++;
      else missed++;
    }

    if (mounted) {
      setState(() {
        _today = todayEntries;
        _earlierThisWeek = earlier;
        _totalCount = history.length;
        _attendedCount = attended;
        _missedCount = missed;
        _loading = false;
      });
    }'''
content = content.replace(load_history_start, load_history_new)


# 3. Update build method calls
# We need to change _Header, _ActiveSessionBanner, _StatsRow, and empty states.
build_start = '''                  _Header(
                    onBack: () {
                      if (Navigator.of(context).canPop()) {
                        Navigator.of(context).pop();
                      } else {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                              builder: (_) => const StudentDashboardScreen()),
                        );
                      }
                    },
                    onFilterTap: () => _openCalendarFilter(context),
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                      children: [
                        _ActiveSessionBanner(
                            onSwap: () => _switchSession(context)),
                        const SizedBox(height: 12),
                        const _StatsRow(),
                        const SizedBox(height: 24),
                        const _SectionDivider(title: "Today's Log"),
                        const SizedBox(height: 10),
                        ..._today.map(
                          (e) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _AttendanceCard(entry: e),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const _SectionDivider(title: 'Earlier This Week'),
                        const SizedBox(height: 10),
                        ..._earlierThisWeek.map('''

build_new = '''                  _Header(
                    onBack: () {
                      if (Navigator.of(context).canPop()) {
                        Navigator.of(context).pop();
                      } else {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                              builder: (_) => const StudentDashboardScreen()),
                        );
                      }
                    },
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                      children: [
                        _DateBanner(),
                        const SizedBox(height: 12),
                        _StatsRow(total: _totalCount, attended: _attendedCount, missed: _missedCount),
                        const SizedBox(height: 24),
                        const _SectionDivider(title: "Today's Log"),
                        const SizedBox(height: 10),
                        if (_today.isEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Text('No log yet!', style: TextStyle(color: Colors.grey.shade500)),
                          )
                        else
                          ..._today.map(
                            (e) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _AttendanceCard(entry: e),
                            ),
                          ),
                        const SizedBox(height: 12),
                        const _SectionDivider(title: 'Earlier This Week'),
                        const SizedBox(height: 10),
                        if (_earlierThisWeek.isEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Text('-', style: TextStyle(color: Colors.grey.shade500, fontSize: 24)),
                          )
                        else
                          ..._earlierThisWeek.map('''
content = content.replace(build_start, build_new)

# 4. Update Header class
header_start = '''class _Header extends StatelessWidget {
  const _Header({required this.onBack, required this.onFilterTap});

  final VoidCallback onBack;
  final VoidCallback onFilterTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: AppColors.vesitWhite,
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onBack,
            child:
                Icon(Icons.arrow_back, color: Colors.grey.shade600, size: 24),
          ),
          Expanded(
            child: Text(
              'Attendance History',
              textAlign: TextAlign.center,
              style: AppTextStyles.vesitHeadlineSm
                  .copyWith(color: AppColors.vesitPrimary),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          GestureDetector(
            onTap: onFilterTap,
            child: const Icon(Icons.calendar_month,
                color: AppColors.vesitPrimary, size: 24),
          ),
        ],
      ),
    );
  }
}'''

header_new = '''class _Header extends StatelessWidget {
  const _Header({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: AppColors.vesitWhite,
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onBack,
            child:
                Icon(Icons.arrow_back, color: Colors.grey.shade600, size: 24),
          ),
          Expanded(
            child: Text(
              'Attendance History',
              textAlign: TextAlign.center,
              style: AppTextStyles.vesitHeadlineSm
                  .copyWith(color: AppColors.vesitPrimary),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 24), // to balance the arrow back
        ],
      ),
    );
  }
}'''
content = content.replace(header_start, header_new)

# 5. Update Banner
banner_start = '''class _ActiveSessionBanner extends StatelessWidget {
  const _ActiveSessionBanner({required this.onSwap});

  final VoidCallback onSwap;

  @override
  Widget build(BuildContext context) {
    return VesitCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const PilotLight(active: true, size: 8),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ACTIVE SESSION',
                  style: AppTextStyles.vesitLabelBold.copyWith(
                      letterSpacing: 1.2, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 2),
                Text('Today, Oct 24', style: AppTextStyles.vesitHeadlineSm),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: AppColors.vesitPrimary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: IconButton(
              onPressed: onSwap,
              icon: const Icon(Icons.swap_horiz,
                  color: AppColors.vesitPrimary, size: 22),
            ),
          ),
        ],
      ),
    );
  }
}'''

banner_new = '''class _DateBanner extends StatelessWidget {
  const _DateBanner();

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final Map<int, String> days = {1:'Monday',2:'Tuesday',3:'Wednesday',4:'Thursday',5:'Friday',6:'Saturday',7:'Sunday'};
    final Map<int, String> months = {1:'Jan',2:'Feb',3:'Mar',4:'Apr',5:'May',6:'Jun',7:'Jul',8:'Aug',9:'Sep',10:'Oct',11:'Nov',12:'Dec'};
    
    return VesitCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const PilotLight(active: true, size: 8),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TODAY\\'S DATE',
                  style: AppTextStyles.vesitLabelBold.copyWith(
                      letterSpacing: 1.2, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 2),
                Text('${days[now.weekday]}, ${months[now.month]} ${now.day} ${now.year}', style: AppTextStyles.vesitHeadlineSm),
              ],
            ),
          ),
        ],
      ),
    );
  }
}'''
content = content.replace(banner_start, banner_new)

# 6. Update StatsRow
stats_start = '''class _StatsRow extends StatelessWidget {
  const _StatsRow();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(
            child: _StatWell(
                label: 'Total',
                value: '4 Classes',
                valueColor: AppColors.vesitTextHeading)),
        SizedBox(width: 8),
        Expanded(
            child: _StatWell(
                label: 'Attended',
                value: '3',
                valueColor: AppColors.vesitPrimary)),
        SizedBox(width: 8),
        Expanded(
            child:
                _StatWell(label: 'Missed', value: '1', valueColor: Colors.red)),
      ],
    );
  }
}'''

stats_new = '''class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.total, required this.attended, required this.missed});
  final int total;
  final int attended;
  final int missed;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
            child: _StatWell(
                label: 'Total',
                value: '$total',
                valueColor: AppColors.vesitTextHeading)),
        const SizedBox(width: 8),
        Expanded(
            child: _StatWell(
                label: 'Attended',
                value: '$attended',
                valueColor: AppColors.vesitPrimary)),
        const SizedBox(width: 8),
        Expanded(
            child:
                _StatWell(label: 'Missed', value: '$missed', valueColor: Colors.red)),
      ],
    );
  }
}'''
content = content.replace(stats_start, stats_new)

# 7. Remove the unused methods _openCalendarFilter and _switchSession
content = re.sub(r'  void _openCalendarFilter\(BuildContext context\) \{.*?\n  }\n', '', content, flags=re.DOTALL)
content = re.sub(r'  void _switchSession\(BuildContext context\) \{.*?\n  }\n', '', content, flags=re.DOTALL)

with open('lib/screens/attendance_history_screen.dart', 'w') as f:
    f.write(content)
