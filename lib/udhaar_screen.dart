import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UdhaarScreen extends StatefulWidget {
  const UdhaarScreen({super.key});

  @override
  State<UdhaarScreen> createState() => _UdhaarScreenState();
}

class _UdhaarScreenState extends State<UdhaarScreen> {
  final CollectionReference _customersRef =
      FirebaseFirestore.instance.collection('customers');
  final CollectionReference _invoicesRef =
      FirebaseFirestore.instance.collection('invoices');

  final TextEditingController _searchCtrl = TextEditingController();
  String _search = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _showRecordPayment(String docId, Map<String, dynamic> customer) {
    final amountCtrl = TextEditingController();
    final currentBalance = (customer['balance'] ?? 0) as int;
    final noteCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Record Payment'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Customer info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFCEBEB),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          customer['name'] ?? '',
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          customer['phone'] ?? '',
                          style: const TextStyle(
                              fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('Total Udhaar',
                            style:
                                TextStyle(fontSize: 11, color: Colors.grey)),
                        Text(
                          'Rs $currentBalance',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Payment amount
              const Text('Payment Amount (Rs)',
                  style:
                      TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              TextField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                autofocus: true,
                style: const TextStyle(fontSize: 18),
                decoration: InputDecoration(
                  hintText: '0',
                  prefixText: 'Rs ',
                  filled: true,
                  fillColor: const Color(0xFFF5F5F5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                        color: Color(0xFF1D9E75), width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Quick amount buttons
              const Text('Quick amounts:',
                  style: TextStyle(fontSize: 11, color: Colors.grey)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                children: [
                  _QuickBtn(
                    label: 'Full: Rs $currentBalance',
                    onTap: () => amountCtrl.text = '$currentBalance',
                    color: const Color(0xFF1D9E75),
                  ),
                  if (currentBalance >= 500)
                    _QuickBtn(
                      label: 'Half: Rs ${(currentBalance / 2).round()}',
                      onTap: () => amountCtrl.text =
                          '${(currentBalance / 2).round()}',
                      color: const Color(0xFF3B82F6),
                    ),
                  _QuickBtn(
                    label: 'Rs 1000',
                    onTap: () => amountCtrl.text = '1000',
                    color: Colors.grey,
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Note
              const Text('Note (optional)',
                  style:
                      TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              TextField(
                controller: noteCtrl,
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'e.g. Cash received, Bank transfer...',
                  filled: true,
                  fillColor: const Color(0xFFF5F5F5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton.icon(
            onPressed: () async {
              final amount = int.tryParse(amountCtrl.text) ?? 0;
              if (amount <= 0) return;
              if (amount > currentBalance) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                        'Payment cannot exceed the outstanding balance!'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              // Update customer balance
              await _customersRef.doc(docId).update({
                'balance': FieldValue.increment(-amount),
              });

              // Save payment record in invoices
              await _invoicesRef.add({
                'customerId': docId,
                'customerName': customer['name'],
                'items': [],
                'subtotal': 0,
                'discount': 0,
                'total': amount,
                'paymentMethod': 'Payment Received',
                'status': 'Payment',
                'note': noteCtrl.text,
                'createdAt': FieldValue.serverTimestamp(),
              });

              if (context.mounted) Navigator.pop(context);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        'Rs $amount payment recorded for ${customer['name']}!'),
                    backgroundColor: const Color(0xFF1D9E75),
                    duration: const Duration(seconds: 3),
                  ),
                );
              }
            },
            icon: const Icon(Icons.check, size: 18),
            label: const Text('Record Payment'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1D9E75),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  void _showCustomerInvoices(String docId, String name) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('$name — Invoice History'),
        content: SizedBox(
          width: 500,
          height: 400,
          child: StreamBuilder<QuerySnapshot>(
            stream: _invoicesRef
                .where('customerId', isEqualTo: docId)
                .snapshots(),
            builder: (context, snap) {
              final docs = snap.data?.docs ?? [];
              docs.sort((a, b) {
                final aTs = (a.data() as Map)['createdAt'] as Timestamp?;
                final bTs = (b.data() as Map)['createdAt'] as Timestamp?;
                if (aTs == null || bTs == null) return 0;
                return bTs.compareTo(aTs);
              });

              if (docs.isEmpty) {
                return const Center(
                    child: Text('No invoices found.',
                        style: TextStyle(color: Colors.grey)));
              }

              return ListView.builder(
                itemCount: docs.length,
                itemBuilder: (_, i) {
                  final data = docs[i].data() as Map<String, dynamic>;
                  final status = data['status'] ?? 'Paid';
                  final ts = data['createdAt'] as Timestamp?;
                  final date = ts?.toDate();
                  final dateStr = date != null
                      ? '${date.day}/${date.month}/${date.year}'
                      : '-';
                  final isPayment = status == 'Payment';

                  return Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    margin: const EdgeInsets.only(bottom: 6),
                    decoration: BoxDecoration(
                      color: isPayment
                          ? const Color(0xFFE1F5EE)
                          : const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isPayment
                                  ? '✅ Payment Received'
                                  : '#${docs[i].id.substring(0, 6).toUpperCase()}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isPayment
                                    ? const Color(0xFF085041)
                                    : const Color(0xFF1A1A2E),
                              ),
                            ),
                            Text(dateStr,
                                style: const TextStyle(
                                    fontSize: 11, color: Colors.grey)),
                            if (data['note'] != null &&
                                data['note'].toString().isNotEmpty)
                              Text(data['note'],
                                  style: const TextStyle(
                                      fontSize: 11, color: Colors.grey)),
                          ],
                        ),
                        Text(
                          isPayment
                              ? '+ Rs ${data['total']}'
                              : '- Rs ${data['total']}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: isPayment
                                ? const Color(0xFF1D9E75)
                                : Colors.red,
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
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close')),
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
        title: const Text('Udhaar Report',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _customersRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final allCustomers = snapshot.data?.docs ?? [];

          // Only customers with balance > 0
          final debtors = allCustomers.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final balance = (data['balance'] ?? 0) as int;
            final matchSearch = (data['name'] ?? '')
                .toString()
                .toLowerCase()
                .contains(_search.toLowerCase());
            return balance > 0 && matchSearch;
          }).toList();

          // Sort by highest debt first
          debtors.sort((a, b) {
            final aB = ((a.data() as Map)['balance'] ?? 0) as int;
            final bB = ((b.data() as Map)['balance'] ?? 0) as int;
            return bB.compareTo(aB);
          });

          // Total outstanding
          int totalUdhaar = 0;
          for (final doc in allCustomers) {
            final data = doc.data() as Map<String, dynamic>;
            final balance = (data['balance'] ?? 0) as int;
            if (balance > 0) totalUdhaar += balance;
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Summary cards
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFCEBEB),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.money_off,
                                  color: Colors.red, size: 24),
                            ),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Total Udhaar',
                                    style: TextStyle(
                                        fontSize: 12, color: Colors.grey)),
                                Text(
                                  'Rs $totalUdhaar',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF3CD),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color:
                                    const Color(0xFFF59E0B).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.people_outline,
                                  color: Color(0xFFF59E0B), size: 24),
                            ),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Customers with Udhaar',
                                    style: TextStyle(
                                        fontSize: 12, color: Colors.grey)),
                                Text(
                                  '${debtors.length} customers',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFFF59E0B),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE1F5EE),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color:
                                    const Color(0xFF1D9E75).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.people_outline,
                                  color: Color(0xFF1D9E75), size: 24),
                            ),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Clear Customers',
                                    style: TextStyle(
                                        fontSize: 12, color: Colors.grey)),
                                Text(
                                  '${allCustomers.length - debtors.length} customers',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF1D9E75),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Search
                TextField(
                  controller: _searchCtrl,
                  onChanged: (v) => setState(() => _search = v),
                  decoration: InputDecoration(
                    hintText: 'Search customer...',
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

                // Table header
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
                      Expanded(flex: 1, child: _TH('#')),
                      Expanded(flex: 3, child: _TH('Customer')),
                      Expanded(flex: 2, child: _TH('Phone')),
                      Expanded(flex: 2, child: _TH('City')),
                      Expanded(flex: 2, child: _TH('Total Purchases')),
                      Expanded(flex: 2, child: _TH('Udhaar Amount')),
                      Expanded(flex: 2, child: _TH('')),
                    ],
                  ),
                ),

