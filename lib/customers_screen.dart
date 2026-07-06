import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  final CollectionReference _customersRef =
      FirebaseFirestore.instance.collection('customers');

  String _search = '';

  void _showAddCustomer() {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final cityCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    final balanceCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Add New Customer'),
        content: SizedBox(
          width: 400,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _Field(ctrl: nameCtrl, label: 'Business / Customer Name'),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: _Field(ctrl: phoneCtrl, label: 'Phone')),
                  const SizedBox(width: 12),
                  Expanded(child: _Field(ctrl: cityCtrl, label: 'City')),
                ]),
                const SizedBox(height: 12),
                _Field(ctrl: addressCtrl, label: 'Address'),
                const SizedBox(height: 12),
                _Field(
                    ctrl: balanceCtrl,
                    label: 'Opening Balance (Credit, if any)',
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
              await _customersRef.add({
                'name': nameCtrl.text,
                'phone': phoneCtrl.text,
                'city': cityCtrl.text,
                'address': addressCtrl.text,
                'balance': int.tryParse(balanceCtrl.text) ?? 0,
                'totalPurchases': 0,
                'createdAt': FieldValue.serverTimestamp(),
              });
              if (context.mounted) Navigator.pop(context);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Customer added successfully!'),
                    backgroundColor: Color(0xFF1D9E75),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1D9E75),
              foregroundColor: Colors.white,
            ),
            child: const Text('Save Customer'),
          ),
        ],
      ),
    );
  }

  void _showEditCustomer(String docId, Map<String, dynamic> customer) {
    final nameCtrl = TextEditingController(text: customer['name']);
    final phoneCtrl = TextEditingController(text: customer['phone']);
    final cityCtrl = TextEditingController(text: customer['city']);
    final addressCtrl = TextEditingController(text: customer['address']);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Edit Customer'),
        content: SizedBox(
          width: 400,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _Field(ctrl: nameCtrl, label: 'Business / Customer Name'),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: _Field(ctrl: phoneCtrl, label: 'Phone')),
                  const SizedBox(width: 12),
                  Expanded(child: _Field(ctrl: cityCtrl, label: 'City')),
                ]),
                const SizedBox(height: 12),
                _Field(ctrl: addressCtrl, label: 'Address'),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await _customersRef.doc(docId).delete();
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await _customersRef.doc(docId).update({
                'name': nameCtrl.text,
                'phone': phoneCtrl.text,
                'city': cityCtrl.text,
                'address': addressCtrl.text,
              });
              if (context.mounted) Navigator.pop(context);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Customer updated!'),
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

  void _showRecordPayment(String docId, Map<String, dynamic> customer) {
    final amountCtrl = TextEditingController();
    final currentBalance = (customer['balance'] ?? 0) as int;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Record Payment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${customer['name']}',
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('Current balance owed: Rs $currentBalance',
                style: const TextStyle(fontSize: 13, color: Colors.red)),
            const SizedBox(height: 16),
            _Field(
                ctrl: amountCtrl,
                label: 'Payment Amount (Rs)',
                isNumber: true),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final amount = int.tryParse(amountCtrl.text) ?? 0;
              if (amount <= 0) return;
              await _customersRef.doc(docId).update({
                'balance': FieldValue.increment(-amount),
              });
              if (context.mounted) Navigator.pop(context);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Payment of Rs $amount recorded!'),
                    backgroundColor: const Color(0xFF1D9E75),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1D9E75),
              foregroundColor: Colors.white,
            ),
            child: const Text('Record Payment'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Customers',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ElevatedButton.icon(
              onPressed: _showAddCustomer,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Customer'),
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
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              onChanged: (v) => setState(() => _search = v),
              decoration: InputDecoration(
                hintText: 'Search customers...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                  Expanded(flex: 2, child: _TH('Phone')),
                  Expanded(flex: 2, child: _TH('City')),
                  Expanded(flex: 2, child: _TH('Total Purchases')),
                  Expanded(flex: 2, child: _TH('Balance')),
                  Expanded(flex: 2, child: _TH('')),
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
                child: StreamBuilder<QuerySnapshot>(
                  stream: _customersRef.snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final docs = snapshot.data?.docs ?? [];
                    final filtered = docs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return (data['name'] ?? '')
                          .toString()
                          .toLowerCase()
                          .contains(_search.toLowerCase());
                    }).toList();

                    if (filtered.isEmpty) {
                      return const Center(
                        child: Text(
                            'No customers yet. Click "Add Customer" to start!',
                            style: TextStyle(color: Colors.grey)),
                      );
                    }

                    return ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (_, i) {
                        final doc = filtered[i];
                        final c = doc.data() as Map<String, dynamic>;
                        final balance = (c['balance'] ?? 0) as int;
                        final totalPurchases =
                            (c['totalPurchases'] ?? 0) as int;
                        final hasDebt = balance > 0;
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            border:
                                Border(top: BorderSide(color: Colors.grey.shade100)),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                  flex: 3,
                                  child: Text(c['name'] ?? '',
                                      style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500))),
                              Expanded(
                                  flex: 2,
                                  child: Text(c['phone'] ?? '',
                                      style: const TextStyle(
                                          fontSize: 13, color: Colors.grey))),
                              Expanded(
                                  flex: 2,
                                  child: Text(c['city'] ?? '',
                                      style: const TextStyle(
                                          fontSize: 13, color: Colors.grey))),
                              Expanded(
                                  flex: 2,
                                  child: Text('Rs $totalPurchases',
                                      style: const TextStyle(fontSize: 13))),
                              Expanded(
                                flex: 2,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: hasDebt
                                        ? const Color(0xFFFCEBEB)
                                        : const Color(0xFFE1F5EE),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    hasDebt ? 'Rs $balance due' : 'Clear',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: hasDebt
                                          ? const Color(0xFF501313)
                                          : const Color(0xFF085041),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Row(
                                  children: [
                                    if (hasDebt)
                                      TextButton(
                                        onPressed: () =>
                                            _showRecordPayment(doc.id, c),
                                        child: const Text('Pay',
                                            style: TextStyle(fontSize: 12)),
                                      ),
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined,
                                          size: 18, color: Colors.grey),
                                      onPressed: () =>
                                          _showEditCustomer(doc.id, c),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
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