import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/tactile_widgets.dart';
import '../ams/globals.dart';
import '../widgets/vesit_toast.dart';

/// Change Password — ported from the Stitch export (code.html:
/// "Chronos Admin - Change Password"). Reachable from Account Settings'
/// "Change Password" row.
class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _submitting = false;
  bool _success = false;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

    Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_newController.text != _confirmController.text) {
      VesitToast.show(context: context, title: "New password and confirmation don't match", type: ToastType.info);
      return;
    }

    setState(() => _submitting = true);
    
    try {
      await Future.delayed(const Duration(milliseconds: 500)); // mock network call
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _success = true;
      });
      VesitToast.show(context: context, title: 'Password updated successfully', type: ToastType.success);
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;
      Navigator.of(context).maybePop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      VesitToast.show(context: context, title: "Error: $e", type: ToastType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.surface,
      body: SafeArea(
        child: Column(
          children: [
            _Header(onBack: () => Navigator.of(context).maybePop()),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
                children: [
                  Center(
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: context.colors.surfaceContainer,
                            border: Border.all(color: context.colors.outlineVariant),
                            boxShadow: [
                              BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: Icon(Icons.lock_reset, color: context.colors.primary, size: 36),
                        ),
                        Positioned(
                          top: -2,
                          right: -2,
                          child: Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: context.colors.primaryContainer,
                              border: Border.all(color: context.colors.surface, width: 2),
                              boxShadow: [
                                BoxShadow(color: context.colors.primaryContainer.withOpacity(0.8), blurRadius: 6),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  RaisedPanel(
                    borderRadius: 20,
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          DebossedField(
                            label: 'Current Password',
                            icon: Icons.lock_outline,
                            hint: '••••••••',
                            obscureText: true,
                            showVisibilityToggle: true,
                            controller: _currentController,
                            validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                          ),
                          const SizedBox(height: 16),
                          DebossedField(
                            label: 'New Password',
                            icon: Icons.vpn_key_outlined,
                            hint: 'Min. 8 characters',
                            obscureText: true,
                            showVisibilityToggle: true,
                            controller: _newController,
                            validator: (v) => (v == null || v.length < 8) ? 'Min. 8 characters' : null,
                          ),
                          const SizedBox(height: 16),
                          DebossedField(
                            label: 'Confirm Password',
                            icon: Icons.vpn_key_outlined,
                            hint: 'Re-type new password',
                            obscureText: true,
                            showVisibilityToggle: true,
                            controller: _confirmController,
                            validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                          ),
                          const SizedBox(height: 20),
                          PushableButton(
                            label: _submitting
                                ? 'Updating...'
                                : (_success ? 'Success' : 'Update Password'),
                            icon: _success ? Icons.check_circle : null,
                            onPressed: _submitting || _success ? () {} : _submit,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: context.colors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: context.colors.outlineVariant, width: 1),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline, color: context.colors.primary, size: 18),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Ensure your new password contains a mix of uppercase, lowercase, numbers, and symbols for maximum security.',
                            style: context.textStyles.labelSm.copyWith(color: context.colors.onSurfaceVariant),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: context.colors.surface,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: Icon(Icons.arrow_back, color: context.colors.primary),
          ),
          Expanded(
            child: Text(
              'Change Password',
              textAlign: TextAlign.center,
              style: context.textStyles.headlineSm.copyWith(color: context.colors.primary),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}
