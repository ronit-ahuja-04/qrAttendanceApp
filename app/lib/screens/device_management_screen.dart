import 'package:flutter/material.dart';
import '../ams/api_services.dart';

class DeviceManagementScreen extends StatefulWidget {
  const DeviceManagementScreen({super.key});

  @override
  State<DeviceManagementScreen> createState() => _DeviceManagementScreenState();
}

class _DeviceManagementScreenState extends State<DeviceManagementScreen> {
  final ApiAdminService _adminService = ApiAdminService();
  bool _isLoading = true;
  bool _isLocked = true;
  List<Map<String, dynamic>> _allStudents = [];
  List<Map<String, dynamic>> _filteredStudents = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchData();
    _searchController.addListener(_filterStudents);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
    });
    
    final locked = await _adminService.getDeviceLockStatus();
    final students = await _adminService.getAllStudents();
    
    if (mounted) {
      setState(() {
        _isLocked = locked;
        _allStudents = students;
        _filteredStudents = students;
        _isLoading = false;
      });
    }
  }

  void _filterStudents() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredStudents = _allStudents.where((student) {
        final name = (student['name'] ?? '').toLowerCase();
        final rollNo = (student['rollNo'] ?? '').toLowerCase();
        return name.contains(query) || rollNo.contains(query);
      }).toList();
    });
  }

  Future<void> _toggleLock(bool value) async {
    setState(() {
      _isLocked = value;
    });
    final success = await _adminService.setDeviceLockStatus(value);
    if (!success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update device lock status')),
        );
        setState(() {
          _isLocked = !value; // revert
        });
      }
    }
  }

  Future<void> _unbindStudent(String studentId, String studentName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Unbind'),
        content: Text('Are you sure you want to unbind $studentName? Their current device will be instantly logged out.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Unbind'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final success = await _adminService.unbindStudentDevice(studentId);
    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Successfully unbound $studentName'), backgroundColor: Colors.green),
        );
        _fetchData(); // Refresh list to show updated status
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to unbind $studentName'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Device Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16.0),
                  color: _isLocked ? Colors.red.shade50 : Colors.green.shade50,
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Global Device Lock',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _isLocked 
                                ? 'Locked. Students cannot bind new devices.' 
                                : 'Unlocked. Unbound students can log in and bind new devices.',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _isLocked,
                        onChanged: _toggleLock,
                        activeColor: Colors.red,
                        inactiveThumbColor: Colors.green,
                        inactiveTrackColor: Colors.green.shade200,
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search by Name or Roll No...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    itemCount: _filteredStudents.length,
                    separatorBuilder: (context, index) => const Divider(),
                    itemBuilder: (context, index) {
                      final student = _filteredStudents[index];
                      final isBound = student['deviceId'] != null;
                      
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isBound ? Colors.blue.shade100 : Colors.grey.shade200,
                          child: Icon(
                            isBound ? Icons.smartphone : Icons.phone_android_outlined,
                            color: isBound ? Colors.blue.shade800 : Colors.grey.shade600,
                          ),
                        ),
                        title: Text(student['name'] ?? 'Unknown'),
                        subtitle: Text(student['rollNo'] ?? 'No Roll No'),
                        trailing: isBound 
                          ? IconButton(
                              icon: const Icon(Icons.link_off, color: Colors.red),
                              tooltip: 'Unbind Device',
                              onPressed: () => _unbindStudent(student['id'], student['name']),
                            )
                          : const Chip(
                              label: Text('Unbound', style: TextStyle(fontSize: 10)),
                              backgroundColor: Colors.transparent,
                              side: BorderSide(color: Colors.grey),
                              padding: EdgeInsets.zero,
                            ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
