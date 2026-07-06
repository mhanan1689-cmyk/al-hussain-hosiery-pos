import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final CollectionReference _productsRef =
      FirebaseFirestore.instance.collection('products');

  String _search = '';
  String _selectedCat = 'All';

  final List<String> _categories = [
    'All', 'Caps', 'Underwear', 'Bra', 'Socks', 'Tasbih', 'Garments', 'Other'
  ];

  String _stockStatus(int stock) {
    if (stock == 0) return 'Out';
    if (stock <= 6) return 'Low';
    return 'OK';
  }

  Color _stockColor(int stock) {
    if (stock == 0) return const Color(0xFFEF4444);
    if (stock <= 6) return const Color(0xFFF59E0B);
    return const Color(0xFF1D9E75);
  }

  void _showAddProduct() {
    final nameCtrl = TextEditingController();
    final skuCtrl = TextEditingController();
    final stockCtrl = TextEditingController();
    final buyCtrl = TextEditingController();
    final sellCtrl = TextEditingController();
    String cat = 'Caps';

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setS) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Add New Product'),
          content: SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _Field(ctrl: nameCtrl, label: 'Product Name'),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: _Field(ctrl: skuCtrl, label: 'SKU')),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: cat,
                        decoration: _dropDeco('Category'),
                        items: _categories
                            .where((c) => c != 'All')
                            .map((c) => DropdownMenuItem(
                                value: c,
                                child: Text(c,
                                    style: const TextStyle(fontSize: 13))))
                            .toList(),
                        onChanged: (v) => setS(() => cat = v!),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(
                        child: _Field(
                            ctrl: stockCtrl,
                            label: 'Stock Qty',
                            isNumber: true)),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _Field(
                            ctrl: buyCtrl,
                            label: 'Buy Price (Rs)',
                            isNumber: true)),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _Field(
                            ctrl: sellCtrl,
                            label: 'Sell Price (Rs)',
                            isNumber: true)),
                  ]),
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
                await _productsRef.add({
                  'name': nameCtrl.text,
                  'cat': cat,
                  'sku': skuCtrl.text,
                  'stock': int.tryParse(stockCtrl.text) ?? 0,
                  'buy': int.tryParse(buyCtrl.text) ?? 0,
                  'sell': int.tryParse(sellCtrl.text) ?? 0,
                  'createdAt': FieldValue.serverTimestamp(),
                });
                if (context.mounted) Navigator.pop(context);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Product added successfully!'),
                      backgroundColor: Color(0xFF1D9E75),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1D9E75),
                foregroundColor: Colors.white,
              ),
              child: const Text('Save Product'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditProduct(String docId, Map<String, dynamic> product) {
    final nameCtrl = TextEditingController(text: product['name']);
    final skuCtrl = TextEditingController(text: product['sku']);
    final stockCtrl =
        TextEditingController(text: product['stock'].toString());
    final buyCtrl = TextEditingController(text: product['buy'].toString());
    final sellCtrl = TextEditingController(text: product['sell'].toString());
    String cat = product['cat'];

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setS) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Edit Product'),
          content: SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _Field(ctrl: nameCtrl, label: 'Product Name'),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: _Field(ctrl: skuCtrl, label: 'SKU')),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: cat,
                        decoration: _dropDeco('Category'),
                        items: _categories
                            .where((c) => c != 'All')
                            .map((c) => DropdownMenuItem(
                                value: c,
                                child: Text(c,
                                    style: const TextStyle(fontSize: 13))))
                            .toList(),
                        onChanged: (v) => setS(() => cat = v!),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(
                        child: _Field(
                            ctrl: stockCtrl,
                            label: 'Stock Qty',
                            isNumber: true)),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _Field(
                            ctrl: buyCtrl,
                            label: 'Buy Price (Rs)',
                            isNumber: true)),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _Field(
                            ctrl: sellCtrl,
                            label: 'Sell Price (Rs)',
                            isNumber: true)),
                  ]),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                await _productsRef.doc(docId).delete();
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                await _productsRef.doc(docId).update({
                  'name': nameCtrl.text,
                  'cat': cat,
                  'sku': skuCtrl.text,
                  'stock': int.tryParse(stockCtrl.text) ?? 0,
                  'buy': int.tryParse(buyCtrl.text) ?? 0,
                  'sell': int.tryParse(sellCtrl.text) ?? 0,
                });
                if (context.mounted) Navigator.pop(context);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Product updated!'),
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
      ),
    );
  }

  InputDecoration _dropDeco(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(fontSize: 13),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Inventory',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ElevatedButton.icon(
              onPressed: _showAddProduct,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Product'),
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
            Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (v) => setState(() => _search = v),
                    decoration: InputDecoration(
                      hintText: 'Search products...',
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
                ...(_categories.map((cat) {
                  final selected = _selectedCat == cat;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedCat = cat),
                    child: Container(
                      margin: const EdgeInsets.only(left: 6),
                      padding:
                          const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: selected ? const Color(0xFF1D9E75) : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        cat,
                        style: TextStyle(
                          fontSize: 12,
                          color: selected ? Colors.white : Colors.grey,
                          fontWeight:
                              selected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                })),
              ],
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
                  Expanded(flex: 3, child: _TH('Product')),
                  Expanded(flex: 2, child: _TH('Category')),
                  Expanded(flex: 2, child: _TH('SKU')),
                  Expanded(flex: 1, child: _TH('Stock')),
                  Expanded(flex: 2, child: _TH('Buy Price')),
                  Expanded(flex: 2, child: _TH('Sell Price')),
                  Expanded(flex: 1, child: _TH('Status')),
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
                child: StreamBuilder<QuerySnapshot>(
                  stream: _productsRef.snapshots(),
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
                      final matchCat =
                          _selectedCat == 'All' || data['cat'] == _selectedCat;
                      final matchSearch = (data['name'] ?? '')
                          .toString()
                          .toLowerCase()
                          .contains(_search.toLowerCase());
                      return matchCat && matchSearch;
                    }).toList();

                    if (filtered.isEmpty) {
                      return const Center(
                        child: Text('No products yet. Click "Add Product" to start!',
                            style: TextStyle(color: Colors.grey)),
                      );
                    }

                    return ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (_, i) {
                        final doc = filtered[i];
                        final p = doc.data() as Map<String, dynamic>;
                        final stock = p['stock'] ?? 0;
                        final status = _stockStatus(stock);
                        final color = _stockColor(stock);
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
                                  child: Text(p['name'] ?? '',
                                      style: const TextStyle(
                                          fontSize: 13, fontWeight: FontWeight.w500))),
                              Expanded(
                                  flex: 2,
                                  child: Text(p['cat'] ?? '',
                                      style: const TextStyle(
                                          fontSize: 13, color: Colors.grey))),
                              Expanded(
                                  flex: 2,
                                  child: Text(p['sku'] ?? '',
                                      style: const TextStyle(
                                          fontSize: 12, color: Colors.grey))),
                              Expanded(
                                  flex: 1,
                                  child: Text('$stock',
                                      style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: color))),
                              Expanded(
                                  flex: 2,
                                  child: Text('Rs ${p['buy'] ?? 0}',
                                      style: const TextStyle(fontSize: 13))),
                              Expanded(
                                  flex: 2,
                                  child: Text('Rs ${p['sell'] ?? 0}',
                                      style: const TextStyle(fontSize: 13))),
                              Expanded(
                                flex: 1,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: color.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    status,
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: color,
                                        fontWeight: FontWeight.w600),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: IconButton(
                                  icon: const Icon(Icons.edit_outlined,
                                      size: 18, color: Colors.grey),
                                  onPressed: () => _showEditProduct(doc.id, p),
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