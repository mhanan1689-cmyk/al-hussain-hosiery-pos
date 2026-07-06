import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StaffScreen extends StatefulWidget {
  const StaffScreen({super.key});

  @override
  State<StaffScreen> createState() => _StaffScreenState();
}

class _StaffScreenState extends State<StaffScreen> {
  final CollectionReference _staffRef =
      FirebaseFirestore.instance.collection('staff');
  final CollectionReference _attendanceRef =
      FirebaseFirestore.instance.collection('attendance');

  String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  String _monthPrefix() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}';
  }

  void _showAddStaff() {
    final nameCtrl = TextEditingController();
    final roleCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final salaryCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Add Staff Member'),
        content: SizedBox(
          width: 400,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _Field(ctrl: nameCtrl, label: 'Name'),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: _Field(ctrl: roleCtrl, label: 'Role')),
                  const SizedBox(width: 12),
                  Expanded(child: _Field(ctrl: phoneCtrl, label: 'Phone')),
                ]),
                const SizedBox(height: 12),
                _Field(
                    ctrl: salaryCtrl,
                    label: 'Monthly Salary (Rs)',
                    isNumber: true),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.isEmpty) return;
              await _staffRef.add({
                'name': nameCtrl.text,
                'role': roleCtrl.text,
                'phone': phoneCtrl.text,
                'salary': int.tryParse(salaryCtrl.text) ?? 0,
                'createdAt': FieldValue.serverTimestamp(),
              });
              if (context.mounted) Navigator.pop(context);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Staff member added!'),
                    backgroundColor: Color(0xFF1D9E75),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1D9E75),
              foregroundColor: Colors.white,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showEditStaff(String docId, Map<String, dynamic> staff) {
    final nameCtrl = TextEditingController(text: staff['name']);
    final roleCtrl = TextEditingController(text: staff['role']);
    final phoneCtrl = TextEditingController(text: staff['phone']);
    final salaryCtrl =
        TextEditingController(text: staff['salary'].toString());

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Edit Staff Member'),
        content: SizedBox(
          width: 400,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _Field(ctrl: nameCtrl, label: 'Name'),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: _Field(ctrl: roleCtrl, label: 'Role')),
                  const SizedBox(width: 12),
                  Expanded(child: _Field(ctrl: phoneCtrl, label: 'Phone')),
                ]),
                const SizedBox(height: 12),
                _Field(
                    ctrl: salaryCtrl,
                    label: 'Monthly Salary (Rs)',
                    isNumber: true),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await _staffRef.doc(docId).delete();
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await _staffRef.doc(docId).update({
                'name': nameCtrl.text,
                'role': roleCtrl.text,
                'phone': phoneCtrl.text,
                'salary': int.tryParse(salaryCtrl.text) ?? 0,
              });
              if (context.mounted) Navigator.pop(context);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Updated!'),
                    backgroundColor: Color(0xFF1D9E75),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1D9E75),
              foregroundColor: Colors.white,
            ),
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  Future<void> _markAttendance(String staffId, String staffName, bool present) async {
    final docId = '${staffId}_${_todayKey()}';
    await _attendanceRef.doc(docId).set({
      'staffId': staffId,
      'staffName': staffName,
      'date': _todayKey(),
      'present': present,
      'markedAt': FieldValue.serverTimestamp(),
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$staffName marked as ${present ? "Present" : "Absent"}'),
          backgroundColor: present ? const Color(0xFF1D9E75) : Colors.red,
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Staff',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ElevatedButton.icon(
              onPressed: _showAddStaff,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Staff'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1D9E75),
                foregroundColor: Colors.white,
                shape:
                    RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _staffRef.snapshots(),
        builder: (context, staffSnap) {
          if (staffSnap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final staffList = staffSnap.data?.docs ?? [];

          if (staffList.isEmpty) {
            return const Center(
              child: Text('No staff added yet. Click "Add Staff" to start!',
                  style: TextStyle(color: Colors.grey)),
            );
          }

          return StreamBuilder<QuerySnapshot>(
            stream: _attendanceRef
                .where('date', isGreaterThanOrEqualTo: '${_monthPrefix()}-01')
                .where('date', isLessThanOrEqualTo: '${_monthPrefix()}-31')
                .snapshots(),
            builder: (context, attSnap) {
              final attendanceDocs = attSnap.data?.docs ?? [];

              
              Map<String, int> presentCount = {};
              Map<String, int> totalMarked = {};
              Map<String, bool?> todayStatus = {};
              final today = _todayKey();

              for (final doc in attendanceDocs) {
                final data = doc.data() as Map<String, dynamic>;
                final staffId = data['staffId'] as String;
                final present = data['present'] as bool;
                final date = data['date'] as String;

                totalMarked[staffId] = (totalMarked[staffId] ?? 0) + 1;
                if (present) {
                  presentCount[staffId] = (presentCount[staffId] ?? 0) + 1;
                }
                if (date == today) {
                  todayStatus[staffId] = present;
                }
              }

              return Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                        ),
                      ),
                      child: const Row(
                        children: [
                          Expanded(flex: 3, child: _TH('Name')),
                          Expanded(flex: 2, child: _TH('Role')),
                          Expanded(flex: 2, child: _TH('Phone')),
                          Expanded(flex: 2, child: _TH('Salary')),
                          Expanded(flex: 2, child: _TH('Today')),
                          Expanded(flex: 2, child: _TH('This Month')),
                          Expanded(flex: 1, child: _TH('')),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(12),
                            bottomRight: Radius.circular(12),
                          ),
                        ),
                        child: ListView.builder(
                          itemCount: staffList.length,
                          itemBuilder: (_, i) {
                            final doc = staffList[i];
                            final s = doc.data() as Map<String, dynamic>;
                            final status = todayStatus[doc.id];
                            final present = presentCount[doc.id] ?? 0;
                            final marked = totalMarked[doc.id] ?? 0;

                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                border: Border(
                                    top: BorderSide(
                                        color: Colors.grey.shade100)),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                      flex: 3,
                                      child: Text(s['name'] ?? '',
                                          style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500))),
                                  Expanded(
                                      flex: 2,
                                      child: Text(s['role'] ?? '',
                                          style: const TextStyle(
                                              fontSize: 13,
                                              color: Colors.grey))),
                                  Expanded(
                                      flex: 2,
                                      child: Text(s['phone'] ?? '',
                                          style: const TextStyle(
                                              fontSize: 13,
                                              color: Colors.grey))),
                                  Expanded(
                                      flex: 2,
                                      child: Text('Rs ${s['salary'] ?? 0}',
                                          style:
                                              const TextStyle(fontSize: 13))),
                                  Expanded(
                                    flex: 2,
                                    child: Row(
                                      children: [
                                        GestureDetector(
                                          onTap: () => _markAttendance(
                                              doc.id, s['name'] ?? '', true),
                                          child: Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              color: status == true
                                                  ? const Color(0xFF1D9E75)
                                                  : const Color(0xFFEEEEEE),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Icon(Icons.check,
                                                size: 16,
                                                color: status == true
                                                    ? Colors.white
                                                    : Colors.grey),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        GestureDetector(
                                          onTap: () => _markAttendance(
                                              doc.id, s['name'] ?? '', false),
                                          child: Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              color: status == false
                                                  ? Colors.red
                                                  : const Color(0xFFEEEEEE),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Icon(Icons.close,
                                                size: 16,
                                                color: status == false
                                                    ? Colors.white
                                                    : Colors.grey),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text('$present / $marked days',
                                        style: const TextStyle(fontSize: 12)),
                                  ),
                                  Expanded(
                                    flex: 1,
                                    child: IconButton(
                                      icon: const Icon(Icons.edit_outlined,
                                          size: 18, color: Colors.grey),
                                      onPressed: () =>
                                          _showEditStaff(doc.id, s),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _TH extends StatelessWidget {
  final String text;
  const _TH(this.text);
  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: const TextStyle(
            fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600));
  }
}

class _Field extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final bool isNumber;
  const _Field({required this.ctrl, required this.label, this.isNumber = false});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: ctrl,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 13),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
    );
  }
}