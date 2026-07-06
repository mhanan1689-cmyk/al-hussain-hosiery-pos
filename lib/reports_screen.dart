import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
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

  @override
  Widget build(BuildContext context) {
    final invoicesRef = FirebaseFirestore.instance.collection('invoices');
    final customersRef = FirebaseFirestore.instance.collection('customers');
    final periodStart = _periodStart();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Reports',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: DropdownButton<String>(
              value: _period,
              underline: const SizedBox(),
              items: _periods
                  .map((p) => DropdownMenuItem(
                      value: p,
                      child:
                          Text(p, style: const TextStyle(fontSize: 13))))
                  .toList(),
              onChanged: (v) => setState(() => _period = v!),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: StreamBuilder<QuerySnapshot>(
          stream: invoicesRef.snapshots(),
          builder: (context, invoiceSnap) {
            if (invoiceSnap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final allInvoices = invoiceSnap.data?.docs ?? [];

            
            final filtered = allInvoices.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final ts = data['createdAt'] as Timestamp?;
              if (ts == null) return false;
              return ts.toDate().isAfter(periodStart);
            }).toList();

            int totalRevenue = 0;
            int totalOrders = filtered.length;
            Map<String, int> categorySales = {};
            Map<String, int> customerSales = {};

            for (final doc in filtered) {
              final data = doc.data() as Map<String, dynamic>;
              final total = (data['total'] ?? 0) as int;
              totalRevenue += total;

              final customerName = data['customerName'] ?? 'Unknown';
              customerSales[customerName] =
                  (customerSales[customerName] ?? 0) + total;

              final items = data['items'] as List<dynamic>? ?? [];
              for (final item in items) {
                final itemMap = item as Map<String, dynamic>;
                final price = (itemMap['price'] ?? 0) as int;
                final qty = (itemMap['qty'] ?? 0) as int;
                
                final name = itemMap['name'] ?? 'Unknown';
                categorySales[name] =
                    (categorySales[name] ?? 0) + (price * qty);
              }
            }

            final avgOrder =
                totalOrders > 0 ? (totalRevenue / totalOrders).round() : 0;

            final sortedProducts = categorySales.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value));
            final topProducts = sortedProducts.take(6).toList();
            final maxProductSale = topProducts.isNotEmpty
                ? topProducts.first.value
                : 1;

            final sortedCustomers = customerSales.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value));
            final topCustomers = sortedCustomers.take(5).toList();

            return StreamBuilder<QuerySnapshot>(
              stream: customersRef.snapshots(),
              builder: (context, custSnap) {
                final customers = custSnap.data?.docs ?? [];
                int outstandingCredit = 0;
                int customersWithDebt = 0;
                for (final doc in customers) {
                  final data = doc.data() as Map<String, dynamic>;
                  final balance = (data['balance'] ?? 0) as int;
                  if (balance > 0) {
                    outstandingCredit += balance;
                    customersWithDebt++;
                  }
                }

                return SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GridView.count(
                        crossAxisCount: 4,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 1.8,
                        children: [
                          _StatCard(
                              label: 'Revenue ($_period)',
                              value: 'Rs $totalRevenue',
                              sub: '$totalOrders orders',
                              color: const Color(0xFF1D9E75)),
                          _StatCard(
                              label: 'Total Orders',
                              value: '$totalOrders',
                              sub: 'Avg Rs $avgOrder / order',
                              color: const Color(0xFF3B82F6)),
                          _StatCard(
                              label: 'Outstanding Credit',
                              value: 'Rs $outstandingCredit',
                              sub: '$customersWithDebt customers',
                              color: const Color(0xFFF59E0B)),
                          _StatCard(
                              label: 'Avg Order Value',
                              value: 'Rs $avgOrder',
                              sub: 'per invoice',
                              color: const Color(0xFF8B5CF6)),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Top Selling Products',
                                      style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 16),
                                  if (topProducts.isEmpty)
                                    const Padding(
                                      padding:
                                          EdgeInsets.symmetric(vertical: 20),
                                      child: Text('No sales in this period',
                                          style: TextStyle(
                                              color: Colors.grey,
                                              fontSize: 13)),
                                    )
                                  else
                                    ...topProducts.map((e) {
                                      final pct = e.value / maxProductSale;
                                      return Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 10),
                                        child: Row(
                                          children: [
                                            SizedBox(
                                              width: 110,
                                              child: Text(
                                                e.key,
                                                style: const TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey),
                                                overflow:
                                                    TextOverflow.ellipsis,
                                              ),
                                            ),
                                            Expanded(
                                              child: Container(
                                                height: 12,
                                                decoration: BoxDecoration(
                                                  color:
                                                      const Color(0xFFF5F5F5),
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                                child: FractionallySizedBox(
                                                  alignment:
                                                      Alignment.centerLeft,
                                                  widthFactor: pct,
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      color: const Color(
                                                          0xFF1D9E75),
                                                      borderRadius:
                                                          BorderRadius
                                                              .circular(4),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            SizedBox(
                                              width: 60,
                                              child: Text(
                                                'Rs ${e.value}',
                                                style: const TextStyle(
                                                    fontSize: 11,
                                                    color: Colors.grey),
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
                          const SizedBox(width: 16),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Top Customers ($_period)',
                                      style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 16),
                                  if (topCustomers.isEmpty)
                                    const Padding(
                                      padding:
                                          EdgeInsets.symmetric(vertical: 20),
                                      child: Text('No sales in this period',
                                          style: TextStyle(
                                              color: Colors.grey,
                                              fontSize: 13)),
                                    )
                                  else
                                    Table(
                                      children: [
                                        const TableRow(
                                          children: [
                                            Padding(
                                              padding:
                                                  EdgeInsets.only(bottom: 8),
                                              child: Text('#',
                                                  style: TextStyle(
                                                      fontSize: 11,
                                                      color: Colors.grey)),
                                            ),
                                            Padding(
                                              padding:
                                                  EdgeInsets.only(bottom: 8),
                                              child: Text('Customer',
                                                  style: TextStyle(
                                                      fontSize: 11,
                                                      color: Colors.grey)),
                                            ),
                                            Padding(
                                              padding:
                                                  EdgeInsets.only(bottom: 8),
                                              child: Text('Purchases',
                                                  style: TextStyle(
                                                      fontSize: 11,
                                                      color: Colors.grey)),
                                            ),
                                          ],
                                        ),
                                        ...topCustomers
                                            .asMap()
                                            .entries
                                            .map((entry) {
                                          final idx = entry.key + 1;
                                          final c = entry.value;
                                          return TableRow(
                                            children: [
                                              Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 6),
                                                child: Text('$idx',
                                                    style: const TextStyle(
                                                        fontSize: 13)),
                                              ),
                                              Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 6),
                                                child: Text(c.key,
                                                    style: const TextStyle(
                                                        fontSize: 13),
                                                    overflow:
                                                        TextOverflow.ellipsis),
                                              ),
                                              Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 6),
                                                child: Text('Rs ${c.value}',
                                                    style: const TextStyle(
                                                        fontSize: 13,
                                                        fontWeight:
                                                            FontWeight.w500)),
                                              ),
                                            ],
                                          );
                                        }),
                                      ],
                                    ),
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
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String sub;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.sub,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 11, color: Colors.grey)),
          const SizedBox(height: 6),
          Text(value,
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w600, color: color)),
          const SizedBox(height: 2),
          Text(sub, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ],
      ),
    );
  }
}