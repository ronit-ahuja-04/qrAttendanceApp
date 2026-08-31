import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../ams/api_services.dart';
import '../ams/globals.dart';
import '../ams/models.dart';
import '../ams/api_services.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/vesit_widgets.dart';
import '../widgets/vesit_toast.dart';

class ProxyApprovalsScreen extends StatefulWidget {
  const ProxyApprovalsScreen({super.key});

  @override
  State<ProxyApprovalsScreen> createState() => _ProxyApprovalsScreenState();
}

class _ProxyApprovalsScreenState extends State<ProxyApprovalsScreen> {
  bool _isLoading = true;
  List<AttendanceSession> _pendingSessions = [];

  @override
  void initState() {
    super.initState();
    _fetchPendingApprovals();
  }

  Future<void> _fetchPendingApprovals() async {
    final user = AmsGlobals.loggedInUser;
    if (user != null) {
      final sessions = await ApiSessionService().getFacultySessions(user.id);
      if (mounted) {
        setState(() {
          _pendingSessions = sessions.where((s) => s.approvalStatus == 'pending').toList();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleApprove(AttendanceSession session) async {
    final confirmed = await _showConfirmDialog(
      title: 'Approve Proxy Session',
      content: 'Are you sure you want to approve this attendance session? It will be officially added to your records.',
      confirmText: 'Approve',
      confirmColor: Colors.green,
    );
    if (!confirmed) return;

    setState(() => _isLoading = true);
    final success = await AmsGlobals.sessionService.approveProxySession(session.id);
    if (success) {
      if (mounted) {
        setState(() {
          _pendingSessions.removeWhere((s) => s.id == session.id);
          _isLoading = false;
        });
        VesitToast.show(context: context, title: 'Session approved.', type: ToastType.info);
        if (_pendingSessions.isEmpty) {
          Navigator.of(context).pop();
        }
      }
      _fetchPendingApprovals(); // background sync
    } else {
      setState(() => _isLoading = false);
      if (mounted) {
        VesitToast.show(context: context, title: 'Failed to approve session.', type: ToastType.info);
      }
    }
  }

  Future<void> _handleDecline(AttendanceSession session) async {
    final confirmed = await _showConfirmDialog(
      title: 'Decline Proxy Session',
      content: 'Are you sure you want to decline this attendance session? The recorded attendance will be invalidated.',
      confirmText: 'Decline',
      confirmColor: Colors.red,
    );
    if (!confirmed) return;

    setState(() => _isLoading = true);
    final success = await AmsGlobals.sessionService.declineProxySession(session.id);
    if (success) {
      if (mounted) {
        setState(() {
          _pendingSessions.removeWhere((s) => s.id == session.id);
          _isLoading = false;
        });
        VesitToast.show(context: context, title: 'Session declined.', type: ToastType.info);
        if (_pendingSessions.isEmpty) {
          Navigator.of(context).pop();
        }
      }
      _fetchPendingApprovals(); // background sync
    } else {
      setState(() => _isLoading = false);
      if (mounted) {
        VesitToast.show(context: context, title: 'Failed to decline session.', type: ToastType.info);
      }
    }
  }

  Future<bool> _showConfirmDialog({
    required String title,
    required String content,
    required String confirmText,
    required Color confirmColor,
  }) async {
    return await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title, style: context.textStyles.vesitHeadlineSm),
        content: Text(content, style: context.textStyles.vesitBodyMd),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: confirmColor, foregroundColor: Colors.white),
            child: Text(confirmText),
          ),
        ],
      ),
    ) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.vesitGray,
      appBar: AppBar(
        backgroundColor: context.colors.vesitPrimary,
        title: Text('Proxy Approvals', style: context.textStyles.vesitHeadlineSm.copyWith(color: context.colors.vesitWhite)),
        iconTheme: IconThemeData(color: context.colors.vesitWhite),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _pendingSessions.isEmpty
              ? _buildEmptyState()
              : _buildList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline, size: 80, color: Colors.green.shade300),
          const SizedBox(height: 16),
          Text(
            'All Caught Up!',
            style: context.textStyles.vesitHeadlineSm.copyWith(color: Colors.grey.shade800),
          ),
          const SizedBox(height: 8),
          Text(
            'You have no pending proxy approvals.',
            style: context.textStyles.vesitBodyMd.copyWith(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _pendingSessions.length,
      itemBuilder: (context, index) {
        final session = _pendingSessions[index];
        final dateStr = DateFormat('MMM d, yyyy • h:mm a').format(session.createdAt);
        final isLab = session.courseCode.toLowerCase().contains('lab');

        return VesitCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: context.colors.vesitPrimary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isLab ? Icons.science_outlined : Icons.book_outlined,
                      color: context.colors.vesitPrimary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(session.courseCode, style: context.textStyles.vesitHeadlineSm),
                        if (session.batchTarget != null) ...[
                          const SizedBox(height: 2),
                          Text(session.batchTarget!, style: context.textStyles.vesitBodySm.copyWith(color: context.colors.vesitPrimary)),
                        ],
                        const SizedBox(height: 4),
                        Text(dateStr, style: context.textStyles.vesitBodySm.copyWith(color: Colors.grey.shade600)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.person, color: Colors.grey.shade600, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Proxy Faculty: ${AmsGlobals.formatFacultyName(session.proxyFacultyName ?? session.proxyFacultyId ?? 'Unknown')}',
                        style: context.textStyles.vesitBodyMd,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _handleDecline(session),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Decline'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _handleApprove(session),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Approve'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
