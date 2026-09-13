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
  final _divisionController = TextEditingController();
  
  bool _isLoading = false;
  bool _isLoadingClass = false;
  
  List<dynamic> _students = [];
  String _currentDivision = '';

  // Quick select divisions
  final List<String> _commonDivisions = ['D10A', 'D15A', 'D15B', 'D15C'];

  Future<void> _unbindDevice(String rollNo, {bool refreshClass = false}) async {
    if (rollNo.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a student Roll Number.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/faculty/unbind-device'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'rollNo': rollNo}),
      );

      final data = jsonDecode(response.body);

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (response.statusCode == 200) {
        if (!refreshClass) {
          _rollNoController.clear();
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? 'Device unbound successfully!'),
            backgroundColor: Colors.green.shade700,
          ),
        );
        
        if (refreshClass && _currentDivision.isNotEmpty) {
          _loadClass(_currentDivision);
        }
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
  
  Future<void> _unbindEntireDivision(String division) async {
    setState(() => _isLoadingClass = true);

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/faculty/unbind-division'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'division': division}),
      );

      final data = jsonDecode(response.body);

      if (!mounted) return;
      setState(() => _isLoadingClass = false);

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? 'Division devices unbound successfully!'),
            backgroundColor: Colors.green.shade700,
          ),
        );
        _loadClass(division);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['error'] ?? 'Failed to unbind division'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingClass = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Network error: $e'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  Future<void> _loadClass(String division) async {
    if (division.isEmpty) return;
    
    setState(() {
      _isLoadingClass = true;
      _currentDivision = division;
      _divisionController.text = division;
    });

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/faculty/students-by-division?division=${Uri.encodeComponent(division)}'),
      );

      if (!mounted) return;
      
      if (response.statusCode == 200) {
        setState(() {
          _students = jsonDecode(response.body);
          _isLoadingClass = false;
        });
      } else {
        setState(() => _isLoadingClass = false);
        final data = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['error'] ?? 'Failed to load class'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingClass = false);
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'UNBIND INDIVIDUAL STUDENT',
                style: context.textStyles.vesitLabelBold.copyWith(letterSpacing: 1.5, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 12),
              VesitCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    VesitTextField(
                      controller: _rollNoController,
                      label: 'Student Roll No',
                      hint: 'e.g., 2022.ronit.ahuja',
                      icon: Icons.person,
                    ),
                    const SizedBox(height: 16),
                    VesitButton(
                      label: 'Unbind Specific Device',
                      onPressed: () => _unbindDevice(_rollNoController.text.trim()),
                      isLoading: _isLoading,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              Text(
                'CLASSROOM DEVICE MANAGEMENT',
                style: context.textStyles.vesitLabelBold.copyWith(letterSpacing: 1.5, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 12),
              VesitCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quick Select Division:',
                      style: context.textStyles.vesitLabelSm.copyWith(color: Colors.grey.shade700),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: _commonDivisions.map((div) {
                        final isSelected = _currentDivision.toUpperCase() == div;
                        return ChoiceChip(
                          label: Text(div),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) _loadClass(div);
                          },
                          selectedColor: context.colors.vesitPrimary.withOpacity(0.2),
                          labelStyle: isSelected 
                            ? TextStyle(color: context.colors.vesitPrimary, fontWeight: FontWeight.bold) 
                            : null,
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: VesitTextField(
                            controller: _divisionController,
                            label: 'Other Division',
                            hint: 'e.g., D15A',
                            icon: Icons.group,
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () => _loadClass(_divisionController.text.trim()),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: context.colors.vesitPrimary,
                            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Icon(Icons.search, color: Colors.white),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              if (_isLoadingClass)
                const Center(child: CircularProgressIndicator())
              else if (_students.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${_currentDivision.toUpperCase()} STUDENTS (${_students.length})',
                          style: context.textStyles.vesitLabelBold.copyWith(letterSpacing: 1.5, color: Colors.grey.shade600),
                        ),
                        TextButton.icon(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Unbind Entire Class?'),
                                content: Text('Are you sure you want to clear device bindings for EVERY student in ${_currentDivision.toUpperCase()}?'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(ctx);
                                      _unbindEntireDivision(_currentDivision);
                                    }, 
                                    child: const Text('Unbind All', style: TextStyle(color: Colors.red)),
                                  ),
                                ],
                              )
                            );
                          },
                          icon: const Icon(Icons.link_off, color: Colors.red, size: 18),
                          label: const Text('Unbind All', style: TextStyle(color: Colors.red)),
                        )
                      ],
                    ),
                    const SizedBox(height: 8),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _students.length,
                      itemBuilder: (context, index) {
                        final student = _students[index];
                        final isBound = student['isBound'] == true;
                        
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(color: Colors.grey.shade300),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: context.colors.vesitPrimary.withOpacity(0.1),
                              child: Text(
                                student['name'].toString().substring(0, 1).toUpperCase(),
                                style: TextStyle(color: context.colors.vesitPrimary),
                              ),
                            ),
                            title: Text(student['name'], style: context.textStyles.vesitBodyMd.copyWith(fontWeight: FontWeight.bold)),
                            subtitle: Text(student['rollNo']),
                            trailing: isBound 
                              ? IconButton(
                                  icon: const Icon(Icons.link_off, color: Colors.red),
                                  tooltip: 'Unbind Device',
                                  onPressed: () => _unbindDevice(student['rollNo'], refreshClass: true),
                                )
                              : const Tooltip(
                                  message: 'No device bound',
                                  child: Icon(Icons.check_circle_outline, color: Colors.green),
                                ),
                          ),
                        );
                      },
                    ),
                  ],
                )
              else if (_currentDivision.isNotEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Text(
                      'No students found in $_currentDivision',
                      style: context.textStyles.vesitBodyMd.copyWith(color: Colors.grey.shade600),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
