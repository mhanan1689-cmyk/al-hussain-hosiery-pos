import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PurchaseScreen extends StatefulWidget {
  const PurchaseScreen({super.key});

  @override
  State<PurchaseScreen> createState() => _PurchaseScreenState();
}

class _PurchaseScreenState extends State<PurchaseScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final _suppliersRef =
      FirebaseFirestore.instance.collection('suppliers');
  final _purchasesRef =
      FirebaseFirestore.instance.collection('purchases');
  final _productsRef =
      FirebaseFirestore.instance.collection('products');

  String _search = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ─── ADD SUPPLIER ─────────────────────────────────────
  void _showAddSupplier() {
    final nameCtrl = TextEditingController();
    final companyCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final cityCtrl = TextEditingController();
    final addressCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text('Add Supplier'),
        content: SizedBox(
          width: 420,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _Field(ctrl: nameCtrl, label: 'Contact Person Name'),
                const SizedBox(height: 12),
                _Field(
                    ctrl: companyCtrl,
                    label: 'Company / Business Name'),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(
                      child: _Field(ctrl: phoneCtrl, label: 'Phone')),
                  const SizedBox(width: 12),
                  Expanded(
                      child: _Field(ctrl: cityCtrl, label: 'City')),
                ]),
                const SizedBox(height: 12),
                _Field(ctrl: addressCtrl, label: 'Address (optional)'),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton.icon(
            onPressed: () async {
              if (nameCtrl.text.isEmpty) return;
              await _suppliersRef.add({
                'name': nameCtrl.text.trim(),
                'company': companyCtrl.text.trim(),
                'phone': phoneCtrl.text.trim(),
                'city': cityCtrl.text.trim(),
                'address': addressCtrl.text.trim(),
                'totalPurchases': 0,
                'createdAt': FieldValue.serverTimestamp(),
              });
              if (context.mounted) Navigator.pop(context);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Supplier added!'),
                    backgroundColor: Color(0xFF1D9E75),
                  ),
                );
              }
            },
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Save Supplier'),
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

  // ─── EDIT SUPPLIER ────────────────────────────────────
  void _showEditSupplier(String docId, Map<String, dynamic> s) {
    final nameCtrl = TextEditingController(text: s['name']);
    final companyCtrl = TextEditingController(text: s['company']);
    final phoneCtrl = TextEditingController(text: s['phone']);
    final cityCtrl = TextEditingController(text: s['city']);
    final addressCtrl = TextEditingController(text: s['address']);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text('Edit Supplier'),
        content: SizedBox(
          width: 420,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _Field(ctrl: nameCtrl, label: 'Contact Person Name'),
                const SizedBox(height: 12),
                _Field(
                    ctrl: companyCtrl,
                    label: 'Company / Business Name'),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(
                      child: _Field(ctrl: phoneCtrl, label: 'Phone')),
                  const SizedBox(width: 12),
                  Expanded(
                      child: _Field(ctrl: cityCtrl, label: 'City')),
                ]),
                const SizedBox(height: 12),
                _Field(ctrl: addressCtrl, label: 'Address (optional)'),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await _suppliersRef.doc(docId).delete();
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Delete',
                style: TextStyle(color: Colors.red)),
          ),
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await _suppliersRef.doc(docId).update({
                'name': nameCtrl.text.trim(),
                'company': companyCtrl.text.trim(),
                'phone': phoneCtrl.text.trim(),
                'city': cityCtrl.text.trim(),
                'address': addressCtrl.text.trim(),
              });
              if (context.mounted) Navigator.pop(context);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Supplier updated!'),
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

  // ─── ADD PURCHASE ─────────────────────────────────────
  void _showAddPurchase() async {
    // Get suppliers and products
    final suppSnap = await _suppliersRef.get();
    final prodSnap = await _productsRef.get();

    if (!mounted) return;

    if (suppSnap.docs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Add a supplier first before recording a purchase!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (prodSnap.docs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Add products in Inventory first!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    String selectedSupplierId = suppSnap.docs.first.id;
    String selectedSupplierName =
        (suppSnap.docs.first.data())['name'] ?? '';
    String selectedProductId = prodSnap.docs.first.id;
    String selectedProductName =
        (prodSnap.docs.first.data() as Map<String, dynamic>)['name'] ?? '';
    final qtyCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final noteCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setS) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          title: const Text('Record Purchase'),
          content: SizedBox(
            width: 440,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Supplier
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Supplier',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1A1A2E))),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        value: selectedSupplierId,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: const Color(0xFFF5F5F5),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        items: suppSnap.docs.map((doc) {
                          final data =
                              doc.data() as Map<String, dynamic>;
                          return DropdownMenuItem(
                            value: doc.id,
                            child: Text(
                                '${data['name']} — ${data['company']}',
                                style: const TextStyle(fontSize: 13)),
                          );
                        }).toList(),
                        onChanged: (v) {
                          if (v == null) return;
                          setS(() {
                            selectedSupplierId = v;
                            final doc = suppSnap.docs
                                .firstWhere((d) => d.id == v);
                            selectedSupplierName =
                                (doc.data() as Map<String, dynamic>)[
                                        'name'] ??
                                    '';
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Product
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Product',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1A1A2E))),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        value: selectedProductId,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: const Color(0xFFF5F5F5),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        items: prodSnap.docs.map((doc) {
                          final data =
                              doc.data() as Map<String, dynamic>;
                          return DropdownMenuItem(
                            value: doc.id,
                            child: Text(
                                '${data['name']} (Stock: ${data['stock']})',
                                style: const TextStyle(fontSize: 13)),
                          );
                        }).toList(),
                        onChanged: (v) {
                          if (v == null) return;
                          setS(() {
                            selectedProductId = v;
                            final doc = prodSnap.docs
                                .firstWhere((d) => d.id == v);
                            selectedProductName =
                                (doc.data() as Map<String, dynamic>)[
                                        'name'] ??
                                    '';
                            // Auto fill buy price
                            final buyPrice =
                                (doc.data() as Map<String, dynamic>)[
                                        'buy'] ??
                                    0;
                            priceCtrl.text = '$buyPrice';
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Qty and price
                  Row(children: [
                    Expanded(
                      child: _Field(
                          ctrl: qtyCtrl,
                          label: 'Quantity',
                          isNumber: true),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _Field(
                          ctrl: priceCtrl,
                          label: 'Buy Price per unit (Rs)',
                          isNumber: true),
                    ),
                  ]),
                  const SizedBox(height: 14),
                  _Field(
                      ctrl: noteCtrl,
                      label: 'Note (optional)',
                      hint: 'e.g. Paid cash, credit etc'),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel')),
            ElevatedButton.icon(
              onPressed: () async {
                final qty = int.tryParse(qtyCtrl.text) ?? 0;
                final price = int.tryParse(priceCtrl.text) ?? 0;
                if (qty <= 0 || price <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                          'Please enter valid quantity and price!'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                final total = qty * price;

                // Save purchase record
                await _purchasesRef.add({
                  'supplierId': selectedSupplierId,
                  'supplierName': selectedSupplierName,
                  'productId': selectedProductId,
                  'productName': selectedProductName,
                  'qty': qty,
                  'pricePerUnit': price,
                  'total': total,
                  'note': noteCtrl.text.trim(),
                  'createdAt': FieldValue.serverTimestamp(),
                });

                // Update product stock in inventory
                await _productsRef
                    .doc(selectedProductId)
                    .update({
                  'stock': FieldValue.increment(qty),
                  'buy': price, // Update buy price too
                });

                // Update supplier total purchases
                await _suppliersRef
                    .doc(selectedSupplierId)
                    .update({
                  'totalPurchases': FieldValue.increment(total),
                });

                if (context.mounted) Navigator.pop(context);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          'Purchase recorded! $qty × $selectedProductName — Rs $total. Stock updated!'),
                      backgroundColor: const Color(0xFF1D9E75),
                      duration: const Duration(seconds: 3),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.check, size: 18),
              label: const Text('Save Purchase'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1D9E75),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Purchases & Suppliers',
            style:
                TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF1D9E75),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF1D9E75),
          tabs: const [
            Tab(icon: Icon(Icons.shopping_cart_outlined), text: 'Purchases'),
            Tab(icon: Icon(Icons.people_outline), text: 'Suppliers'),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ElevatedButton.icon(
              onPressed: _showAddPurchase,
              icon: const Icon(Icons.add_shopping_cart, size: 18),
              label: const Text('Record Purchase'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1D9E75),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ElevatedButton.icon(
              onPressed: _showAddSupplier,
              icon: const Icon(Icons.person_add_outlined, size: 18),
              label: const Text('Add Supplier'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A1A2E),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _PurchasesTab(
              purchasesRef: _purchasesRef, search: _search),
          _SuppliersTab(
            suppliersRef: _suppliersRef,
            search: _search,
            onSearchChanged: (v) => setState(() => _search = v),
            onEdit: _showEditSupplier,
          ),
        ],
      ),
    );
  }
}

// ─── PURCHASES TAB ────────────────────────────────────────
class _PurchasesTab extends StatelessWidget {
  final CollectionReference purchasesRef;
  final String search;

  const _PurchasesTab(
      {required this.purchasesRef, required this.search});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: purchasesRef.snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snap.data?.docs ?? [];
        docs.sort((a, b) {
          final aTs =
              ((a.data() as Map)['createdAt'] as Timestamp?);
          final bTs =
              ((b.data() as Map)['createdAt'] as Timestamp?);
          if (aTs == null || bTs == null) return 0;
          return bTs.compareTo(aTs);
        });

        // Total spent
        int totalSpent = 0;
        for (final doc in docs) {
          final data = doc.data() as Map<String, dynamic>;
          totalSpent += (data['total'] ?? 0) as int;
        }

        if (docs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.shopping_cart_outlined,
                    size: 48, color: Colors.grey),
                SizedBox(height: 12),
                Text('No purchases recorded yet.',
                    style:
                        TextStyle(color: Colors.grey, fontSize: 14)),
                SizedBox(height: 4),
                Text(
                    'Click "Record Purchase" to add your first purchase.',
                    style:
                        TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Summary
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFCEBEB),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                                Icons.shopping_cart_outlined,
                                color: Colors.red,
                                size: 22),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              const Text('Total Spent on Purchases',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey)),
                              Text('Rs $totalSpent',
                                  style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.red)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE1F5EE),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1D9E75)
                                  .withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.receipt_outlined,
                                color: Color(0xFF1D9E75), size: 22),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              const Text('Total Purchase Orders',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey)),
                              Text('${docs.length} orders',
                                  style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF1D9E75))),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
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
                    Expanded(flex: 3, child: _TH('Product')),
                    Expanded(flex: 2, child: _TH('Supplier')),
                    Expanded(flex: 1, child: _TH('Qty')),
                    Expanded(flex: 2, child: _TH('Price/Unit')),
                    Expanded(flex: 2, child: _TH('Total')),
                    Expanded(flex: 2, child: _TH('Date')),
                    Expanded(flex: 2, child: _TH('Note')),
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
                    itemCount: docs.length,
                    itemBuilder: (_, i) {
                      final data =
                          docs[i].data() as Map<String, dynamic>;
                      final ts =
                          data['createdAt'] as Timestamp?;
                      final date = ts?.toDate();
                      final dateStr = date != null
                          ? '${date.day}/${date.month}/${date.year}'
                          : '-';

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
                              child: Text(
                                data['productName'] ?? '',
                                style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                data['supplierName'] ?? '',
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text(
                                '+${data['qty']}',
                                style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1D9E75)),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                  'Rs ${data['pricePerUnit']}',
                                  style: const TextStyle(
                                      fontSize: 12)),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                'Rs ${data['total']}',
                                style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.red),
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
                              flex: 2,
                              child: Text(
                                data['note'] ?? '',
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey),
                                overflow: TextOverflow.ellipsis,
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
  }
}

