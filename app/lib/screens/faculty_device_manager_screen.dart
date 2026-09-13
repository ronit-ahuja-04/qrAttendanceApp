import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/vesit_widgets.dart';
import '../ams/api_services.dart';

class FacultyDeviceManagerScreen extends StatefulWidget {
  const FacultyDeviceManagerScreen({super.key});

  @override
  State<FacultyDeviceManagerScreen> createState() => _FacultyDeviceManagerScreenState();
}

class _FacultyDeviceManagerScreenState extends State<FacultyDeviceManagerScreen> {
  final _rollNoController = TextEditingController();
  bool _isLoading = false;

  Future<void> _unbindDevice() async {
    final rollNo = _rollNoController.text.trim().toUpperCase();
    if (rollNo.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a student Roll Number.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('${ApiSessionService().baseUrl}/api/faculty/unbind-device'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'rollNo': rollNo}),
      );

      final data = jsonDecode(response.body);

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (response.statusCode == 200) {
        _rollNoController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? 'Device unbound successfully!'),
            backgroundColor: Colors.green.shade700,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['error'] ?? 'Failed to unbind device'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Network error: $e'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.vesitGray,
      appBar: AppBar(
        title: Text('Device Management', style: context.textStyles.vesitHeadlineSm.copyWith(color: context.colors.vesitPrimary)),
        backgroundColor: context.colors.vesitWhite,
        iconTheme: IconThemeData(color: context.colors.vesitPrimary),
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'UNBIND STUDENT DEVICE',
                style: context.textStyles.vesitLabelBold.copyWith(letterSpacing: 1.5, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 16),
              VesitCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      'Enter the student\'s Roll Number below to instantly clear their device binding. This will allow them to log into a new device.',
                      style: context.textStyles.vesitBodyMd,
                    ),
                    const SizedBox(height: 24),
                    VesitTextField(
                      controller: _rollNoController,
                      label: 'Student Roll No',
                      hint: 'e.g., 2022.ronit.ahuja',
                      icon: Icons.person_search,
                    ),
                    const SizedBox(height: 24),
                    VesitButton(
                      label: 'Unbind Device',
                      onPressed: _unbindDevice,
                      isLoading: _isLoading,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
