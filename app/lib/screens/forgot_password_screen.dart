import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/vesit_widgets.dart';
import '../ams/globals.dart';

/// 3-step Forgot Password flow:
///   Step 1 → Enter email
///   Step 2 → Enter 6-digit OTP (shown from backend in dev)
///   Step 3 → Enter + confirm new password
class ForgotPasswordScreen extends StatefulWidget {
  ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _emailFormKey = GlobalKey<FormState>();
  final _otpFormKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();

  int _step = 0; // 0=email, 1=otp, 2=new password, 3=success
  bool _loading = false;
  String? _error;
  String? _resetToken; // The OTP token from backend

  late final AnimationController _animController;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 350),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _nextStep(int next) async {
    await _animController.reverse();
    setState(() {
      _step = next;
      _error = null;
    });
    _animController.forward();
  }

  Future<void> _sendOtp() async {
    if (!(_emailFormKey.currentState?.validate() ?? false)) return;
    setState(() { _loading = true; _error = null; });
    try {
      await AmsGlobals.sessionService.forgotPassword(
        _emailController.text.trim(),
      );
      await _nextStep(1);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _verifyOtp() async {
    if (!(_otpFormKey.currentState?.validate() ?? false)) return;
    // Store user-entered OTP as the token — server verifies it in reset-password
    _resetToken = _otpController.text.trim();
    await _nextStep(2);
  }

  Future<void> _resetPassword() async {
    if (!(_passwordFormKey.currentState?.validate() ?? false)) return;
    if (_newPasswordController.text != _confirmPasswordController.text) {
      setState(() => _error = 'Passwords do not match.');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      await AmsGlobals.sessionService.resetPassword(
        _resetToken!,
        _newPasswordController.text,
      );
      await _nextStep(3);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.vesitWhite,
      resizeToAvoidBottomInset: true,
      body: Column(
        children: [
          // Blue header
          Container(
            width: double.infinity,
            color: context.colors.vesitPrimary,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                    Expanded(
                      child: Text(
                        'FORGOT PASSWORD',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Oswald',
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: context.colors.vesitGold,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                    SizedBox(width: 48),
                  ],
                ),
              ),
            ),
          ),
          // Step progress dots
          Padding(
            padding: EdgeInsets.only(top: 20, bottom: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (i) {
                final active = i <= _step && _step < 3;
                final done = i < _step || _step == 3;
                return AnimatedContainer(
                  duration: Duration(milliseconds: 300),
                  margin: EdgeInsets.symmetric(horizontal: 6),
                  width: done || active ? 32 : 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: done
                        ? context.colors.vesitGold
                        : active
                            ? context.colors.vesitPrimary
                            : context.colors.vesitPrimary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                );
              }),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(20),
              child: FadeTransition(
                opacity: _fadeAnim,
                child: _buildStep(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case 0:
        return _StepEmail(
          formKey: _emailFormKey,
          controller: _emailController,
          loading: _loading,
          error: _error,
          onSubmit: _sendOtp,
        );
      case 1:
        return _StepOtp(
          formKey: _otpFormKey,
          controller: _otpController,
          email: _emailController.text.trim(),
          loading: _loading,
          error: _error,
          onSubmit: _verifyOtp,
          onResend: () {
            _otpController.clear();
            _nextStep(0);
          },
        );
      case 2:
        return _StepNewPassword(
          formKey: _passwordFormKey,
          newController: _newPasswordController,
          confirmController: _confirmPasswordController,
          loading: _loading,
          error: _error,
          onSubmit: _resetPassword,
        );
      case 3:
        return _StepSuccess(
          onDone: () => Navigator.of(context).pop(),
        );
      default:
        return SizedBox.shrink();
    }
  }
}

// ─────────────────────────────────────────────
// Step 0 — Email Entry
// ─────────────────────────────────────────────
class _StepEmail extends StatelessWidget {
  _StepEmail({
    required this.formKey,
    required this.controller,
    required this.loading,
    required this.error,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController controller;
  final bool loading;
  final String? error;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return VesitCard(
      child: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _StepIcon(icon: Icons.email_outlined),
            SizedBox(height: 16),
            Text('Reset Your Password',
                style: context.textStyles.vesitHeadlineSm, textAlign: TextAlign.center),
            SizedBox(height: 8),
            Text(
              'Enter your registered email address and we\'ll send you a reset code.',
              style: context.textStyles.vesitBodyMd.copyWith(
                  color: context.colors.vesitPrimary.withOpacity(0.6)),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24),
            VesitTextField(
              label: 'Email Address',
              icon: Icons.alternate_email,
              hint: 'user@ves.ac.in',
              keyboardType: TextInputType.emailAddress,
              controller: controller,
              onFieldSubmitted: (_) => onSubmit(),
              validator: (v) => (v == null || v.trim().isEmpty || !v.contains('@'))
                  ? 'Enter a valid email address'
                  : null,
            ),
            if (error != null) ...[
              SizedBox(height: 12),
              _ErrorBanner(error!),
            ],
            SizedBox(height: 24),
            VesitButton(
              label: 'Send Reset Code',
              onPressed: onSubmit,
              isLoading: loading,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Step 1 — OTP Verification
// ─────────────────────────────────────────────
class _StepOtp extends StatelessWidget {
  _StepOtp({
    required this.formKey,
    required this.controller,
    required this.email,
    required this.loading,
    required this.error,
    required this.onSubmit,
    required this.onResend,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController controller;
  final String email;
  final bool loading;
  final String? error;
  final VoidCallback onSubmit;
  final VoidCallback onResend;

  @override
  Widget build(BuildContext context) {
    return VesitCard(
      child: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _StepIcon(icon: Icons.verified_outlined),
            SizedBox(height: 16),
            Text('Enter Reset Code',
                style: context.textStyles.vesitHeadlineSm, textAlign: TextAlign.center),
            SizedBox(height: 8),
            Text(
              'A 6-digit code was sent to\n$email',
              style: context.textStyles.vesitBodyMd.copyWith(
                  color: context.colors.vesitPrimary.withOpacity(0.6)),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24),
            VesitTextField(
              label: 'Reset Code',
              icon: Icons.pin_outlined,
              hint: '••••••',
              keyboardType: TextInputType.number,
              controller: controller,
              onFieldSubmitted: (_) => onSubmit(),
              validator: (v) =>
                  (v == null || v.trim().length != 6) ? 'Enter the 6-digit code' : null,
            ),
            if (error != null) ...[
              SizedBox(height: 12),
              _ErrorBanner(error!),
            ],
            SizedBox(height: 24),
            VesitButton(
              label: 'Verify Code',
              onPressed: onSubmit,
              isLoading: loading,
            ),
            SizedBox(height: 16),
            GestureDetector(
              onTap: onResend,
              child: Text(
                'Didn\'t receive a code? Resend',
                style: context.textStyles.vesitBodyMd.copyWith(
                  color: context.colors.vesitPrimary,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Step 2 — New Password
// ─────────────────────────────────────────────
class _StepNewPassword extends StatelessWidget {
  _StepNewPassword({
    required this.formKey,
    required this.newController,
    required this.confirmController,
    required this.loading,
    required this.error,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController newController;
  final TextEditingController confirmController;
  final bool loading;
  final String? error;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return VesitCard(
      child: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _StepIcon(icon: Icons.lock_reset_outlined),
            SizedBox(height: 16),
            Text('Set New Password',
                style: context.textStyles.vesitHeadlineSm, textAlign: TextAlign.center),
            SizedBox(height: 8),
            Text(
              'Choose a strong password with at least 8 characters.',
              style: context.textStyles.vesitBodyMd.copyWith(
                  color: context.colors.vesitPrimary.withOpacity(0.6)),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24),
            VesitTextField(
              label: 'New Password',
              icon: Icons.vpn_key_outlined,
              hint: 'Min. 8 characters',
              obscureText: true,
              showVisibilityToggle: true,
              controller: newController,
              validator: (v) => (v == null || v.length < 8)
                  ? 'Minimum 8 characters'
                  : null,
            ),
            SizedBox(height: 16),
            VesitTextField(
              label: 'Confirm Password',
              icon: Icons.vpn_key_outlined,
              hint: 'Re-enter new password',
              obscureText: true,
              showVisibilityToggle: true,
              controller: confirmController,
              onFieldSubmitted: (_) => onSubmit(),
              validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
            ),
            if (error != null) ...[
              SizedBox(height: 12),
              _ErrorBanner(error!),
            ],
            SizedBox(height: 24),
            VesitButton(
              label: 'Update Password',
              onPressed: onSubmit,
              isLoading: loading,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Step 3 — Success
// ─────────────────────────────────────────────
class _StepSuccess extends StatelessWidget {
  _StepSuccess({required this.onDone});
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return VesitCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF1B5E20),
            ),
            child: Icon(Icons.check_rounded, color: Colors.white, size: 44),
          ),
          SizedBox(height: 20),
          Text('Password Updated!',
              style: context.textStyles.vesitHeadlineSm, textAlign: TextAlign.center),
          SizedBox(height: 8),
          Text(
            'Your password has been reset successfully.\nYou can now log in with your new password.',
            style: context.textStyles.vesitBodyMd.copyWith(
                color: context.colors.vesitPrimary.withOpacity(0.6)),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 28),
          VesitButton(label: 'Back to Login', onPressed: onDone),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Shared widgets
// ─────────────────────────────────────────────
class _StepIcon extends StatelessWidget {
  _StepIcon({required this.icon});
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: context.colors.vesitPrimary.withOpacity(0.08),
        border: Border.all(color: context.colors.vesitPrimary.withOpacity(0.2), width: 2),
      ),
      child: Icon(icon, color: context.colors.vesitPrimary, size: 36),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  _ErrorBanner(this.message);
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red, size: 18),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: context.textStyles.vesitBodyMd.copyWith(color: Colors.red.shade700, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
