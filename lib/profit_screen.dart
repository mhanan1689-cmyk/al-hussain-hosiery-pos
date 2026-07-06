import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfitScreen extends StatefulWidget {
  const ProfitScreen({super.key});

  @override
  State<ProfitScreen> createState() => _ProfitScreenState();
}

class _ProfitScreenState extends State<ProfitScreen> {
  final _invoicesRef =
      FirebaseFirestore.instance.collection('invoices');
  final _expensesRef =
      FirebaseFirestore.instance.collection('expenses');
  final _productsRef =
      FirebaseFirestore.instance.collection('products');

  String _period = 'This Month';
  final List<String> _periods = [
    'Today', 'This Week', 'This Month', 'This Year', 'All Time'
  ];

  DateTime _periodStart() {
    final now = DateTime.now();
    switch (_period) {
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

  void _showAddExpense() {
    final titleCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    String category = 'Salary';
    final categories = [
      'Salary', 'Electricity', 'Rent', 'Transport',
      'Maintenance', 'Miscellaneous'
    ];

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setS) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          title: const Text('Add Expense'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Category
                DropdownButtonFormField<String>(
                  value: category,
                  decoration: InputDecoration(
                    labelText: 'Category',
                    filled: true,
                    fillColor: const Color(0xFFF5F5F5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: categories
                      .map((c) => DropdownMenuItem(
                          value: c,
                          child: Text(c,
                              style: const TextStyle(fontSize: 13))))
                      .toList(),
                  onChanged: (v) => setS(() => category = v!),
                ),
                const SizedBox(height: 12),
                // Title
                TextField(
                  controller: titleCtrl,
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    labelText: 'Title (e.g. Muhammad Usman Salary)',
                    filled: true,
                    fillColor: const Color(0xFFF5F5F5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Amount
                TextField(
                  controller: amountCtrl,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    labelText: 'Amount (Rs)',
                    prefixText: 'Rs ',
                    filled: true,
                    fillColor: const Color(0xFFF5F5F5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Note
                TextField(
                  controller: noteCtrl,
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    labelText: 'Note (optional)',
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
                if (titleCtrl.text.isEmpty ||
                    amountCtrl.text.isEmpty) return;
                await _expensesRef.add({
                  'title': titleCtrl.text.trim(),
                  'category': category,
                  'amount': int.tryParse(amountCtrl.text) ?? 0,
                  'note': noteCtrl.text.trim(),
                  'createdAt': FieldValue.serverTimestamp(),
                });
                if (context.mounted) Navigator.pop(context);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Expense added!'),
                      backgroundColor: Color(0xFF1D9E75),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Expense'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteExpense(String docId) async {
    await _expensesRef.doc(docId).delete();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Expense deleted'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _categoryEmoji(String cat) {
    switch (cat) {
      case 'Salary': return '👨‍💼';
      case 'Electricity': return '💡';
      case 'Rent': return '🏪';
      case 'Transport': return '🚗';
      case 'Maintenance': return '🔧';
      default: return '💸';
    }
  }

  @override
  Widget build(BuildContext context) {
    final periodStart = _periodStart();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Profit & Loss',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        actions: [
          // Period selector
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: DropdownButton<String>(
              value: _period,
              underline: const SizedBox(),
              items: _periods
                  .map((p) => DropdownMenuItem(
                      value: p,
                      child: Text(p,
                          style: const TextStyle(fontSize: 13))))
                  .toList(),
              onChanged: (v) => setState(() => _period = v!),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ElevatedButton.icon(
              onPressed: _showAddExpense,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Expense'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _invoicesRef.snapshots(),
        builder: (context, invoiceSnap) {
          final allInvoices = invoiceSnap.data?.docs ?? [];

          // Filter invoices by period
          final filteredInvoices = allInvoices.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final ts = data['createdAt'] as Timestamp?;
            if (ts == null) return false;
            final status = data['status'] ?? '';
            // Exclude payment records
            if (status == 'Payment') return false;
            return ts.toDate().isAfter(periodStart);
          }).toList();

          // Calculate revenue and cost
          int totalRevenue = 0;
          int totalOrders = filteredInvoices.length;
          Map<String, int> categoryRevenue = {};

          for (final doc in filteredInvoices) {
            final data = doc.data() as Map<String, dynamic>;
            final total = (data['total'] ?? 0) as int;
            totalRevenue += total;
          }

          return StreamBuilder<QuerySnapshot>(
            stream: _expensesRef.snapshots(),
            builder: (context, expenseSnap) {
              final allExpenses = expenseSnap.data?.docs ?? [];

              // Filter expenses by period
              final filteredExpenses = allExpenses.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final ts = data['createdAt'] as Timestamp?;
                if (ts == null) return false;
                return ts.toDate().isAfter(periodStart);
              }).toList();

              // Calculate total expenses
              int totalExpenses = 0;
              Map<String, int> expenseByCategory = {};
              for (final doc in filteredExpenses) {
                final data = doc.data() as Map<String, dynamic>;
                final amount = (data['amount'] ?? 0) as int;
                final cat = data['category'] ?? 'Miscellaneous';
                totalExpenses += amount;
                expenseByCategory[cat] =
                    (expenseByCategory[cat] ?? 0) + amount;
              }

              // Net profit
              final netProfit = totalRevenue - totalExpenses;
              final isProfitable = netProfit >= 0;

              return StreamBuilder<QuerySnapshot>(
                stream: _productsRef.snapshots(),
                builder: (context, productSnap) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Summary Cards
                        GridView.count(
                          crossAxisCount: 4,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 1.6,
                          children: [
                            _SummaryCard(
                              label: 'Total Revenue',
                              value: 'Rs $totalRevenue',
                              sub: '$totalOrders orders',
                              color: const Color(0xFF1D9E75),
                              icon: Icons.trending_up,
                            ),
                            _SummaryCard(
                              label: 'Total Expenses',
                              value: 'Rs $totalExpenses',
                              sub: '${filteredExpenses.length} entries',
                              color: const Color(0xFFEF4444),
                              icon: Icons.trending_down,
                            ),
                            _SummaryCard(
                              label: 'Net Profit',
                              value: 'Rs $netProfit',
                              sub: isProfitable
                                  ? '✅ Profitable'
                                  : '⚠️ Loss',
                              color: isProfitable
                                  ? const Color(0xFF1D9E75)
                                  : const Color(0xFFEF4444),
                              icon: isProfitable
                                  ? Icons.arrow_upward
                                  : Icons.arrow_downward,
                            ),
                            _SummaryCard(
                              label: 'Profit Margin',
                              value: totalRevenue > 0
                                  ? '${((netProfit / totalRevenue) * 100).toStringAsFixed(1)}%'
                                  : '0%',
                              sub: _period,
                              color: const Color(0xFF8B5CF6),
                              icon: Icons.pie_chart_outline,
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Left — Profit/Loss bar
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius:
                                      BorderRadius.circular(12),
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    const Text('Revenue vs Expenses',
                                        style: TextStyle(
                                            fontSize: 14,
                                            fontWeight:
                                                FontWeight.w600)),
                                    const SizedBox(height: 20),

                                    // Revenue bar
                                    _BarRow(
                                      label: 'Revenue',
                                      amount: totalRevenue,
                                      maxAmount: totalRevenue > 0
                                          ? totalRevenue
                                          : 1,
                                      color:
                                          const Color(0xFF1D9E75),
                                    ),
                                    const SizedBox(height: 12),

                                    // Expenses bar
                                    _BarRow(
                                      label: 'Expenses',
                                      amount: totalExpenses,
                                      maxAmount: totalRevenue > 0
                                          ? totalRevenue
                                          : 1,
                                      color: const Color(0xFFEF4444),
                                    ),
                                    const SizedBox(height: 12),

                                    // Profit bar
                                    _BarRow(
                                      label: 'Net Profit',
                                      amount:
                                          netProfit < 0 ? 0 : netProfit,
                                      maxAmount: totalRevenue > 0
                                          ? totalRevenue
                                          : 1,
                                      color: const Color(0xFF8B5CF6),
                                    ),

                                    const SizedBox(height: 20),
                                    const Divider(),
                                    const SizedBox(height: 12),

                                    // Expense by category
                                    const Text('Expenses by Category',
                                        style: TextStyle(
                                            fontSize: 13,
                                            fontWeight:
                                                FontWeight.w600)),
                                    const SizedBox(height: 12),
                                    if (expenseByCategory.isEmpty)
                                      const Text(
                                          'No expenses added yet.',
                                          style: TextStyle(
                                              color: Colors.grey,
                                              fontSize: 12))
                                    else
                                      ...expenseByCategory.entries
                                          .map((e) => Padding(
                                                padding:
                                                    const EdgeInsets
                                                        .only(
                                                        bottom: 8),
                                                child: Row(
                                                  children: [
                                                    Text(
                                                      _categoryEmoji(
                                                          e.key),
                                                      style:
                                                          const TextStyle(
                                                              fontSize:
                                                                  16),
                                                    ),
                                                    const SizedBox(
                                                        width: 8),
                                                    Expanded(
                                                      child: Text(
                                                          e.key,
                                                          style: const TextStyle(
                                                              fontSize:
                                                                  12)),
                                                    ),
                                                    Text(
                                                      'Rs ${e.value}',
                                                      style: const TextStyle(
                                                          fontSize: 12,
                                                          fontWeight:
                                                              FontWeight
                                                                  .w600,
                                                          color: Color(
                                                              0xFFEF4444)),
                                                    ),
                                                  ],
                                                ),
                                              )),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),

                            // Right — Expenses list
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius:
                                      BorderRadius.circular(12),
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment
                                              .spaceBetween,
                                      children: [
                                        const Text('Expense Details',
                                            style: TextStyle(
                                                fontSize: 14,
                                                fontWeight:
                                                    FontWeight.w600)),
                                        Text(
                                          '${filteredExpenses.length} entries',
                                          style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    if (filteredExpenses.isEmpty)
                                      const Padding(
                                        padding: EdgeInsets.symmetric(
                                            vertical: 20),
                                        child: Center(
                                          child: Text(
                                            'No expenses for this period.\nTap "Add Expense" to add one.',
                                            textAlign:
                                                TextAlign.center,
                                            style: TextStyle(
                                                color: Colors.grey,
                                                fontSize: 12),
                                          ),
                                        ),
                                      )
                                    else
                                      ...filteredExpenses.map((doc) {
                                        final data = doc.data()
                                            as Map<String, dynamic>;
                                        final ts = data['createdAt']
                                            as Timestamp?;
                                        final date = ts?.toDate();
                                        final dateStr = date != null
                                            ? '${date.day}/${date.month}/${date.year}'
                                            : '-';
                                        return Container(
                                          padding:
                                              const EdgeInsets.all(
                                                  12),
                                          margin:
                                              const EdgeInsets.only(
                                                  bottom: 8),
                                          decoration: BoxDecoration(
                                            color: const Color(
                                                0xFFF5F5F5),
                                            borderRadius:
                                                BorderRadius.circular(
                                                    8),
                                          ),
                                          child: Row(
                                            children: [
                                              Text(
                                                _categoryEmoji(
                                                    data['category'] ??
                                                        ''),
                                                style: const TextStyle(
                                                    fontSize: 20),
                                              ),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment
                                                          .start,
                                                  children: [
                                                    Text(
                                                      data['title'] ??
                                                          '',
                                                      style: const TextStyle(
                                                          fontSize: 13,
                                                          fontWeight:
                                                              FontWeight
                                                                  .w500),
                                                    ),
                                                    Text(
                                                      '${data['category']} • $dateStr',
                                                      style: const TextStyle(
                                                          fontSize: 11,
                                                          color: Colors
                                                              .grey),
                                                    ),
                                                    if (data['note'] !=
                                                            null &&
                                                        data['note']
                                                            .toString()
                                                            .isNotEmpty)
                                                      Text(
                                                        data['note'],
                                                        style: const TextStyle(
                                                            fontSize:
                                                                11,
                                                            color: Colors
                                                                .grey),
                                                      ),
                                                  ],
                                                ),
                                              ),
                                              Text(
                                                'Rs ${data['amount'] ?? 0}',
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight:
                                                      FontWeight.w700,
                                                  color: Color(
                                                      0xFFEF4444),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              GestureDetector(
                                                onTap: () =>
                                                    _deleteExpense(
                                                        doc.id),
                                                child: const Icon(
                                                  Icons.delete_outline,
                                                  size: 18,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final String sub;
  final Color color;
  final IconData icon;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.sub,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 11, color: Colors.grey)),
                const SizedBox(height: 2),
                Text(value,
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: color)),
                Text(sub,
                    style: const TextStyle(
                        fontSize: 10, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BarRow extends StatelessWidget {
  final String label;
  final int amount;
  final int maxAmount;
  final Color color;

  const _BarRow({
    required this.label,
    required this.amount,
    required this.maxAmount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final pct = maxAmount > 0 ? (amount / maxAmount).clamp(0.0, 1.0) : 0.0;
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(label,
              style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ),
        Expanded(
          child: Container(
            height: 14,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(4),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: pct,
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 80,
          child: Text(
            'Rs $amount',
            style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.w600),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}