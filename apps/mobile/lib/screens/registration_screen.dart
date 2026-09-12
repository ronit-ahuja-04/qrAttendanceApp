import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/tactile_widgets.dart';
import 'faculty_dashboard_screen.dart';
import 'login_screen.dart';
import 'student_dashboard_screen.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key, required this.role});

  final UserRole role;

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _agreedToTerms = false;

  bool get _isFaculty => widget.role == UserRole.faculty;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _handleCreateAccount() {
    if (!_formKey.currentState!.validate()) return;
    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please agree to the Terms & Conditions.')),
      );
      return;
    }

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => widget.role == UserRole.student
            ? const StudentDashboardScreen()
            : const FacultyDashboardScreen(),
      ),
      (route) => false,
    );
  }

  void _goToLogin() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.wall,
      appBar: TactileAppBar(
        trailingTitle: _isFaculty ? 'FACULTY REGISTRATION' : 'STUDENT REGISTRATION',
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: RaisedPanel(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Registration', style: context.textStyles.headlineMd),
                      const SizedBox(height: 4),
                      Text(
                        _isFaculty
                            ? 'Create your faculty access node.'
                            : 'Fill in your physical hardware credentials.',
                        style: context.textStyles.bodyMd.copyWith(color: context.colors.onSurfaceVariant),
                      ),
                      const SizedBox(height: 20),
                      DebossedField(
                        label: 'Full Name',
                        icon: Icons.person_outline,
                        hint: _isFaculty ? 'Dr. Julian Sterling' : 'Johnathan Doe',
                        controller: _nameController,
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Enter your full name' : null,
                      ),
                      const SizedBox(height: 16),
                      DebossedField(
                        label: _isFaculty ? 'Official Email' : 'College Email',
                        icon: Icons.mail_outline,
                        hint: _isFaculty
                            ? 'sterling.j@faculty.vesit.edu'
                            : 'j.doe@vesit.edu',
                        keyboardType: TextInputType.emailAddress,
                        controller: _emailController,
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Enter your email' : null,
                      ),
                      const SizedBox(height: 16),
                      DebossedField(
                        label: 'Password',
                        icon: Icons.lock_outline,
                        hint: '••••••••',
                        obscureText: true,
                        showVisibilityToggle: true,
                        controller: _passwordController,
                        validator: (v) =>
                            (v == null || v.length < 6) ? 'Minimum 6 characters' : null,
                      ),
                      const SizedBox(height: 16),
                      DebossedField(
                        label: 'Confirm Password',
                        icon: Icons.verified_user_outlined,
                        hint: '••••••••',
                        obscureText: true,
                        controller: _confirmController,
                        validator: (v) =>
                            v != _passwordController.text ? 'Passwords do not match' : null,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Checkbox(
                            value: _agreedToTerms,
                            activeColor: context.colors.primaryContainer,
                            onChanged: (v) => setState(() => _agreedToTerms = v ?? false),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: RichText(
                                text: TextSpan(
                                  style: context.textStyles.labelMd,
                                  children: [
                                    const TextSpan(text: 'I agree to the '),
                                    TextSpan(
                                      text: 'Terms & Conditions',
                                      style: TextStyle(color: context.colors.primary, fontWeight: FontWeight.bold),
                                    ),
                                    const TextSpan(text: ' and '),
                                    TextSpan(
                                      text: 'Privacy Policy',
                                      style: TextStyle(color: context.colors.primary, fontWeight: FontWeight.bold),
                                    ),
                                    const TextSpan(text: '.'),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      PushableButton(
                        label: 'Create Account',
                        icon: Icons.arrow_forward,
                        onPressed: _handleCreateAccount,
                      ),
                      const SizedBox(height: 20),
                      Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Already have an account? ', style: context.textStyles.bodyMd),
                            GestureDetector(
                              onTap: _goToLogin,
                              child: Text(
                                'Login',
                                style: context.textStyles.labelMd.copyWith(
                                  color: context.colors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