                // Table rows (no longer wrapped in Expanded — SingleChildScrollView
                // needs unbounded height, so we use shrinkWrap + NeverScrollable
                // and let the outer scroll view handle scrolling)
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                  ),
                  child: debtors.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.symmetric(vertical: 40),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.check_circle_outline,
                                    color: Color(0xFF1D9E75), size: 48),
                                const SizedBox(height: 12),
                                const Text(
                                  'No udhaar! All customers are clear.',
                                  style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF1D9E75)),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _search.isNotEmpty
                                      ? 'No results for "$_search"'
                                      : 'All balances are settled.',
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: debtors.length,
                          itemBuilder: (_, i) {
                            final doc = debtors[i];
                            final c = doc.data() as Map<String, dynamic>;
                            final balance = (c['balance'] ?? 0) as int;
                            final totalPurchases =
                                (c['totalPurchases'] ?? 0) as int;

                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                border: Border(
                                    top: BorderSide(
                                        color: Colors.grey.shade100)),
                                color: i == 0
                                    ? const Color(0xFFFFF8F8)
                                    : Colors.white,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 1,
                                    child: Container(
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        color: i == 0
                                            ? Colors.red
                                            : const Color(0xFFEEEEEE),
                                        borderRadius:
                                            BorderRadius.circular(20),
                                      ),
                                      child: Center(
                                        child: Text(
                                          '${i + 1}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: i == 0
                                                ? Colors.white
                                                : Colors.grey,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: Text(c['name'] ?? '',
                                        style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500)),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(c['phone'] ?? '',
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey)),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(c['city'] ?? '',
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey)),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text('Rs $totalPurchases',
                                        style:
                                            const TextStyle(fontSize: 13)),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      'Rs $balance',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.red,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Row(
                                      children: [
                                        ElevatedButton(
                                          onPressed: () =>
                                              _showRecordPayment(doc.id, c),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                const Color(0xFF1D9E75),
                                            foregroundColor: Colors.white,
                                            padding:
                                                const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 6),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                          ),
                                          child: const Text('Pay',
                                              style: TextStyle(fontSize: 12)),
                                        ),
                                        const SizedBox(width: 6),
                                        IconButton(
                                          icon: const Icon(Icons.history,
                                              size: 18, color: Colors.grey),
                                          tooltip: 'View History',
                                          onPressed: () =>
                                              _showCustomerInvoices(
                                                  doc.id, c['name'] ?? ''),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
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

class _QuickBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final Color color;
  const _QuickBtn(
      {required this.label, required this.onTap, required this.color});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 11, color: color, fontWeight: FontWeight.w600)),
      ),
    );
  }
}