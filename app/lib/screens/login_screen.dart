import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/tactile_widgets.dart';
import 'registration_screen.dart';
import 'faculty_dashboard_screen.dart';
import 'student_dashboard_screen.dart';
import 'change_password_screen.dart';
import '../ams/globals.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  UserRole _role = UserRole.student;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool _isLoading = false;

  void _handleSignIn() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final user = await AmsGlobals.sessionService.login(
      _emailController.text.trim(),
      _passwordController.text,
    );

    setState(() => _isLoading = false);

    if (user != null) {
      if (user.role != _role.name) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Account is registered as ${user.role}, not ${_role.name}.')),
        );
        return;
      }
      AmsGlobals.loggedInUser = user;
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => user.role == 'student'
              ? const StudentDashboardScreen()
              : const FacultyDashboardScreen(),
        ),
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid email or password.')),
      );
    }
  }

  void _goToRegistration() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => RegistrationScreen(role: _role)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.wall,
      appBar: const TactileAppBar(),
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('ACCESS NODE', style: AppTextStyles.headlineSm),
                          const LedDot(active: true),
                        ],
                      ),
                      const SizedBox(height: 16),
                      RoleToggle(
                        value: _role,
                        onChanged: (r) => setState(() => _role = r),
                      ),
                      const SizedBox(height: 24),
                      DebossedField(
                        label: 'Email Address',
                        icon: Icons.alternate_email,
                        hint: 'user@vesit.edu',
                        keyboardType: TextInputType.emailAddress,
                        controller: _emailController,
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Enter your email' : null,
                      ),
                      const SizedBox(height: 16),
                      DebossedField(
                        label: 'Security Key',
                        icon: Icons.lock_outline,
                        hint: '••••••••',
                        obscureText: true,
                        showVisibilityToggle: true,
                        controller: _passwordController,
                        validator: (v) =>
                            (v == null || v.isEmpty) ? 'Enter your password' : null,
                      ),
                      const SizedBox(height: 24),
                      _isLoading 
                          ? const Center(child: CircularProgressIndicator())
                          : PushableButton(label: 'Sign In', onPressed: _handleSignIn),
                      const SizedBox(height: 20),
                      Center(
                        child: Column(
                          children: [
                            GestureDetector(
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
                              ),
                              child: Text('Forgot Password?', style: AppTextStyles.labelMd),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text("Don't have an account? ", style: AppTextStyles.labelMd),
                                GestureDetector(
                                  onTap: _goToRegistration,
                                  child: Text(
                                    'Create one',
                                    style: AppTextStyles.labelMd.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
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
