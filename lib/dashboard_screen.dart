import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final productsRef = FirebaseFirestore.instance.collection('products');
    final customersRef = FirebaseFirestore.instance.collection('customers');
    final invoicesRef = FirebaseFirestore.instance.collection('invoices');

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Dashboard',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                _getDate(),
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: StreamBuilder<QuerySnapshot>(
          stream: invoicesRef.snapshots(),
          builder: (context, invoiceSnap) {
            final invoices = invoiceSnap.data?.docs ?? [];

            // Today's sales
            final now = DateTime.now();
            int todaySalesTotal = 0;
            int todayInvoiceCount = 0;
            List<QueryDocumentSnapshot> recentInvoices = [];

            for (final doc in invoices) {
              final data = doc.data() as Map<String, dynamic>;
              final ts = data['createdAt'] as Timestamp?;
              if (ts != null) {
                final date = ts.toDate();
                if (date.year == now.year &&
                    date.month == now.month &&
                    date.day == now.day) {
                  todaySalesTotal += ((data['total'] ?? 0) as int);
                  todayInvoiceCount++;
                }
              }
            }

            
            final sortedInvoices = List<QueryDocumentSnapshot>.from(invoices);
            sortedInvoices.sort((a, b) {
              final aData = a.data() as Map<String, dynamic>;
              final bData = b.data() as Map<String, dynamic>;
              final aTs = aData['createdAt'] as Timestamp?;
              final bTs = bData['createdAt'] as Timestamp?;
              if (aTs == null || bTs == null) return 0;
              return bTs.compareTo(aTs);
            });
            recentInvoices = sortedInvoices.take(5).toList();

            return StreamBuilder<QuerySnapshot>(
              stream: productsRef.snapshots(),
              builder: (context, productSnap) {
                final products = productSnap.data?.docs ?? [];
                final totalProducts = products.length;

                final categories = <String>{};
                List<QueryDocumentSnapshot> lowStockItems = [];
                for (final doc in products) {
                  final data = doc.data() as Map<String, dynamic>;
                  if (data['cat'] != null) categories.add(data['cat']);
                  final stock = (data['stock'] ?? 0) as int;
                  if (stock <= 6) lowStockItems.add(doc);
                }
                lowStockItems.sort((a, b) {
                  final aStock = ((a.data() as Map)['stock'] ?? 0) as int;
                  final bStock = ((b.data() as Map)['stock'] ?? 0) as int;
                  return aStock.compareTo(bStock);
                });

                return StreamBuilder<QuerySnapshot>(
                  stream: customersRef.snapshots(),
                  builder: (context, custSnap) {
                    final customers = custSnap.data?.docs ?? [];
                    final totalCustomers = customers.length;

                    return Column(
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
                                label: "Today's Sales",
                                value: 'Rs $todaySalesTotal',
                                sub: '$todayInvoiceCount invoices',
                                color: const Color(0xFF1D9E75),
                                icon: Icons.trending_up),
                            _StatCard(
                                label: 'Total Products',
                                value: '$totalProducts',
                                sub: '${categories.length} categories',
                                color: const Color(0xFF3B82F6),
                                icon: Icons.inventory_2_outlined),
                            _StatCard(
                                label: 'Customers',
                                value: '$totalCustomers',
                                sub: 'wholesale buyers',
                                color: const Color(0xFF8B5CF6),
                                icon: Icons.people_outline),
                            _StatCard(
                                label: 'Low Stock',
                                value: '${lowStockItems.length}',
                                sub: 'Need reorder',
                                color: const Color(0xFFEF4444),
                                icon: Icons.warning_amber_outlined),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _RecentSalesCard(invoices: recentInvoices),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _LowStockCard(items: lowStockItems.take(5).toList()),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  String _getDate() {
    final now = DateTime.now();
    return '${now.day}/${now.month}/${now.year}';
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String sub;
  final Color color;
  final IconData icon;

  const _StatCard({
    required this.label,
    required this.value,
    required this.sub,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(label,
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 4),
                Text(value,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w600)),
                Text(sub,
                    style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentSalesCard extends StatelessWidget {
  final List<QueryDocumentSnapshot> invoices;
  const _RecentSalesCard({required this.invoices});

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
        children: [
          const Text('Recent Sales',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          if (invoices.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Text('No sales yet',
                  style: TextStyle(color: Colors.grey, fontSize: 13)),
            )
          else
            Table(
              children: [
                const TableRow(
                  decoration: BoxDecoration(
                    border:
                        Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
                  ),
                  children: [
                    Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: Text('Invoice',
                          style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                              fontWeight: FontWeight.w500)),
                    ),
                    Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: Text('Customer',
                          style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                              fontWeight: FontWeight.w500)),
                    ),
                    Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: Text('Amount',
                          style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                              fontWeight: FontWeight.w500)),
                    ),
                    Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: Text('Status',
                          style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                              fontWeight: FontWeight.w500)),
                    ),
                  ],
                ),
                ...invoices.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final status = data['status'] ?? 'Paid';
                  final isPaid = status == 'Paid';
                  return TableRow(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text('#${doc.id.substring(0, 6).toUpperCase()}',
                            style: const TextStyle(fontSize: 13)),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(data['customerName'] ?? '',
                            style: const TextStyle(fontSize: 13),
                            overflow: TextOverflow.ellipsis),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text('Rs ${data['total'] ?? 0}',
                            style: const TextStyle(fontSize: 13)),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: isPaid
                                ? const Color(0xFFE1F5EE)
                                : const Color(0xFFFFF3CD),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            status,
                            style: TextStyle(
                              fontSize: 11,
                              color: isPaid
                                  ? const Color(0xFF085041)
                                  : const Color(0xFF7D4E00),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                }),
              ],
            ),
        ],
      ),
    );
  }
}

class _LowStockCard extends StatelessWidget {
  final List<QueryDocumentSnapshot> items;
  const _LowStockCard({required this.items});

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
        children: [
          const Text('Low Stock Alert',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Text('All stock levels are healthy ✅',
                  style: TextStyle(color: Colors.grey, fontSize: 13)),
            )
          else
            Table(
              children: [
                const TableRow(
                  decoration: BoxDecoration(
                    border:
                        Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
                  ),
                  children: [
                    Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: Text('Product',
                          style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                              fontWeight: FontWeight.w500)),
                    ),
                    Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: Text('Category',
                          style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                              fontWeight: FontWeight.w500)),
                    ),
                    Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: Text('Qty',
                          style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                              fontWeight: FontWeight.w500)),
                    ),
                  ],
                ),
                ...items.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final stock = (data['stock'] ?? 0) as int;
                  final color = stock == 0
                      ? const Color(0xFFEF4444)
                      : const Color(0xFFF59E0B);
                  return TableRow(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(data['name'] ?? '',
                            style: const TextStyle(fontSize: 13),
                            overflow: TextOverflow.ellipsis),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(data['cat'] ?? '',
                            style: const TextStyle(
                                fontSize: 13, color: Colors.grey)),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          stock == 0 ? '0 — Out' : '$stock left',
                          style: TextStyle(
                              fontSize: 13,
                              color: color,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  );
                }),
              ],
            ),
        ],
      ),
    );
  }
}