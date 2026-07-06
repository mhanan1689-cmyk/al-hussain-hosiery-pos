import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class InvoicesScreen extends StatefulWidget {
  const InvoicesScreen({super.key});

  @override
  State<InvoicesScreen> createState() => _InvoicesScreenState();
}

class _InvoicesScreenState extends State<InvoicesScreen> {
  final CollectionReference _invoicesRef =
      FirebaseFirestore.instance.collection('invoices');

  String _search = '';
  String _statusFilter = 'All';
  String _periodFilter = 'All Time';

  final List<String> _statuses = ['All', 'Paid', 'Credit', 'Online'];
  final List<String> _periods = [
    'Today', 'This Week', 'This Month', 'This Year', 'All Time'
  ];

  DateTime _periodStart() {
    final now = DateTime.now();
    switch (_periodFilter) {
      case 'Today':
        return DateTime(now.year, now.month, now.day);
      case 'This Week':
        return now.subtract(Duration(days: now.weekday - 1));
      case 'This Month':
        return DateTime(now.year, now.month, 1);
      case 'This Year':
        return DateTime(now.year, 1, 1);
      default:
        return DateTime(2000);
    }
  }

  void _showInvoiceDetail(String docId, Map<String, dynamic> invoice) {
    final items = invoice['items'] as List<dynamic>? ?? [];
    final status = invoice['status'] ?? 'Paid';
    final isPaid = status == 'Paid';
    final isOnline = status == 'Online';
    final dateTime = (invoice['createdAt'] as Timestamp?)?.toDate();
    final dateStr = dateTime != null
        ? '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}'
        : 'Unknown date';

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Invoice #${docId.substring(0, 6).toUpperCase()}'),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isPaid
                    ? const Color(0xFFE1F5EE)
                    : isOnline
                        ? const Color(0xFFE8F0FE)
                        : const Color(0xFFFFF3CD),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                status,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isPaid
                      ? const Color(0xFF085041)
                      : isOnline
                          ? const Color(0xFF1A56DB)
                          : const Color(0xFF7D4E00),
                ),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 460,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Invoice info
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      _DetailRow(
                          label: 'Customer',
                          value: invoice['customerName'] ?? 'Walk-in'),
                      const SizedBox(height: 6),
                      _DetailRow(label: 'Date', value: dateStr),
                      const SizedBox(height: 6),
                      _DetailRow(
                          label: 'Payment',
                          value: invoice['paymentMethod'] ?? 'Cash'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Items
                const Text('Items',
                    style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                ...items.map((item) {
                  final i = item as Map<String, dynamic>;
                  final qty = (i['qty'] ?? 0) as int;
                  final price = (i['price'] ?? 0) as int;
                  final itemTotal = qty * price;
                  return Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    margin: const EdgeInsets.only(bottom: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border:
                          Border.all(color: Colors.grey.shade100),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(i['name'] ?? '',
                              style: const TextStyle(fontSize: 13)),
                        ),
                        Text('$qty × Rs $price',
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey)),
                        const SizedBox(width: 12),
                        Text('Rs $itemTotal',
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  );
                }),

                const Divider(height: 24),

                // Totals
                _DetailRow(
                    label: 'Subtotal',
                    value: 'Rs ${invoice['subtotal'] ?? 0}'),
                if ((invoice['discount'] ?? 0) > 0) ...[
                  const SizedBox(height: 6),
                  _DetailRow(
                    label:
                        'Discount (${(invoice['discount'] ?? 0).toStringAsFixed(0)}%)',
                    value:
                        '- Rs ${(invoice['subtotal'] ?? 0) - (invoice['total'] ?? 0)}',
                    valueColor: Colors.red,
                  ),
                ],
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE1F5EE),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('TOTAL',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF085041))),
                      Text('Rs ${invoice['total'] ?? 0}',
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1D9E75))),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final periodStart = _periodStart();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Invoice History',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        actions: [
          // Period filter
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: DropdownButton<String>(
              value: _periodFilter,
              underline: const SizedBox(),
              items: _periods
                  .map((p) => DropdownMenuItem(
                      value: p,
                      child: Text(p,
                          style: const TextStyle(fontSize: 13))))
                  .toList(),
              onChanged: (v) => setState(() => _periodFilter = v!),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Search and status filter
            Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (v) => setState(() => _search = v),
                    decoration: InputDecoration(
                      hintText:
                          'Search by customer name or invoice number...',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ...(_statuses.map((s) {
                  final selected = _statusFilter == s;
                  return GestureDetector(
                    onTap: () => setState(() => _statusFilter = s),
                    child: Container(
                      margin: const EdgeInsets.only(left: 6),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: selected
                            ? const Color(0xFF1D9E75)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        s,
                        style: TextStyle(
                          fontSize: 12,
                          color: selected ? Colors.white : Colors.grey,
                          fontWeight: selected
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                })),
              ],
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
                  Expanded(flex: 2, child: _TH('Invoice #')),
                  Expanded(flex: 3, child: _TH('Customer')),
                  Expanded(flex: 2, child: _TH('Date')),
                  Expanded(flex: 1, child: _TH('Items')),
                  Expanded(flex: 2, child: _TH('Total')),
                  Expanded(flex: 2, child: _TH('Payment')),
                  Expanded(flex: 1, child: _TH('Status')),
                  Expanded(flex: 1, child: _TH('')),
                ],
              ),
            ),

            // Invoice list
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
                  stream: _invoicesRef
                      .orderBy('createdAt', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(
                          child: Text('Error: ${snapshot.error}'));
                    }
                    if (snapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(
                          child: CircularProgressIndicator());
                    }

                    final allDocs = snapshot.data?.docs ?? [];

                    // Filter
                    final filtered = allDocs.where((doc) {
                      final data =
                          doc.data() as Map<String, dynamic>;
                      final ts = data['createdAt'] as Timestamp?;
                      final date = ts?.toDate();

                      // Period filter
                      if (date != null &&
                          date.isBefore(periodStart)) {
                        return false;
                      }

                      // Status filter
                      if (_statusFilter != 'All' &&
                          data['status'] != _statusFilter) {
                        return false;
                      }

                      // Search filter
                      if (_search.isNotEmpty) {
                        final customer = (data['customerName'] ?? '')
                            .toString()
                            .toLowerCase();
                        final invoiceId =
                            doc.id.toLowerCase();
                        if (!customer.contains(
                                _search.toLowerCase()) &&
                            !invoiceId.contains(
                                _search.toLowerCase())) {
                          return false;
                        }
                      }
                      return true;
                    }).toList();

                    // Calculate totals
                    int grandTotal = 0;
                    for (final doc in filtered) {
                      final data =
                          doc.data() as Map<String, dynamic>;
                      grandTotal += (data['total'] ?? 0) as int;
                    }

                    if (filtered.isEmpty) {
                      return const Center(
                        child: Text('No invoices found.',
                            style: TextStyle(color: Colors.grey)),
                      );
                    }

                    return Column(
                      children: [
                        Expanded(
                          child: ListView.builder(
                            itemCount: filtered.length,
                            itemBuilder: (_, i) {
                              final doc = filtered[i];
                              final data = doc.data()
                                  as Map<String, dynamic>;
                              final status =
                                  data['status'] ?? 'Paid';
                              final isPaid = status == 'Paid';
                              final isOnline =
                                  status == 'Online';
                              final items = data['items']
                                      as List<dynamic>? ??
                                  [];
                              final ts = data['createdAt']
                                  as Timestamp?;
                              final date = ts?.toDate();
                              final dateStr = date != null
                                  ? '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}'
                                  : '-';

                              return GestureDetector(
                                onTap: () => _showInvoiceDetail(
                                    doc.id, data),
                                child: Container(
                                  padding:
                                      const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 12),
                                  decoration: BoxDecoration(
                                    border: Border(
                                      top: BorderSide(
                                          color: Colors
                                              .grey.shade100),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          '#${doc.id.substring(0, 6).toUpperCase()}',
                                          style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight:
                                                  FontWeight.w600,
                                              color: Color(
                                                  0xFF1D9E75)),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 3,
                                        child: Text(
                                          data['customerName'] ??
                                              'Walk-in',
                                          style: const TextStyle(
                                              fontSize: 13),
                                          overflow:
                                              TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Text(dateStr,
                                            style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey)),
                                      ),
                                      Expanded(
                                        flex: 1,
                                        child: Text(
                                            '${items.length} items',
                                            style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey)),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          'Rs ${data['total'] ?? 0}',
                                          style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight:
                                                  FontWeight.w600),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          data['paymentMethod'] ??
                                              'Cash',
                                          style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 1,
                                        child: Container(
                                          padding: const EdgeInsets
                                              .symmetric(
                                              horizontal: 8,
                                              vertical: 3),
                                          decoration: BoxDecoration(
                                            color: isPaid
                                                ? const Color(
                                                    0xFFE1F5EE)
                                                : isOnline
                                                    ? const Color(
                                                        0xFFE8F0FE)
                                                    : const Color(
                                                        0xFFFFF3CD),
                                            borderRadius:
                                                BorderRadius
                                                    .circular(20),
                                          ),
                                          child: Text(
                                            status,
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight:
                                                  FontWeight.w600,
                                              color: isPaid
                                                  ? const Color(
                                                      0xFF085041)
                                                  : isOnline
                                                      ? const Color(
                                                          0xFF1A56DB)
                                                      : const Color(
                                                          0xFF7D4E00),
                                            ),
                                            textAlign:
                                                TextAlign.center,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 1,
                                        child: Icon(
                                          Icons
                                              .arrow_forward_ios_rounded,
                                          size: 14,
                                          color: Colors.grey.shade400,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        // Grand total footer
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F5F5),
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(12),
                              bottomRight: Radius.circular(12),
                            ),
                            border: Border(
                                top: BorderSide(
                                    color: Colors.grey.shade200)),
                          ),
                          child: Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${filtered.length} invoices',
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.grey),
                              ),
                              Text(
                                'Grand Total: Rs $grandTotal',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1D9E75),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
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
            fontSize: 11,
            color: Colors.grey,
            fontWeight: FontWeight.w600));
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  const _DetailRow(
      {required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 12, color: Colors.grey)),
        Text(value,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: valueColor ?? const Color(0xFF1A1A2E))),
      ],
    );
  }
}