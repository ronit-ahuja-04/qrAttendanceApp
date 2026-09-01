import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/vesit_widgets.dart';
import '../widgets/vesit_loader.dart';
import 'faculty_main_layout.dart';
import 'student_main_layout.dart';
import 'change_password_screen.dart';
import 'forgot_password_screen.dart';
import '../ams/globals.dart';
import '../ams/api_services.dart';
import '../ams/notification_service.dart';
import '../routes/fade_blur_route.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'dart:ui';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _role = 'student';
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleSignIn() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 50)); // Force Flutter to paint the loading frame

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final user = await AmsGlobals.sessionService.login(
      email,
      password,
    );
    await Future.delayed(const Duration(milliseconds: 1500));


    if (user != null) {
      if (user.role != _role) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Role mismatch: This is a ${user.role} account. Please select ${user.role.toUpperCase()} above!',
              style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
            ),
            backgroundColor: context.colors.vesitGold,
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            margin: const EdgeInsets.only(bottom: 20, left: 16, right: 16),
          ),
        );
        return;
      }
      AmsGlobals.loggedInUser = user;
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('ams_user_session', jsonEncode(user.toJson()));
      
      final pushEnabled = prefs.getBool('notif_master') ?? true;
      
      if (pushEnabled) {
        try {
          final freshToken = await FirebaseMessaging.instance.getToken();
          if (freshToken != null) {
            NotificationService().currentToken = freshToken;
            ApiSessionService().updateFcmToken(user.id, freshToken);
          }
        } catch (e) {
          print('Error getting fresh token: $e');
        }
      }
      
      // Sync granular preferences to backend
      ApiSessionService().updateNotificationPrefs(
        user.id,
        {
          'notif_master': pushEnabled,
          'notif_alerts': prefs.getBool('notif_alerts') ?? true,
          'notif_proxy': prefs.getBool('notif_proxy') ?? true,
          'notif_attendance': prefs.getBool('notif_attendance') ?? true,
        }
      );
      
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        FadeBlurPageRoute(
          page: user.role == 'student'
              ? const StudentMainLayout()
              : const FacultyMainLayout(),
        ),
      );
    } else {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Login failed! Check your password, role, or connection.',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          ),
          backgroundColor: context.colors.vesitGold,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          margin: const EdgeInsets.only(bottom: 20, left: 16, right: 16),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 600;
    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
    
    return Scaffold(
      backgroundColor: context.colors.vesitWhite,
      body: Stack(
        children: [
          // Main content
          Column(
            children: [
                // Header
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                  height: isKeyboardOpen 
                      ? MediaQuery.of(context).size.height * 0.15 // Shrink header when keyboard is open
                      : MediaQuery.of(context).size.height * (isDesktop ? 0.25 : 0.30),
                  child: Container(
                    width: double.infinity,
                    color: context.colors.vesitPrimary,
                    child: SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
                        child: AnimatedCrossFade(
                          duration: const Duration(milliseconds: 300),
                          crossFadeState: (!isDesktop && isKeyboardOpen) 
                              ? CrossFadeState.showSecond 
                              : CrossFadeState.showFirst,
                          layoutBuilder: (Widget topChild, Key topChildKey, Widget bottomChild, Key bottomChildKey) {
                            return Stack(
                              clipBehavior: Clip.none,
                              alignment: Alignment.center,
                              children: <Widget>[
                                Positioned(
                                  key: bottomChildKey,
                                  top: 0,
                                  child: bottomChild,
                                ),
                                Positioned(
                                  key: topChildKey,
                                  child: topChild,
                                ),
                              ],
                            );
                          },
                          firstChild: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Image.asset(
                                  'assets/images/logo.png',
                                  height: 80,
                                  fit: BoxFit.contain,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'VIVEKANAND EDUCATION SOCIETY\'S',
                                  style: context.textStyles.vesitHeadlineSm.copyWith(color: context.colors.vesitWhite, letterSpacing: 1.5),
                                  textAlign: TextAlign.center,
                                ),
                                Text(
                                  'INSTITUTE OF TECHNOLOGY',
                                  style: context.textStyles.vesitHeadlineMd.copyWith(color: context.colors.vesitGold),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                          secondChild: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Image.asset(
                                  'assets/images/logo.png',
                                  height: 60,
                                  fit: BoxFit.contain,
                                ),
                                const SizedBox(width: 16),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'VIVEKANAND EDUCATION SOCIETY\'S',
                                      style: context.textStyles.vesitHeadlineSm.copyWith(color: context.colors.vesitWhite, letterSpacing: 1.5),
                                    ),
                                    Text(
                                      'INSTITUTE OF TECHNOLOGY',
                                      style: context.textStyles.vesitHeadlineMd.copyWith(color: context.colors.vesitGold),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // Body form
                Expanded(
                  child: SingleChildScrollView(
                    physics: isDesktop ? const NeverScrollableScrollPhysics() : const AlwaysScrollableScrollPhysics(),
                    child: SafeArea(
                      top: false,
                      child: AnimatedPadding(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                        padding: EdgeInsets.only(
                          top: isKeyboardOpen ? 4 : 12, 
                          bottom: isKeyboardOpen ? 20 : 60, 
                          left: isDesktop ? 24 : 12, 
                          right: isDesktop ? 24 : 12
                        ),
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 400),
                            child: VesitCard(
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Center(
                                      child: Text(
                                        'ACCOUNT LOGIN',
                                        style: context.textStyles.vesitHeadlineMd,
                                      ),
                                    ),
                                    AnimatedContainer(
                                      duration: const Duration(milliseconds: 300),
                                      curve: Curves.easeOut,
                                      height: isKeyboardOpen ? 12 : 24,
                                    ),
                                    VesitRoleToggle(
                                      value: _role,
                                      onChanged: (r) => setState(() => _role = r),
                                    ),
                                    AnimatedContainer(
                                      duration: const Duration(milliseconds: 300),
                                      curve: Curves.easeOut,
                                      height: isKeyboardOpen ? 12 : 24,
                                    ),
                                    VesitTextField(
                                      label: 'Email Address',
                                      icon: Icons.alternate_email,
                                      hint: 'user@ves.ac.in',
                                      keyboardType: TextInputType.emailAddress,
                                      controller: _emailController,
                                      onFieldSubmitted: (_) => _handleSignIn(),
                                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter your email' : null,
                                    ),
                                    AnimatedContainer(
                                      duration: const Duration(milliseconds: 300),
                                      curve: Curves.easeOut,
                                      height: isKeyboardOpen ? 8 : 16,
                                    ),
                                    VesitTextField(
                                      label: 'Password',
                                      icon: Icons.lock_outline,
                                      hint: '••••••••',
                                      obscureText: true,
                                      showVisibilityToggle: true,
                                      controller: _passwordController,
                                      onFieldSubmitted: (_) => _handleSignIn(),
                                      validator: (v) => (v == null || v.isEmpty) ? 'Enter your password' : null,
                                    ),
                                    AnimatedContainer(
                                      duration: const Duration(milliseconds: 300),
                                      curve: Curves.easeOut,
                                      height: isKeyboardOpen ? 16 : 32,
                                    ),
                                    VesitButton(
                                      label: 'Sign In',
                                      onPressed: _handleSignIn,
                                      isLoading: _isLoading,
                                    ),
                                    AnimatedContainer(
                                      duration: const Duration(milliseconds: 300),
                                      curve: Curves.easeOut,
                                      height: isKeyboardOpen ? 12 : 20,
                                    ),
                                    Center(
                                      child: MouseRegion(
                                        cursor: SystemMouseCursors.click,
                                        child: GestureDetector(
                                          onTap: () => Navigator.of(context).push(
                                            MaterialPageRoute(builder: (_) => ForgotPasswordScreen()),
                                          ),
                                          child: Text('Forgot Password?', style: context.textStyles.vesitBodyMd.copyWith(
                                            color: context.colors.vesitPrimary,
                                            decoration: TextDecoration.underline,
                                          )),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ), // SafeArea
                  ), // SingleChildScrollView
                ), // Expanded
              ], // Column children
            ), // Column
          // Loading overlay with blur
          if (_isLoading)
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                child: Container(
                  color: Colors.black.withOpacity(0.4),
                  alignment: Alignment.center,
                  child: const VesitSwirlingLoader(size: 80),
                ),
              ),
            ),
        ],
      ),
);
  }
}