// ─── SUPPLIERS TAB ────────────────────────────────────────
class _SuppliersTab extends StatelessWidget {
  final CollectionReference suppliersRef;
  final String search;
  final Function(String) onSearchChanged;
  final Function(String, Map<String, dynamic>) onEdit;

  const _SuppliersTab({
    required this.suppliersRef,
    required this.search,
    required this.onSearchChanged,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: suppliersRef.snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snap.data?.docs ?? [];
        final filtered = docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return (data['name'] ?? '')
              .toString()
              .toLowerCase()
              .contains(search.toLowerCase());
        }).toList();

        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              TextField(
                onChanged: onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Search suppliers...',
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
                    Expanded(flex: 2, child: _TH('Name')),
                    Expanded(flex: 2, child: _TH('Company')),
                    Expanded(flex: 2, child: _TH('Phone')),
                    Expanded(flex: 1, child: _TH('City')),
                    Expanded(flex: 2, child: _TH('Total Purchased')),
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
                  child: filtered.isEmpty
                      ? const Center(
                          child: Text(
                            'No suppliers yet. Click "Add Supplier" to start!',
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          itemCount: filtered.length,
                          itemBuilder: (_, i) {
                            final doc = filtered[i];
                            final s = doc.data()
                                as Map<String, dynamic>;
                            final totalPurchases =
                                (s['totalPurchases'] ?? 0) as int;

                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                border: Border(
                                    top: BorderSide(
                                        color:
                                            Colors.grey.shade100)),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: Text(s['name'] ?? '',
                                        style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight:
                                                FontWeight.w500)),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                        s['company'] ?? '',
                                        style: const TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey)),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(s['phone'] ?? '',
                                        style: const TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey)),
                                  ),
                                  Expanded(
                                    flex: 1,
                                    child: Text(s['city'] ?? '',
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey)),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      'Rs $totalPurchases',
                                      style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.red),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 1,
                                    child: IconButton(
                                      icon: const Icon(
                                          Icons.edit_outlined,
                                          size: 18,
                                          color: Colors.grey),
                                      onPressed: () =>
                                          onEdit(doc.id, s),
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

class _Field extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final String? hint;
  final bool isNumber;
  const _Field(
      {required this.ctrl,
      required this.label,
      this.hint,
      this.isNumber = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A2E))),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          keyboardType:
              isNumber ? TextInputType.number : TextInputType.text,
          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(
            hintText: hint ?? '',
            hintStyle:
                const TextStyle(color: Colors.grey, fontSize: 13),
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
      ],
    );
  }
}